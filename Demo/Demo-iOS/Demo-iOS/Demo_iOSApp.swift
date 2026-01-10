import SwiftUI
import AVFoundation

@main
struct Demo_iOSApp: App {
    
    init() {
        // Configure audio session for playback and PiP
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playback,
                mode: .moviePlayback,
                options: [.allowAirPlay]
            )
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to configure audio session: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            AVFoundationContentView()
        }
    }
}

/// View to select between different player implementations
struct PlayerSelectionView: View {
    @State private var selectedPlayer: PlayerType?
    
    enum PlayerType: String, CaseIterable {
        case metal = "Metal (Vulkan)"
        case avfoundation = "AVFoundation (PiP)"
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                Text("MPVKit Demo")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Select Player Type")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                VStack(spacing: 16) {
                    NavigationLink {
                        ContentView()
                            .navigationBarHidden(true)
                    } label: {
                        PlayerOptionCard(
                            title: "Metal (Vulkan)",
                            description: "GPU-accelerated rendering with HDR support",
                            icon: "cpu"
                        )
                    }
                    
                    NavigationLink {
                        AVFoundationContentView()
                            .navigationBarHidden(true)
                    } label: {
                        PlayerOptionCard(
                            title: "AVFoundation",
                            description: "Picture-in-Picture support using AVSampleBufferDisplayLayer",
                            icon: "pip"
                        )
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                Text("AVFoundation player requires vo-avfoundation build option")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
            }
            .padding(.top, 60)
        }
        .preferredColorScheme(.dark)
    }
}

struct PlayerOptionCard: View {
    let title: String
    let description: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(.blue)
                .frame(width: 50)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    PlayerSelectionView()
}
