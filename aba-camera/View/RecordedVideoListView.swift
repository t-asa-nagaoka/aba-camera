//
//  RecordedEventListView.swift
//  aba-camera
//
//  Created by shiolab_asakura on 2025/01/13.
//

import SwiftUI
import SwiftData
import Foundation

struct RecordedVideoListView: View {
    
    @Environment(\.modelContext) private var context
    @Query private var videos: [RecordedVideo]
    @State private var deletingVideo: RecordedVideo?
    @State private var showAppSettingsView: Bool
    @State private var showDeleteConfirmAlert: Bool
    @State private var showDeleteAllConfirmAlert: Bool
    @State private var showDeleteFilesFailedAlert : Bool
    
    private let format: DateFormatter
    
    // 並び替えた撮影動画のリスト
    private var sortedVideos: [RecordedVideo] {
        get {
            // 録画開始日時の降順に並び替え
            return self.videos.sorted{ $0.recordedStart > $1.recordedStart }
        }
    }
    
    // 既存の撮影動画IDのリスト
    private var ids: [UUID] {
        get {
            return self.videos.map{ $0.id }
        }
    }
    
    init() {
        self.deletingVideo = nil
        self.showAppSettingsView = false
        self.showDeleteConfirmAlert = false
        self.showDeleteAllConfirmAlert = false
        self.showDeleteFilesFailedAlert = false
        self.format = .init()
        self.format.dateFormat = "yyyy/MM/dd HH:mm:ss"
    }
    
    var body: some View {
        // 描画するViewのレイアウト
        List{
            // カメラ画面へのナビゲーション (詳細画面からの自動遷移)
            Section {
                NavigationLink(destination: RecordedVideoDetailsView(ids: ids)){
                    HStack {
                        Image(systemName: "camera").bold().imageScale(.large).foregroundStyle(Color.blue)
                        VStack(alignment: .leading) {
                            Text("カメラを起動して撮影").foregroundStyle(Color.primary).font(.title3).bold().padding(.vertical, 4)
                            Text("新しい動画を撮影します。").foregroundStyle(Color.secondary)
                        }.padding(.leading, 3)
                    }
                }
            }
            // 撮影動画の一覧
            Section {
                ForEach(sortedVideos) { video in
                    NavigationLink(destination: RecordedVideoDetailsView(video: video)){
                        VStack(alignment: .leading) {
                            Text(video.title).font(.title3).bold()
                                .padding(.vertical, 4)
                            Text(format.string(from: video.recordedStart)).foregroundStyle(Color.secondary)
                        }
                    }.swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button {
                            deletingVideo = video
                            showDeleteConfirmAlert = true
                        } label: {
                            Image(systemName: "trash.fill")
                        }.tint(.red)
                    }
                }
            }
            // 追加(デバッグ用)・削除のボタン
            Section {
                #if DEBUG
                Button("空データを追加 (デバッグ用)") {
                    addEmpty()
                }
                #endif
                Button("すべての撮影動画を削除", role: .destructive){
                    showDeleteAllConfirmAlert = true
                }
            }
        }
        // 動画削除前の確認アラート
        .alert("動画を削除しますか?", isPresented: $showDeleteConfirmAlert) {
            Button("キャンセル", role: .cancel) {
                deletingVideo = nil
            }
            Button("削除", role: .destructive){
                delete()
            }
        } message: {
            Text("この操作は取り消せません。")
        }
        // 動画全削除前の確認アラート
        .alert("すべての動画を削除しますか?", isPresented: $showDeleteAllConfirmAlert) {
            Button("キャンセル", role: .cancel) {}
            Button("全削除", role: .destructive){
                deleteAll()
            }
        } message: {
            Text("この操作は取り消せません。")
        }
        // 動画ファイル削除失敗時のアラート
        .alert("一部またはすべての動画ファイルを削除できませんでした。", isPresented: $showDeleteFilesFailedAlert) {
            
        } message: {
            Text("表示上では動画は削除されていますが、アプリ内に動画ファイルの実体が格納されています。")
        }
        // ツールバーに設定ボタンを設置
        .toolbar{
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showAppSettingsView = true
                } label: {
                    Image(systemName: "gearshape")
                    Text("設定")
                }
            }
        }
        // 設定画面への遷移
        .sheet(isPresented: $showAppSettingsView) {
            NavigationStack {
                AppSettingsView()
            }
            .interactiveDismissDisabled()
        }
        // 画面上部のタイトル
        .navigationTitle("動画一覧")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // 空データの追加 (デバッグ用)
    #if DEBUG
    private func addEmpty() {
        let video: RecordedVideo = .init()
        video.id = UUIDHelper.regenerateId(id: video.id, ids: self.ids)
        video.title = self.format.string(from: video.recordedStart)
        self.context.insert(video)
    }
    #endif

    // 撮影動画の削除
    private func delete() {
        // 動画ファイルの削除
        self.showDeleteFilesFailedAlert = !(self.deletingVideo!.deleteSource())
        // レコードの削除
        self.context.delete(self.deletingVideo!)
        // 削除指定を解除
        self.deletingVideo = nil
    }
    
    // 撮影動画の全削除
    private func deleteAll() {
        // 動画ファイルの削除
        self.showDeleteFilesFailedAlert =  !FileHelper.deleteAllFiles()
        // レコードの削除
        for video in self.videos {
            self.context.delete(video)
        }
    }
}

#Preview {
    NavigationStack{
        RecordedVideoListView()
            .modelContainer(for: [RecordedVideo.self, SceneVideo.self])
    }
}
