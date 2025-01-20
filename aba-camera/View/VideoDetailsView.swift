//
//  VideoDetailsView.swift
//  aba-camera
//
//  Created by shiolab_asakura on 2025/01/15.
//

import SwiftUI
import SwiftData

struct VideoDetailsView: View {

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) var dismiss
    @State private var video: Video
    @State private var title: String
    @State private var memo: String
    @State private var showVideoPlayerView: Bool
    @State private var showVideoInfoEditView: Bool
    @State private var showRenameSuccessAlert: Bool
    @State private var showRenameFailedAlert: Bool
    @State private var showDeleteConfirmAlert: Bool
    @State private var showDeleteFilesFailedAlert: Bool
    
    private let ids: [UUID]
    private let format: DateFormatter
    
    private var updated: Bool {
        return self.video.title != self.title
        || self.video.memo != self.memo
    }
    
    // 編集
    init(video: Video) {
        self.video = video
        self.title = video.title
        self.memo = video.memo
        self.showVideoPlayerView = false
        self.showVideoInfoEditView = false
        self.showRenameSuccessAlert = false
        self.showRenameFailedAlert = false
        self.showDeleteConfirmAlert = false
        self.showDeleteFilesFailedAlert = false
        self.ids = []
        self.format = .init()
        self.format.dateFormat = "yyyy/MM/dd HH:mm:ss"
    }
    
    var body: some View {
        // 描画するViewのレイアウト
        Form {
            Section (header: Text("タイトル").font(.body)) {
                Text(title).font(.title3).bold()
            }
            if (memo != "") {
                Section (header: Text("メモ").font(.body)) {
                    Text(memo)
                }
            }
            #if DEBUG
            Section (header: Text("動画ID (デバッグ用)").font(.body)) {
                Text(video.id.uuidString)
            }
            #endif
            Section{
                HStack {
                    Text("録画開始")
                    Spacer()
                    Text(format.string(from:video.recordedStart)).foregroundStyle(Color.secondary)
                }
                HStack {
                    Text("録画終了")
                    Spacer()
                    Text(format.string(from:video.recordedEnd)).foregroundStyle(Color.secondary)
                }
            }
            if (video.isScene) {
                Section (header: Text("心拍スイッチ情報").font(.body)) {
                    HStack {
                        Text("発生日時")
                        Spacer()
                        Text(format.string(from:video.happend)).foregroundStyle(Color.secondary)
                    }
                    HStack {
                        Text("スイッチの種類")
                        Spacer()
                        Text(video.subjective ? "主観" : "心拍 (客観)").foregroundStyle(Color.secondary)
                    }
                }
            } else {
                Section {
                    NavigationLink(destination: VideoListView(parentId: video.id)) {
                        Text("行動シーン")
                    }
                }
            }
            Section {
                HStack {
                    Text(video.isScene ? "抽出日時" : "データ作成日時")
                    Spacer()
                    Text(format.string(from:video.created)).foregroundStyle(Color.secondary)
                }
            }
            Section {
                Button("タイトルとメモを編集") {
                    showVideoInfoEditView = true
                }
                Button("ファイル名をタイトルと同一にする") {
                    rename()
                }
                Button("この撮影動画を削除", role: .destructive){
                    showDeleteConfirmAlert = true
                }
            }
        }
        // ファイル名変更成功時のアラート
        .alert("ファイル名を変更しました。", isPresented: $showRenameSuccessAlert) {}
        // ファイル名変更失敗時のアラート
        .alert("ファイル名を変更できませんでした。", isPresented: $showRenameFailedAlert) {}
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
        // ツールバーに再生ボタンを設置
        .toolbar{
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showVideoPlayerView = true
                } label: {
                    Image(systemName: "play")
                    Text("再生")
                }
            }
        }
        // 再生画面への遷移
        .fullScreenCover(isPresented: $showVideoPlayerView) {
            VideoPlayerView(videoUrl: video.fileUrl)
        }
        // 情報の編集画面への遷移
        .sheet(isPresented: $showVideoInfoEditView) {
            NavigationStack {
                VideoInfoEditView(video: video, title: $title, memo: $memo)
                    .onDisappear{
                        if (updated) {
                            try! context.save()
                        }
                    }
            }
            .interactiveDismissDisabled()
        }
        .navigationTitle(video.isScene ? "行動シーン" : "撮影動画")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // ファイル名の変更
    private func rename() {
        if (video.rename(fileName: title)) {
            try! context.save()
            showRenameSuccessAlert = true
        } else {
            showRenameFailedAlert = true
        }
    }
    
    // 撮影動画の削除
    private func delete() {
        // 動画ファイルの削除
        self.showDeleteFilesFailedAlert =  !FileHelper.deleteFiles(urls: [self.video.fileUrl])
        // レコードの削除
        self.context.delete(self.video)
        try! self.context.save()
        // 動画ファイルが正常に削除された場合は前の画面に戻る
        if (!self.showDeleteFilesFailedAlert) {
            dismiss()
        }
    }
}

#Preview {
    NavigationStack{
        VideoDetailsView(video: .init())
            .modelContainer(for: [Video.self])
    }
}
