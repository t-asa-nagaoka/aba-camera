//
//  CameraView.swift
//  aba-camera
//
//  Created by shiolab_asakura on 2025/01/14.
//

import SwiftUI
import SwiftData
import UIKit

struct CameraView: View {
    @EnvironmentObject var sceneDelegate: SceneDelegate
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) var dismiss
    @AppStorage("apiUrl") var apiUrl: String = ""
    @Query private var videos: [Video]
    @State private var video: Video?
    @State private var videoUrl: URL?
    @State private var extractPoints: [ExtractPoint]
    
    private var autoExtract: Bool {
        return URL(string: self.apiUrl) != nil && self.video != nil
    }
    
    private var canUseCamera: Bool {
        return UIImagePickerController.isSourceTypeAvailable(.camera)
    }
    
    init() {
        self.video = nil
        self.videoUrl = nil
        self.extractPoints = []
    }
    
    var body: some View {
        if (autoExtract) {
            VideoExtractProcessView(parent: video!, extractPoints: $extractPoints, autoExtract: true)
        } else if (videoUrl != nil) {
            VStack {
                Text("保存しています").font(.title3).padding(.vertical,12)
            }
            .onAppear {
                // 新しい動画ソースが存在する場合は撮影動画を新規追加
                Task {
                    await save()
                    if (!autoExtract) {
                        dismiss()
                    }
                }
            }
        } else if (canUseCamera) {
            CameraMoviePickerView(videoUrl: $videoUrl)
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
        } else {
            VStack {
                Text("カメラを起動できません").font(.title3).padding(.vertical,12)
                Button("前の画面に戻る") {
                    dismiss()
                }.font(.title3).bold().padding(.vertical,12)
            }
        }
    }
    
    // 新しい撮影動画として保存
    private func save() async {
        // 動画ソースが正常に読み込めた場合のみレコード追加
        let result: Video? = await Video.create(id: generateId(), source: videoUrl!)
        if let video = result {
            // タイトルの生成
            let format: DateFormatter = .init()
            format.dateFormat = "yyyy年MM月dd日 HH時mm分ss秒"
            video.title = format.string(from: video.recordedStart)
            
            // ファイル名をタイトルに合わせる
            _ = video.rename(fileName: video.title)
            
            // レコード追加
            self.context.insert(video)
            try! self.context.save()
            
            self.video = video
        }
    }
    
    // 重複しないUUIDの生成
    private func generateId() -> UUID {
        let id: UUID = .init()
        return videos.contains{ $0.id == id } ? generateId() : id
    }
}

#Preview {
    NavigationStack{
        CameraView()
            .modelContainer(for: [Video.self])
    }
}
