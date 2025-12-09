import SwiftUI
import AVKit

/// Demo view using AVFoundation-based player with Picture-in-Picture support
struct AVFoundationContentView: View {
    @ObservedObject var coordinator = MPVAVFoundationPlayerView.Coordinator()
    @State private var loading = false
    @State private var showControls = true
    
    var body: some View {
        ZStack {
            // Player
            MPVAVFoundationPlayerView(coordinator: coordinator)
                .play(URL(string: "https://vjs.zencdn.net/v/oceans.mp4")!)
                .onPropertyChange { player, propertyName, propertyData in
                    switch propertyName {
                    case MPVProperty.pausedForCache:
                        loading = propertyData as? Bool ?? false
                    default:
                        break
                    }
                }
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation {
                        showControls.toggle()
                    }
                }
            
            // Overlay controls
            if showControls {
                controlsOverlay
            }
            
            // Loading indicator
            if loading {
                ProgressView()
                    .scaleEffect(1.5)
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
            }
        }
        .preferredColorScheme(.dark)
    }
    
    // MARK: - Controls Overlay
    
    private var controlsOverlay: some View {
        VStack {
            // Top bar with PiP button
            HStack {
                Spacer()
                
                Button {
                    coordinator.togglePiP()
                } label: {
                    Image(systemName: coordinator.isPiPActive ? "pip.exit" : "pip.enter")
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.black.opacity(0.5))
                        .clipShape(Circle())
                }
                .disabled(!coordinator.isPiPPossible && !coordinator.isPiPActive)
                .opacity(coordinator.isPiPPossible || coordinator.isPiPActive ? 1.0 : 0.5)
            }
            .padding()
            
            Spacer()
            
            // Center play/pause button
            Button {
                coordinator.togglePause()
            } label: {
                Image(systemName: coordinator.isPaused ? "play.circle.fill" : "pause.circle.fill")
                    .font(.system(size: 72))
                    .foregroundColor(.white)
                    .shadow(radius: 10)
            }
            
            Spacer()
            
            // Bottom: seek buttons and video selection
            VStack(spacing: 20) {
                // Seek controls
                HStack(spacing: 40) {
                    Button {
                        coordinator.seekRelative(-10)
                    } label: {
                        Image(systemName: "gobackward.10")
                            .font(.title)
                            .foregroundColor(.white)
                    }
                    
                    Button {
                        coordinator.seekRelative(10)
                    } label: {
                        Image(systemName: "goforward.10")
                            .font(.title)
                            .foregroundColor(.white)
                    }
                }
                
                // Video selection
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        videoButton("H.264", url: "https://vjs.zencdn.net/v/oceans.mp4")
                        videoButton("H.265", url: "https://github.com/mpvkit/video-test/raw/master/resources/h265.mp4")
                        videoButton("Subtitle", url: "https://github.com/mpvkit/video-test/raw/master/resources/pgs_subtitle.mkv")
                        videoButton("HDR", url: "https://github.com/mpvkit/video-test/raw/master/resources/hdr.mkv")
                        videoButton("DV P5", url: "https://github.com/mpvkit/video-test/raw/master/resources/DolbyVision_P5.mp4")
                        videoButton("DV P8", url: "https://github.com/mpvkit/video-test/raw/master/resources/DolbyVision_P8.mp4")
                        videoButton("4K", url: "https://jellyfin.alexprojects.kozow.com/Videos/4c01e7e8097e718effb7ee8cfe49d9f1/stream?static=true&container=mp4&mediaSourceId=4c01e7e8097e718effb7ee8cfe49d9f1&subtitleStreamIndex=2&audioStreamIndex=1&deviceId=634f30a2-7920-4181-9ab4-dbf5edc07642&api_key=8b75ef3681de4ceca00680a3b0312e57&startTimeTicks=0&maxStreamingBitrate=&userId=908309aaf78c4a87b3d27704c1a1b306")
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.bottom, 40)
            .background(
                LinearGradient(
                    colors: [.clear, .black.opacity(0.7)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
    }
    
    private func videoButton(_ title: String, url: String) -> some View {
        Button {
            if let videoUrl = URL(string: url) {
                coordinator.play(videoUrl)
            }
        } label: {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.2))
                .cornerRadius(8)
        }
    }
}

#Preview {
    AVFoundationContentView()
}
