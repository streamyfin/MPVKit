import Foundation
import SwiftUI

/// SwiftUI wrapper for the AVFoundation-based MPV player.
/// Supports Picture-in-Picture on iOS.
struct MPVAVFoundationPlayerView: UIViewControllerRepresentable {
    @ObservedObject var coordinator: Coordinator
    
    func makeUIViewController(context: Context) -> some UIViewController {
        let mpv = MPVAVFoundationViewController()
        mpv.playDelegate = coordinator
        mpv.playUrl = coordinator.playUrl
        
        context.coordinator.player = mpv
        return mpv
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
    }
    
    public func makeCoordinator() -> Coordinator {
        coordinator
    }
    
    /// Set the initial URL to play
    func play(_ url: URL) -> Self {
        coordinator.playUrl = url
        return self
    }
    
    /// Handle property changes from mpv
    func onPropertyChange(_ handler: @escaping (MPVAVFoundationViewController, String, Any?) -> Void) -> Self {
        coordinator.onPropertyChange = handler
        return self
    }
    
    // MARK: - Coordinator
    
    @MainActor
    public final class Coordinator: MPVPlayerDelegate, ObservableObject {
        weak var player: MPVAVFoundationViewController?
        
        var playUrl: URL?
        var onPropertyChange: ((MPVAVFoundationViewController, String, Any?) -> Void)?
        
        @Published var isPaused: Bool = false
        @Published var isPiPActive: Bool = false
        @Published var isPiPPossible: Bool = false
        @Published var subtitleTracks: [SubtitleTrack] = []
        @Published var currentSubtitleId: Int = 0
        @Published var audioTracks: [AudioTrack] = []
        @Published var currentAudioId: Int = 0
        
        /// Load and play a URL
        func play(_ url: URL) {
            player?.loadFile(url)
        }
        
        /// Load and play a URL with an external subtitle
        func play(_ url: URL, withSubtitle subtitleUrl: URL) {
            player?.loadFile(url, withSubtitle: subtitleUrl)
        }
        
        /// Toggle play/pause
        func togglePause() {
            player?.togglePause()
        }
        
        /// Resume playback
        func resume() {
            player?.play()
        }
        
        /// Pause playback
        func pause() {
            player?.pause()
        }
        
        /// Seek to specific time
        func seek(to seconds: Double) {
            player?.seek(to: seconds)
        }
        
        /// Seek relative to current position
        func seekRelative(_ seconds: Double) {
            player?.seekRelative(seconds)
        }
        
        /// Start Picture-in-Picture
        func startPiP() {
            player?.startPictureInPicture()
        }
        
        /// Stop Picture-in-Picture
        func stopPiP() {
            player?.stopPictureInPicture()
        }
        
        /// Toggle Picture-in-Picture
        func togglePiP() {
            if player?.isPictureInPictureActive == true {
                stopPiP()
            } else {
                startPiP()
            }
        }
        
        // MARK: - Subtitles
        
        /// Refresh available subtitle tracks
        func refreshSubtitleTracks() {
            subtitleTracks = player?.getSubtitleTracks() ?? []
            currentSubtitleId = player?.getCurrentSubtitleId() ?? 0
        }
        
        /// Set subtitle track by ID (0 = off)
        func setSubtitle(_ id: Int) {
            player?.setSubtitle(id)
            currentSubtitleId = id
        }
        
        /// Add external subtitle from URL
        func addSubtitle(_ url: URL) {
            player?.addSubtitle(url)
        }
        
        /// Set subtitle delay
        func setSubtitleDelay(_ delay: Double) {
            player?.setSubtitleDelay(delay)
        }
        
        // MARK: - Audio
        
        /// Refresh available audio tracks
        func refreshAudioTracks() {
            audioTracks = player?.getAudioTracks() ?? []
            currentAudioId = player?.getCurrentAudioId() ?? 0
        }
        
        /// Set audio track by ID
        func setAudio(_ id: Int) {
            player?.setAudio(id)
            currentAudioId = id
        }
        
        // MARK: - MPVPlayerDelegate
        
        func propertyChange(mpv: OpaquePointer, propertyName: String, data: Any?) {
            guard let player else { return }
            
            // Update published properties
            switch propertyName {
            case MPVProperty.pause:
                isPaused = data as? Bool ?? false
            default:
                break
            }
            
            // Update PiP state
            isPiPActive = player.isPictureInPictureActive
            isPiPPossible = player.isPictureInPicturePossible
            
            // Call external handler
            onPropertyChange?(player, propertyName, data)
        }
    }
}
