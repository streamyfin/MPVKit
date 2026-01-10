import Foundation
import UIKit
import AVFoundation
import AVKit
import Libmpv

/// Represents a subtitle track
struct SubtitleTrack: Identifiable, Hashable {
    let id: Int
    let title: String?
    let language: String?
    let codec: String?
    
    var displayName: String {
        if id == 0 { return "Off" }
        
        var parts: [String] = []
        if let title = title, !title.isEmpty {
            parts.append(title)
        }
        if let lang = language, !lang.isEmpty {
            parts.append("[\(lang)]")
        }
        
        if parts.isEmpty {
            return "Track \(id)"
        }
        return parts.joined(separator: " ")
    }
}

/// Represents an audio track
struct AudioTrack: Identifiable, Hashable {
    let id: Int
    let title: String?
    let language: String?
    let codec: String?
    let channels: Int?
    
    var displayName: String {
        var parts: [String] = []
        if let title = title, !title.isEmpty {
            parts.append(title)
        }
        if let lang = language, !lang.isEmpty {
            parts.append("[\(lang)]")
        }
        if let codec = codec {
            parts.append("(\(codec.uppercased()))")
        }
        if let ch = channels, ch > 0 {
            parts.append(channelDescription(ch))
        }
        
        if parts.isEmpty {
            return "Track \(id)"
        }
        return parts.joined(separator: " ")
    }
    
    private func channelDescription(_ channels: Int) -> String {
        switch channels {
        case 1: return "Mono"
        case 2: return "Stereo"
        case 6: return "5.1"
        case 8: return "7.1"
        default: return "\(channels)ch"
        }
    }
}

/// MPV player using AVSampleBufferDisplayLayer for video output.
/// This enables Picture-in-Picture support on iOS.
final class MPVAVFoundationViewController: UIViewController {
    
    // MARK: - Properties
    
    /// The display layer that receives video frames from mpv
    private var displayLayer: AVSampleBufferDisplayLayer!
    
    /// The mpv player instance
    var mpv: OpaquePointer!
    
    /// Delegate for property changes
    var playDelegate: MPVPlayerDelegate?
    
    /// Queue for mpv events
    lazy var queue = DispatchQueue(label: "mpv.avfoundation", qos: .userInitiated)
    
    /// URL to play
    var playUrl: URL?
    
    /// Pending external subtitle URL to add when file is loaded
    private var pendingSubtitleUrl: URL?
    
    /// Picture-in-Picture controller
    private var pipController: AVPictureInPictureController?
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupDisplayLayer()
        setupMpv()
        setupPictureInPicture()
        
        if let url = playUrl {
            loadFile(url)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        displayLayer.frame = view.bounds
    }
    
    // MARK: - Setup
    
    private func setupDisplayLayer() {
        displayLayer = AVSampleBufferDisplayLayer()
        displayLayer.frame = view.bounds
        displayLayer.videoGravity = .resizeAspect
        displayLayer.backgroundColor = UIColor.black.cgColor
        
        // Setup control timebase for proper frame timing
        var timebase: CMTimebase?
        CMTimebaseCreateWithSourceClock(
            allocator: kCFAllocatorDefault,
            sourceClock: CMClockGetHostTimeClock(),
            timebaseOut: &timebase
        )
        
        if let timebase = timebase {
            displayLayer.controlTimebase = timebase
            CMTimebaseSetTime(timebase, time: .zero)
            CMTimebaseSetRate(timebase, rate: 1.0)
        }
        
        view.layer.addSublayer(displayLayer)
    }
    
