//
//  CameraView.swift
//  aba-camera
//
//  Created by shiolab_asakura on 2025/01/14.
//

import SwiftUI
import UIKit

struct CameraView: View {
    
    @EnvironmentObject var sceneDelegate: SceneDelegate
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) var dismiss
    @Binding var videoUrl: URL?
    @State private var cancelled: Bool = false
    
    #if DEBUG
    private var debugUrl: URL
    
    init(videoUrl: Binding<URL?>) {
        self._videoUrl = videoUrl
        let dir: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        debugUrl = dir.appendingPathComponent("xxxx.mp4")
    }
    #endif
    
    var body: some View {
        // 撮影終了後の処理 : 前の画面に戻る
        if (videoUrl != nil) {
            VStack{}.onAppear{
                dismiss()
            }
        }
        // 撮影キャンセル後の処理 : 前の画面に戻る
        else if (cancelled) {
            VStack{}.onAppear{
                videoUrl = nil
                dismiss()
            }
        }
        // カメラが使用可能な場合 : カメラを起動する
        else if (UIImagePickerController.isSourceTypeAvailable(.camera)) {
            CameraMoviePickerView(videoUrl: $videoUrl, cancelled: $cancelled)
            .onAppear {
                // 画面の向きを縦方向でロック (カメラ部分はロック関係なく自動回転)
                OrientationController.shared.lockOrientation(to: .portrait, onWindow:sceneDelegate.window)
            }
            .onDisappear {
                // 画面の向き制御をアンロック
                OrientationController.shared.lockOrientation(to: .all, onWindow:sceneDelegate.window)
            }
            .statusBarHidden()
            .ignoresSafeArea(edges: [.all])
        }
        // カメラが使用できない場合
        else {
            VStack {
                Text("カメラを起動できませんでした").font(.title3).padding(.vertical,12)
                Button(action: {
                    dismiss()
                }) {
                    Text("前の画面に戻る").font(.title3).bold().padding(.vertical,12)
                }
                #if DEBUG
                Text(debugUrl.path)
                Button(action: {
                    videoUrl = debugUrl
                }) {
                    Text("強制的に続行 (デバッグ用)").font(.title3).bold().padding(.vertical,12)
                }
                #endif
            }
        }
    }
}

#Preview {
    NavigationStack{
        CameraView(videoUrl: .constant(nil))
    }
}
