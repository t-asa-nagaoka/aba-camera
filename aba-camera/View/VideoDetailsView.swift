//
//  VideoDetailsView.swift
//  aba-camera
//
//  Created by shiolab_asakura on 2025/01/15.
//

import SwiftUI
import SwiftData

struct VideoDetailsView: View {
    private let video: Video

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) var dismiss
    @Query private var videos: [Video]
    @State private var title: String
    @State private var memo: String
    @State private var fileUrl: URL
    @State private var showVideoExtractView: Bool
    @State private var showVideoPlayerView: Bool
    @State private var showVideoInfoEditView: Bool
    @State private var showRenameSuccessAlert: Bool
    @State private var showRenameFailedAlert: Bool
    @State private var showDeleteConfirmAlert: Bool
    @State private var showDeleteFilesFailedAlert: Bool
    
    private let format: DateFormatter
    
    private var fileExists: Bool {
        return FileManager.default.fileExists(atPath: self.fileUrl.path)
    }
    
    private var updated: Bool {
        return self.video.title != self.title
        || self.video.memo != self.memo
    }
    
    init(video: Video) {
        self.video = video
        self.title = video.title
        self.memo = video.memo
        self.fileUrl = video.fileUrl
        self.showVideoExtractView = false
        self.showVideoPlayerView = false
        self.showVideoInfoEditView = false
        self.showRenameSuccessAlert = false
        self.showRenameFailedAlert = false
        self.showDeleteConfirmAlert = false
        self.showDeleteFilesFailedAlert = false
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
            if (video.parentId != nil) {
                Section (header: Text("親動画ID (デバッグ用)").font(.body)) {
                    Text(video.parentId!.uuidString)
                }
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
                        Text("作動日時")
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
                if (fileExists) {
                    Section {
                        Button {
                            showVideoExtractView = true
                        } label: {
                            Label {
                                Text("行動シーンの抽出").bold()
                            } icon: {
                                Image(systemName: "movieclapper")
                            }
                        }
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
                Button {
                    showVideoInfoEditView = true
                } label: {
                    Label("タイトルとメモを編集", systemImage:"pencil.line")
                }
                if (fileExists) {
                    Button {
                        rename()
                    } label: {
                        Label("ファイル名をタイトルと同一にする", systemImage: "rectangle.and.pencil.and.ellipsis")
                    }
                    ShareLink("他のアプリに送信・保存", item: fileUrl)
                }
            }
            Section {
                Button(role: .destructive){
                    showDeleteConfirmAlert = true
                } label: {
                    Label("この動画を削除", systemImage: "trash").foregroundStyle(Color.red)
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
                .disabled(!fileExists)
            }
        }
        // 抽出画面への遷移
        .navigationDestination(isPresented: $showVideoExtractView) {
            VideoExtractView(video: video)
        }
        // 再生画面への遷移
        .fullScreenCover(isPresented: $showVideoPlayerView) {
            VideoPlayerView(videoUrl: fileUrl)
        }
        // 情報の編集画面への遷移
        .sheet(isPresented: $showVideoInfoEditView) {
            NavigationStack {
                VideoInfoEditView(video: video, title: $title, memo: $memo)
                .onDisappear {
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
            self.fileUrl = video.fileUrl
            try! context.save()
            showRenameSuccessAlert = true
        } else {
            showRenameFailedAlert = true
        }
    }
    
    // 撮影動画の削除
    private func delete() {
        // 関連付けの解除
        detachRelations()
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
    
    // 撮影動画→行動シーンの関連付けの解除
    private func detachRelations() {
        for video in self.videos {
            if (video.parentId == self.video.id) {
                video.parentId = nil
            }
        }
        try! self.context.save()
    }
}

#Preview {
    NavigationStack{
        VideoDetailsView(video: .init())
            .modelContainer(for: [Video.self])
    }
}