    private func setupMpv() {
        mpv = mpv_create()
        guard mpv != nil else { return }
        
        // Disable verbose logging
        checkError(mpv_request_log_messages(mpv, "no"))
        
        // Pass the AVSampleBufferDisplayLayer to mpv via --wid
        var displayLayerPtr = Int64(Int(bitPattern: Unmanaged.passUnretained(displayLayer).toOpaque()))
        checkError(mpv_set_option(mpv, "wid", MPV_FORMAT_INT64, &displayLayerPtr))
        
        // Use AVFoundation video output - required for PiP support
        checkError(mpv_set_option_string(mpv, "vo", "avfoundation"))
        
        // Enable composite OSD mode - renders subtitles directly onto video frames
        checkError(mpv_set_option_string(mpv, "avfoundation-composite-osd", "yes"))
        checkError(mpv_set_option_string(mpv, "avfoundation-dv-hdr10-fallback", "yes"))
        
        // Hardware decoding with VideoToolbox
        checkError(mpv_set_option_string(mpv, "hwdec", "videotoolbox"))
        checkError(mpv_set_option_string(mpv, "hwdec-codecs", "all"))
        
        // Subtitle and audio settings
        checkError(mpv_set_option_string(mpv, "subs-match-os-language", "yes"))
        checkError(mpv_set_option_string(mpv, "subs-fallback", "yes"))
        checkError(mpv_set_option_string(mpv, "sub-font-size", "48"))
        checkError(mpv_set_option_string(mpv, "hwdec-software-fallback", "no"))
        
        // Initialize mpv
        checkError(mpv_initialize(mpv))
        
        // Observe properties
        mpv_observe_property(mpv, 0, MPVProperty.videoParamsSigPeak, MPV_FORMAT_DOUBLE)
        mpv_observe_property(mpv, 0, MPVProperty.pausedForCache, MPV_FORMAT_FLAG)
        mpv_observe_property(mpv, 0, MPVProperty.pause, MPV_FORMAT_FLAG)
        
        // Setup wakeup callback
        mpv_set_wakeup_callback(mpv, { ctx in
            let client = unsafeBitCast(ctx, to: MPVAVFoundationViewController.self)
            client.readEvents()
        }, UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()))
        
