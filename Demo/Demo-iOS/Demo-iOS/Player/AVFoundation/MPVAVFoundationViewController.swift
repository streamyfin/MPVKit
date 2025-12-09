import Foundation
import UIKit
import AVFoundation
import AVKit
import Libmpv

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
        guard mpv != nil else {
            print("Failed to create mpv context")
            return
        }
        
        // Logging
        #if DEBUG
        checkError(mpv_request_log_messages(mpv, "debug"))
        #else
        checkError(mpv_request_log_messages(mpv, "no"))
        #endif
        
        // Pass the AVSampleBufferDisplayLayer to mpv via --wid
        // The vo_avfoundation driver expects this
        var displayLayerPtr = Int64(Int(bitPattern: Unmanaged.passUnretained(displayLayer).toOpaque()))
        checkError(mpv_set_option(mpv, "wid", MPV_FORMAT_INT64, &displayLayerPtr))
        
        // Use AVFoundation video output - required for PiP support
        checkError(mpv_set_option_string(mpv, "vo", "avfoundation"))
        
        // Enable composite OSD mode - renders subtitles directly onto video frames using GPU
        // This is better for PiP as subtitles are baked into the video
        checkError(mpv_set_option_string(mpv, "avfoundation-composite-osd", "yes"))
        
        // Hardware decoding with VideoToolbox - REQUIRED for vo_avfoundation
        // vo_avfoundation ONLY accepts IMGFMT_VIDEOTOOLBOX frames
        checkError(mpv_set_option_string(mpv, "hwdec", "videotoolbox"))
        checkError(mpv_set_option_string(mpv, "hwdec-codecs", "all"))
        
        // Subtitle and audio settings
        checkError(mpv_set_option_string(mpv, "subs-match-os-language", "yes"))
        checkError(mpv_set_option_string(mpv, "subs-fallback", "yes"))
        
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
        guard AVPictureInPictureController.isPictureInPictureSupported() else {
            print("PiP not supported on this device")
            return
        }
        
        // Create PiP content source with the sample buffer display layer
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
        // Don't stop video if PiP is active
        if pipController?.isPictureInPictureActive == true {
            return
        }
        pause()
    }
    
    @objc private func enterForeground() {
        play()
    }
    
    // MARK: - Playback Control
    
    func loadFile(_ url: URL) {
        var args = [url.absoluteString, "replace"]
        command("loadfile", args: args)
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
    
    func command(
        _ command: String,
        args: [String?] = [],
        checkForErrors: Bool = true,
        returnValueCallback: ((Int32) -> Void)? = nil
    ) {
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
        returnValueCallback?(returnValue)
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
                    print("mpv: shutdown")
                    mpv_terminate_destroy(self.mpv)
                    self.mpv = nil
                    
                case MPV_EVENT_LOG_MESSAGE:
                    let msg = UnsafeMutablePointer<mpv_event_log_message>(OpaquePointer(event!.pointee.data))
                    if let msg = msg {
                        print("[\(String(cString: msg.pointee.prefix!))] \(String(cString: msg.pointee.level!)): \(String(cString: msg.pointee.text!))", terminator: "")
                    }
                    
                case MPV_EVENT_FILE_LOADED:
                    print("mpv: file loaded")
                    self.printSubtitleInfo()
                    
                case MPV_EVENT_PLAYBACK_RESTART:
                    print("mpv: playback restart")
                    self.printSubtitleInfo()
                    
                default:
                    if let eventName = mpv_event_name(event!.pointee.event_id) {
                        print("mpv event: \(String(cString: eventName))")
                    }
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
    
    // MARK: - Subtitle Debug Info
    
    private func printSubtitleInfo() {
        guard mpv != nil else { return }
        
        print("\n========== SUBTITLE INFO ==========")
        
        // Get current subtitle ID
        var sid: Int64 = 0
        mpv_get_property(mpv, "sid", MPV_FORMAT_INT64, &sid)
        print("Current SID: \(sid)")
        
        // Get subtitle delay
        var subDelay: Double = 0
        mpv_get_property(mpv, "sub-delay", MPV_FORMAT_DOUBLE, &subDelay)
        print("Sub Delay: \(subDelay)")
        
        // Get sub-visibility
        var subVisible: Int64 = 0
        mpv_get_property(mpv, "sub-visibility", MPV_FORMAT_FLAG, &subVisible)
        print("Sub Visibility: \(subVisible > 0 ? "YES" : "NO")")
        
        // Get track count
        var trackCount: Int64 = 0
        mpv_get_property(mpv, "track-list/count", MPV_FORMAT_INT64, &trackCount)
        print("Total Tracks: \(trackCount)")
        
        // List all subtitle tracks
        print("\n--- Available Tracks ---")
        for i in 0..<trackCount {
            // Get track type
            if let typeStr = getString("track-list/\(i)/type") {
                // Get track ID
                var trackId: Int64 = 0
                mpv_get_property(mpv, "track-list/\(i)/id", MPV_FORMAT_INT64, &trackId)
                
                // Get track title
                let title = getString("track-list/\(i)/title") ?? "(no title)"
                
                // Get track language
                let lang = getString("track-list/\(i)/lang") ?? "(no lang)"
                
                // Get codec
                let codec = getString("track-list/\(i)/codec") ?? "(unknown)"
                
                // Check if selected
                var selected: Int64 = 0
                mpv_get_property(mpv, "track-list/\(i)/selected", MPV_FORMAT_FLAG, &selected)
                
                let marker = selected > 0 ? ">>> " : "    "
                print("\(marker)[\(typeStr)] ID=\(trackId): \(title) [\(lang)] codec=\(codec)")
            }
        }
        
        print("====================================\n")
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
        if playing {
            play()
        } else {
            pause()
        }
    }
    
    func pictureInPictureControllerTimeRangeForPlayback(
        _ pictureInPictureController: AVPictureInPictureController
    ) -> CMTimeRange {
        // Return the full duration if known, otherwise return indefinite
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
        print("PiP render size: \(newRenderSize.width)x\(newRenderSize.height)")
    }
    
    func pictureInPictureController(
        _ pictureInPictureController: AVPictureInPictureController,
        skipByInterval skipInterval: CMTime,
        completion completionHandler: @escaping () -> Void
    ) {
        let seconds = CMTimeGetSeconds(skipInterval)
        seekRelative(seconds)
        completionHandler()
    }
}

// MARK: - AVPictureInPictureControllerDelegate

extension MPVAVFoundationViewController: AVPictureInPictureControllerDelegate {
    
    func pictureInPictureControllerWillStartPictureInPicture(
        _ pictureInPictureController: AVPictureInPictureController
    ) {
        print("PiP will start")
    }
    
    func pictureInPictureControllerDidStartPictureInPicture(
        _ pictureInPictureController: AVPictureInPictureController
    ) {
        print("PiP did start")
    }
    
    func pictureInPictureControllerWillStopPictureInPicture(
        _ pictureInPictureController: AVPictureInPictureController
    ) {
        print("PiP will stop")
    }
    
    func pictureInPictureControllerDidStopPictureInPicture(
        _ pictureInPictureController: AVPictureInPictureController
    ) {
        print("PiP did stop")
    }
    
    func pictureInPictureController(
        _ pictureInPictureController: AVPictureInPictureController,
        failedToStartPictureInPictureWithError error: Error
    ) {
        print("PiP failed to start: \(error)")
    }
    
    func pictureInPictureController(
        _ pictureInPictureController: AVPictureInPictureController,
        restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void
    ) {
        // Restore UI when PiP stops
        completionHandler(true)
    }
}
