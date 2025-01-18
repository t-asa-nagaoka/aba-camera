//
//  SceneVideoListView.swift
//  aba-camera
//
//  Created by shiolab_asakura on 2025/01/18.
//

import SwiftUI
import SwiftData
import Foundation

struct SceneVideoListView: View {
    
    @Environment(\.modelContext) private var context
    @Query private var sceneVideos: [SceneVideo]
    @State private var parent: RecordedVideo
    @State private var deletingVideo: SceneVideo?
    @State private var showExtractView: Bool
    @State private var showDeleteConfirmAlert: Bool
    @State private var showDeleteAllConfirmAlert: Bool
    @State private var showDeleteFilesFailedAlert : Bool
    
    private let format: DateFormatter
    
    // 撮影動画と関連付けられたシーン動画のリスト
    private var relatedVideos: [SceneVideo] {
        get {
            return self.sceneVideos.filter{ $0.parent == self.parent }
        }
    }
    
    // 並び替えたシーン動画のリスト
    private var sortedVideos: [SceneVideo] {
        get {
            // 録画開始日時の降順に並び替え
            return self.relatedVideos.sorted{  $0.recordedStart > $1.recordedStart }
        }
    }
    
    // 既存のシーン動画IDのリスト
    private var ids: [UUID] {
        get {
            return self.relatedVideos.map{ $0.id }
        }
    }
    
    init(parent: RecordedVideo) {
        self.parent = parent
        self.deletingVideo = nil
        self.showExtractView = false
        self.showDeleteConfirmAlert = false
        self.showDeleteAllConfirmAlert = false
        self.showDeleteFilesFailedAlert = false
        self.format = .init()
        self.format.dateFormat = "yyyy/MM/dd HH:mm:ss"
    }
    
    var body: some View {
        // 描画するViewのレイアウト
        List{
            // 抽出画面へのボタン
            Section {
                Button("シーン動画を抽出…") {
                    
                }.bold()
            }
            // シーン動画の一覧
            Section {
                ForEach(sortedVideos) { video in
                    NavigationLink(destination: Text("aaa")){
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
                Button("すべてのシーン動画を削除", role: .destructive){
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
        // 画面上部のタイトル
        .navigationTitle("シーン一覧")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // 空データの追加 (デバッグ用)
    #if DEBUG
    private func addEmpty() {
        let video: SceneVideo = .init()
        video.id = UUIDHelper.regenerateId(id: video.id, ids: self.ids)
        video.title = self.format.string(from: video.recordedStart)
        video.parent = self.parent
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
        self.showDeleteFilesFailedAlert =  !FileHelper.deleteFiles(urls: relatedVideos.map{ $0.videoUrl })
        // レコードの削除
        for video in self.relatedVideos {
            self.context.delete(video)
        }
    }
}

#Preview {
    NavigationStack{
        SceneVideoListView(parent: .init())
            .modelContainer(for: [RecordedVideo.self, SceneVideo.self])
    }
}