        setupNotifications()
    }
    
    private func setupPictureInPicture() {
        guard AVPictureInPictureController.isPictureInPictureSupported() else { return }
        
        let contentSource = AVPictureInPictureController.ContentSource(
            sampleBufferDisplayLayer: displayLayer,
            playbackDelegate: self
        )
        
        pipController = AVPictureInPictureController(contentSource: contentSource)
        pipController?.delegate = self
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(enterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(enterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }
    
    // MARK: - Background Handling
    
    @objc private func enterBackground() {
        if pipController?.isPictureInPictureActive == true { return }
        pause()
    }
    
    @objc private func enterForeground() {
        play()
    }
    
    // MARK: - Playback Control
    
    func loadFile(_ url: URL) {
        pendingSubtitleUrl = nil
        command("loadfile", args: [url.absoluteString, "replace"])
    }
    
    func loadFile(_ url: URL, withSubtitle subtitleUrl: URL) {
        pendingSubtitleUrl = subtitleUrl
        command("loadfile", args: [url.absoluteString, "replace"])
    }
    
    func togglePause() {
        getFlag(MPVProperty.pause) ? play() : pause()
    }
    
    func play() {
        setFlag(MPVProperty.pause, false)
    }
    
    func pause() {
        setFlag(MPVProperty.pause, true)
    }
    
    func seek(to seconds: Double) {
        command("seek", args: [String(seconds), "absolute"])
    }
    
    func seekRelative(_ seconds: Double) {
        command("seek", args: [String(seconds), "relative"])
    }
    
    // MARK: - Subtitle Control
    
    /// Get available subtitle tracks
    func getSubtitleTracks() -> [SubtitleTrack] {
        guard mpv != nil else { return [] }
        
        var tracks: [SubtitleTrack] = []
        tracks.append(SubtitleTrack(id: 0, title: "Off", language: nil, codec: nil))
        
        var trackCount: Int64 = 0
        mpv_get_property(mpv, "track-list/count", MPV_FORMAT_INT64, &trackCount)
        
        for i in 0..<trackCount {
            if getString("track-list/\(i)/type") == "sub" {
                var trackId: Int64 = 0
                mpv_get_property(mpv, "track-list/\(i)/id", MPV_FORMAT_INT64, &trackId)
                
                tracks.append(SubtitleTrack(
                    id: Int(trackId),
                    title: getString("track-list/\(i)/title"),
                    language: getString("track-list/\(i)/lang"),
                    codec: getString("track-list/\(i)/codec")
                ))
            }
        }
        
        return tracks
    }
    
    /// Get current subtitle track ID (0 = off)
    func getCurrentSubtitleId() -> Int {
        guard mpv != nil else { return 0 }
        var sid: Int64 = 0
        mpv_get_property(mpv, "sid", MPV_FORMAT_INT64, &sid)
        return Int(sid)
    }
    
    /// Set subtitle track by ID (0 = off)
    func setSubtitle(_ id: Int) {
        guard mpv != nil else { return }
        if id == 0 {
            command("set", args: ["sid", "no"])
        } else {
            command("set", args: ["sid", String(id)])
        }
    }
    
    /// Set subtitle delay in seconds
    func setSubtitleDelay(_ delay: Double) {
        guard mpv != nil else { return }
        command("set", args: ["sub-delay", String(delay)])
    }
    
    /// Add external subtitle from URL and select it
    func addSubtitle(_ url: URL) {
        guard mpv != nil else { return }
        command("sub-add", args: [url.absoluteString, "select"])
    }
    
    // MARK: - Audio Control
    
    /// Get available audio tracks
    func getAudioTracks() -> [AudioTrack] {
        guard mpv != nil else { return [] }
        
        var tracks: [AudioTrack] = []
        
        var trackCount: Int64 = 0
        mpv_get_property(mpv, "track-list/count", MPV_FORMAT_INT64, &trackCount)
        
        for i in 0..<trackCount {
            if getString("track-list/\(i)/type") == "audio" {
                var trackId: Int64 = 0
                mpv_get_property(mpv, "track-list/\(i)/id", MPV_FORMAT_INT64, &trackId)
                
                var channels: Int64 = 0
                mpv_get_property(mpv, "track-list/\(i)/audio-channels", MPV_FORMAT_INT64, &channels)
                
                tracks.append(AudioTrack(
                    id: Int(trackId),
                    title: getString("track-list/\(i)/title"),
                    language: getString("track-list/\(i)/lang"),
                    codec: getString("track-list/\(i)/codec"),
                    channels: channels > 0 ? Int(channels) : nil
                ))
            }
        }
        
        return tracks
    }
    
    /// Get current audio track ID
    func getCurrentAudioId() -> Int {
        guard mpv != nil else { return 0 }
        var aid: Int64 = 0
        mpv_get_property(mpv, "aid", MPV_FORMAT_INT64, &aid)
        return Int(aid)
    }
    
    /// Set audio track by ID
    func setAudio(_ id: Int) {
        guard mpv != nil else { return }
        command("set", args: ["aid", String(id)])
    }
    
    // MARK: - PiP Control
    
    func startPictureInPicture() {
        pipController?.startPictureInPicture()
    }
    
    func stopPictureInPicture() {
        pipController?.stopPictureInPicture()
    }
    
    var isPictureInPictureActive: Bool {
        pipController?.isPictureInPictureActive ?? false
    }
    
    var isPictureInPicturePossible: Bool {
        pipController?.isPictureInPicturePossible ?? false
    }
    
    // MARK: - MPV Helpers
    
    private func getDouble(_ name: String) -> Double {
        guard mpv != nil else { return 0.0 }
        var data = Double()
        mpv_get_property(mpv, name, MPV_FORMAT_DOUBLE, &data)
        return data
    }
    
    private func getString(_ name: String) -> String? {
        guard mpv != nil else { return nil }
        let cstr = mpv_get_property_string(mpv, name)
        let str: String? = cstr == nil ? nil : String(cString: cstr!)
        mpv_free(cstr)
        return str
    }
    
    private func getFlag(_ name: String) -> Bool {
        guard mpv != nil else { return false }
        var data = Int64()
        mpv_get_property(mpv, name, MPV_FORMAT_FLAG, &data)
        return data > 0
    }
    
    private func setFlag(_ name: String, _ flag: Bool) {
        guard mpv != nil else { return }
        var data: Int = flag ? 1 : 0
        mpv_set_property(mpv, name, MPV_FORMAT_FLAG, &data)
    }
    
    func command(_ command: String, args: [String?] = [], checkForErrors: Bool = true) {
        guard mpv != nil else { return }
        
        var cargs = makeCArgs(command, args).map { $0.flatMap { UnsafePointer<CChar>(strdup($0)) } }
        defer {
            for ptr in cargs where ptr != nil {
                free(UnsafeMutablePointer(mutating: ptr!))
            }
        }
        
        let returnValue = mpv_command(mpv, &cargs)
        if checkForErrors {
            checkError(returnValue)
        }
    }
    
    private func makeCArgs(_ command: String, _ args: [String?]) -> [String?] {
        if !args.isEmpty, args.last == nil {
            fatalError("Command do not need a nil suffix")
        }
        
        var strArgs = args
        strArgs.insert(command, at: 0)
        strArgs.append(nil)
        
        return strArgs
    }
    
    // MARK: - Event Handling
    
    func readEvents() {
        queue.async { [weak self] in
            guard let self = self else { return }
            
            while self.mpv != nil {
                let event = mpv_wait_event(self.mpv, 0)
                guard event?.pointee.event_id != MPV_EVENT_NONE else { break }
                
                switch event!.pointee.event_id {
                case MPV_EVENT_PROPERTY_CHANGE:
                    self.handlePropertyChange(event!)
                    
                case MPV_EVENT_SHUTDOWN:
                    mpv_terminate_destroy(self.mpv)
                    self.mpv = nil
                    
                case MPV_EVENT_FILE_LOADED:
                    if let subtitleUrl = self.pendingSubtitleUrl {
                        self.pendingSubtitleUrl = nil
                        self.addSubtitle(subtitleUrl)
                        self.command("set", args: ["sub-visibility", "yes"])
                    }
                    
                default:
                    break
                }
            }
        }
    }
    
    private func handlePropertyChange(_ event: UnsafePointer<mpv_event>) {
        let dataOpaquePtr = OpaquePointer(event.pointee.data)
        guard let property = UnsafePointer<mpv_event_property>(dataOpaquePtr)?.pointee else { return }
        
        let propertyName = String(cString: property.name)
        
        switch propertyName {
        case MPVProperty.videoParamsSigPeak:
            if let sigPeak = UnsafePointer<Double>(OpaquePointer(property.data))?.pointee {
                DispatchQueue.main.async { [weak self] in
                    self?.playDelegate?.propertyChange(mpv: self!.mpv, propertyName: propertyName, data: sigPeak)
                }
            }
            
        case MPVProperty.pausedForCache:
            let buffering = UnsafePointer<Bool>(OpaquePointer(property.data))?.pointee ?? true
            DispatchQueue.main.async { [weak self] in
                self?.playDelegate?.propertyChange(mpv: self!.mpv, propertyName: propertyName, data: buffering)
            }
            
        case MPVProperty.pause:
            let paused = UnsafePointer<Int>(OpaquePointer(property.data))?.pointee ?? 0
            DispatchQueue.main.async { [weak self] in
                self?.playDelegate?.propertyChange(mpv: self!.mpv, propertyName: propertyName, data: paused > 0)
            }
            
        default:
            break
        }
    }
    
    private func checkError(_ status: CInt) {
        if status < 0 {
            print("MPV API error: \(String(cString: mpv_error_string(status)))")
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        if mpv != nil {
            mpv_terminate_destroy(mpv)
            mpv = nil
        }
    }
}

// MARK: - AVPictureInPictureSampleBufferPlaybackDelegate

extension MPVAVFoundationViewController: AVPictureInPictureSampleBufferPlaybackDelegate {
    
    func pictureInPictureController(
        _ pictureInPictureController: AVPictureInPictureController,
        setPlaying playing: Bool
    ) {
        playing ? play() : pause()
    }
    
    func pictureInPictureControllerTimeRangeForPlayback(
        _ pictureInPictureController: AVPictureInPictureController
    ) -> CMTimeRange {
        let duration = getDouble("duration")
        if duration > 0 {
            return CMTimeRange(
                start: .zero,
                duration: CMTime(seconds: duration, preferredTimescale: 600)
            )
        }
        return CMTimeRange(start: .zero, duration: .positiveInfinity)
    }
    
    func pictureInPictureControllerIsPlaybackPaused(
        _ pictureInPictureController: AVPictureInPictureController
    ) -> Bool {
        return getFlag(MPVProperty.pause)
    }
    
    func pictureInPictureController(
        _ pictureInPictureController: AVPictureInPictureController,
        didTransitionToRenderSize newRenderSize: CMVideoDimensions
    ) {
        // Handle render size change if needed
    }
    
    func pictureInPictureController(
        _ pictureInPictureController: AVPictureInPictureController,
        skipByInterval skipInterval: CMTime,
        completion completionHandler: @escaping () -> Void
    ) {
        seekRelative(CMTimeGetSeconds(skipInterval))
        completionHandler()
    }
}

// MARK: - AVPictureInPictureControllerDelegate

extension MPVAVFoundationViewController: AVPictureInPictureControllerDelegate {
    
    func pictureInPictureControllerWillStartPictureInPicture(
        _ pictureInPictureController: AVPictureInPictureController
    ) {}
    
    func pictureInPictureControllerDidStartPictureInPicture(
        _ pictureInPictureController: AVPictureInPictureController
    ) {}
    
    func pictureInPictureControllerWillStopPictureInPicture(
        _ pictureInPictureController: AVPictureInPictureController
    ) {}
    
    func pictureInPictureControllerDidStopPictureInPicture(
        _ pictureInPictureController: AVPictureInPictureController
    ) {}
    
    func pictureInPictureController(
        _ pictureInPictureController: AVPictureInPictureController,
        failedToStartPictureInPictureWithError error: Error
    ) {}
    
    func pictureInPictureController(
        _ pictureInPictureController: AVPictureInPictureController,
        restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void
    ) {
        completionHandler(true)
    }
}
