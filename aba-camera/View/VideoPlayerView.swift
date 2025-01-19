//
//  VideoPlayerView.swift
//  aba-camera
//
//  Created by shiolab_asakura on 2025/01/16.
//

import SwiftUI
import AVKit

struct VideoPlayerView: View {
    
    @Environment(\.dismiss) private var dismiss
    @State private var player: AVPlayer?
    @State private var playerStarted: Bool
    private let videoUrl: URL?
    
    private var exists: Bool {
        return videoUrl != nil && FileManager.default.fileExists(atPath: videoUrl!.path)
    }
    
    init(videoUrl: URL?) {
        self.videoUrl = videoUrl
        playerStarted = false
    }
    
    var body: some View {
        if (exists) {
            ZStack {
                Color.black.ignoresSafeArea(edges: [.all])
                if (player != nil) {
                    VStack {
                        HStack {
                            Spacer()
                            
                            Button {
                                dismiss()
                            } label: {
                                Image(systemName: "xmark").foregroundStyle(Color.white)
                            }.padding(.all, 9)
                            
                        }
                        VideoPlayer(player: player!)
                    }.padding(.bottom, 7)
                }
            }
            .onAppear {
                player = AVPlayer(url: videoUrl!)
            }
            .statusBarHidden()
        } else {
            VStack {
                Text("動画ファイルが見つかりません").font(.title3).padding(.vertical,12)
                Button(action: {
                    dismiss()
                }) {
                    Text("前の画面に戻る").font(.title3).bold().padding(.vertical,12)
                }
            }
        }
    }
}

#Preview {
    VideoPlayerView(videoUrl: nil)
}
