//
//  VideoPlayerView.swift
//  aba-camera
//
//  Created by shiolab_asakura on 2025/01/16.
//

import SwiftUI
import AVKit

struct VideoPlayerView: View {
    private let videoUrl: URL
    
    @Environment(\.dismiss) private var dismiss
    @State private var player: AVPlayer?
    
    init(videoUrl: URL) {
        self.videoUrl = videoUrl
        self.player = nil
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea(edges: [.all])
            if let player = player {
                VStack {
                    HStack {
                        Spacer()
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark").foregroundStyle(Color.white)
                        }.padding(.all, 9)
                    }
                    VideoPlayer(player: player)
                }.padding(.bottom, 7)
            }
        }
        .onAppear {
            player = AVPlayer(url: videoUrl)
        }
        .statusBarHidden()
    }
    
    static func generatePreviewUrl () -> URL {
        let dir: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return dir.appendingPathComponent("xxxx.mp4")
    }
}

#Preview {
    VideoPlayerView(videoUrl: VideoPlayerView.generatePreviewUrl())
}
