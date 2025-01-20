//
//  CameraView.swift
//  aba-camera
//
//  Created by shiolab_asakura on 2025/01/14.
//

import SwiftUI
import UIKit

struct CameraView: View {
    private let id: UUID
    
    @EnvironmentObject var sceneDelegate: SceneDelegate
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) var dismiss
    @State private var videoUrl: URL?
    
    init(id: UUID) {
        self.id = id
        self.videoUrl = nil
    }
    
    var body: some View {
        if (UIImagePickerController.isSourceTypeAvailable(.camera)) {
            CameraMoviePickerView(videoUrl: $videoUrl)
            .onAppear {
                // 画面の向きを縦方向でロック (カメラ部分はロック関係なく自動回転)
                OrientationController.shared.lockOrientation(to: .portrait, onWindow:sceneDelegate.window)
            }
            .onDisappear {
                // 画面の向き制御をアンロック
                OrientationController.shared.lockOrientation(to: .all, onWindow:sceneDelegate.window)
                // 新しい動画ソースが存在する場合は撮影動画を新規追加
                // 存在しない場合は前の画面に戻る
                if (videoUrl != nil) {
                    Task {
                        await save()
                    }
                }
                dismiss()
            }
            .statusBarHidden()
            .ignoresSafeArea(edges: [.all])
        } else {
            VStack {
                Text("カメラを起動できません").font(.title3).padding(.vertical,12)
                Button(action: {
                    dismiss()
                }) {
                    Text("前の画面に戻る").font(.title3).bold().padding(.vertical,12)
                }
            }
        }
    }
    
    // 新しい撮影動画として保存
    private func save() async {
        // 動画ソースが正常に読み込めた場合のみレコード追加
        let result: Video? = await Video.create(id: self.id, source: videoUrl!)
        if let video = result {
            // タイトルの生成
            let format: DateFormatter = .init()
            format.dateFormat = "yyyy.MM.dd"
            video.title = format.string(from: video.recordedStart)
            
            // レコード追加
            self.context.insert(video)
            try! self.context.save()
        }
    }
}

#Preview {
    NavigationStack{
        CameraView(id: .init())
            .modelContainer(for: [Video.self])
    }
}
