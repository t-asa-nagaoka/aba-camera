//
//  RecordedVideoDetailsView.swift
//  aba-camera
//
//  Created by shiolab_asakura on 2025/01/15.
//

import SwiftUI
import SwiftData

struct RecordedVideoDetailsView: View {

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) var dismiss
    @State private var video: RecordedVideo?
    @State private var videoUrl: URL?
    @State private var title: String
    @State private var memo: String
    @State private var showCameraView: Bool
    @State private var showVideoPlayerView: Bool
    @State private var showVideoInfoEditView: Bool
    @State private var showDeleteConfirmAlert: Bool
    @State private var showDeleteFilesFailedAlert: Bool
    
    private let ids: [UUID]
    private let format: DateFormatter
    
    private var updated: Bool {
        get {
            return self.video?.title ?? "" != self.title
            || self.video?.memo ?? "" != self.memo
        }
    }
    
    // 新規追加
    init(ids: [UUID]) {
        self.video = nil
        self.videoUrl = nil
        self.title = ""
        self.memo = ""
        self.showCameraView = false
        self.showVideoPlayerView = false
        self.showVideoInfoEditView = false
        self.showDeleteConfirmAlert = false
        self.showDeleteFilesFailedAlert = false
        self.ids = ids
        self.format = .init()
        self.format.dateFormat = "yyyy/MM/dd HH:mm:ss"
    }
    
    // 編集
    init(video: RecordedVideo) {
        self.video = video
        self.videoUrl = nil
        self.title = video.title
        self.memo = video.memo
        self.showCameraView = false
        self.showVideoPlayerView = false
        self.showVideoInfoEditView = false
        self.showDeleteConfirmAlert = false
        self.showDeleteFilesFailedAlert = false
        self.ids = []
        self.format = .init()
        self.format.dateFormat = "yyyy/MM/dd HH:mm:ss"
    }
    
    var body: some View {
        // 描画するViewのレイアウト
        Form {
            if (video != nil) {
                Section (header: Text("タイトル").font(.body)) {
                    Text(title).font(.title3).bold()
                }
                if (memo != "") {
                    Section (header: Text("メモ").font(.body)) {
                        Text(memo)
                    }
                }
                #if DEBUG
                Section (header: Text("撮影動画ID (デバッグ用)").font(.body)) {
                    Text(video!.id.uuidString)
                }
                #endif
                Section{
                    HStack {
                        Text("録画開始")
                        Spacer()
                        Text(format.string(from:video!.recordedStart)).foregroundStyle(Color.secondary)
                    }
                    HStack {
                        Text("録画終了")
                        Spacer()
                        Text(format.string(from:video!.recordedEnd)).foregroundStyle(Color.secondary)
                    }
                }
                Section {
                    NavigationLink(destination: SceneVideoListView(parent: video!)) {
                        Text("シーン動画の一覧")
                    }
                }
                Section {
                    Button("タイトルとメモを編集…") {
                        showVideoInfoEditView = true
                    }
                    Button("この撮影動画を削除", role: .destructive){
                        showDeleteConfirmAlert = true
                    }
                }
            } else {
                Text("しばらくお待ちください")
            }
        }
        // 動画削除前の確認アラート
        .alert("動画を削除しますか?", isPresented: $showDeleteConfirmAlert) {
            Button("キャンセル", role: .cancel) {}
            Button("削除", role: .destructive){
                delete()
            }
        } message: {
            Text("この操作は取り消せません。")
        }
        // 動画ファイル削除失敗時のアラート
        .alert("一部またはすべての動画ファイルを削除できませんでした。", isPresented: $showDeleteFilesFailedAlert) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("表示上では動画は削除されていますが、アプリ内に動画ファイルの実体が格納されています。")
        }
        // 描画直後の処理
        .onAppear{
            if (video == nil) {
                // 前の画面からの遷移アニメーションが完全に止まってからカメラに切り替える
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
                    showCameraView = true
                })
            }
        }
        // カメラ画面への遷移
        .fullScreenCover(isPresented: $showCameraView) {
            CameraView(videoUrl: $videoUrl)
            .onDisappear {
                // 新しい動画ソースが存在する場合は撮影動画を新規追加
                // 存在しない場合は前の画面に戻る
                if (videoUrl != nil) {
                    Task {
                        await saveAsNew()
                    }
                } else {
                    dismiss()
                }
            }
        }
        // ツールバーに再生ボタンを設置
        .toolbar{
            if (video != nil) {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showVideoPlayerView = true
                    } label: {
                        Image(systemName: "play")
                        Text("再生")
                    }
                }
            }
        }
        // 再生画面への遷移
        .fullScreenCover(isPresented: $showVideoPlayerView) {
            VideoPlayerView(videoUrl: video!.videoUrl)
        }
        // 情報の編集画面への遷移
        .sheet(isPresented: $showVideoInfoEditView) {
            NavigationStack {
                VideoInfoEditView(current: video!, title: $title, memo: $memo)
                    .onDisappear{
                        if (updated) {
                            video!.title = title
                            video!.memo = memo
                            try! context.save()
                        }
                    }
            }
            .interactiveDismissDisabled()
        }
        .navigationTitle("撮影動画")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // 新しい撮影動画として保存
    private func saveAsNew() async {
        // 動画ソースが正常に読み込めた場合のみレコード追加
        // 失敗した場合は前の画面に戻る
        let video: RecordedVideo = .init()
        video.id = UUIDHelper.regenerateId(id: video.id, ids: self.ids)
        let result: Bool = await video.importSource(source: self.videoUrl!)
        self.videoUrl = nil
        if (result) {
            // タイトルの自動生成
            video.title = self.format.string(from: video.recordedStart)
            
            // レコード追加・UI反映
            self.context.insert(video)
            self.title = video.title
            self.memo = video.memo
            self.video = video
        } else {
            dismiss()
        }
    }
    
    // 撮影動画の削除
    private func delete() {
        // 動画ファイルの削除
        self.showDeleteFilesFailedAlert =  !(self.video!.deleteSource())
        // レコードの削除
        self.context.delete(self.video!)
        // 動画ファイルが正常に削除された場合は前の画面に戻る
        if (!self.showDeleteFilesFailedAlert) {
            dismiss()
        }
    }
}

#Preview {
    NavigationStack{
        RecordedVideoDetailsView(video: .init())
            .modelContainer(for: [RecordedVideo.self, SceneVideo.self])
    }
}
