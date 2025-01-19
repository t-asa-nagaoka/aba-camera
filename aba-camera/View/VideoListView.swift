//
//  VideoListView.swift
//  aba-camera
//
//  Created by shiolab_asakura on 2025/01/19.
//

import SwiftUI
import SwiftData

enum VideoListFilterMode: Int {
    case all = 0
    case recordedOnly = 1
    case sceneOnly = 2
}

struct VideoListView: View {
    private let parentId: UUID?
    
    @Environment(\.modelContext) private var context
    @Query private var videos: [Video]
    @State private var deletingVideo: Video?
    @State private var filterMode: VideoListFilterMode
    @State private var showAppSettingsView: Bool
    @State private var showDeleteConfirmAlert: Bool
    @State private var showDeleteAllConfirmAlert: Bool
    @State private var showDeleteFilesFailedAlert : Bool
    
    private let format: DateFormatter
    
    // 画面上部のタイトル
    private var viewTitle: String {
        switch self.filterMode {
        case .all:
            return "すべて"
        case .recordedOnly:
            return "撮影履歴"
        case .sceneOnly:
            return "シーン一覧"
        }
    }
    
    // フィルタを適用した動画のリスト
    private var filteredVideos: [Video] {
        switch self.filterMode {
        case .all:
            return self.videos
        case .recordedOnly:
            return self.videos.filter { $0.isScene == false }
        case .sceneOnly:
            if (self.parentId != nil) {
                return self.videos.filter { $0.isScene == true && $0.parentId == self.parentId }
            }
            
            return self.videos.filter { $0.isScene == true }
        }
    }
    
    // 並び替えた動画のリスト
    private var sortedVideos: [Video] {
        // 録画開始日時の降順に並び替え
        return self.filteredVideos.sorted{ $0.recordedStart > $1.recordedStart }
    }
    
    // 既存の動画IDのリスト
    private var ids: [UUID] {
        return self.filteredVideos.map{ $0.id }
    }
    
    init() {
        self.parentId = nil
        self.deletingVideo = nil
        self.filterMode = .recordedOnly
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
            // 撮影ボタン
            if (filterMode != .sceneOnly) {
                Section {
                    NavigationLink(destination: CameraView(id: generateId())){
                        HStack {
                            Image(systemName: "camera").bold().imageScale(.large).foregroundStyle(Color.blue)
                            VStack(alignment: .leading) {
                                Text("カメラを起動して撮影").foregroundStyle(Color.primary).font(.title3).bold().padding(.vertical, 4)
                                Text("新しい動画を撮影します。").foregroundStyle(Color.secondary)
                            }.padding(.leading, 3)
                        }
                    }
                }
            }
            // 動画一覧
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
                if (filterMode != .sceneOnly) {
                    Button("空の撮影動画を追加 (デバッグ用)") {
                        addEmpty(isScene: false)
                    }
                }
                if (filterMode != .recordedOnly) {
                    Button("空の行動シーンを追加 (デバッグ用)") {
                        addEmpty(isScene: true)
                    }
                }
                #endif
                Button("すべての動画を削除", role: .destructive){
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
        // ツールバー
        .toolbar{
            // 右上に設定ボタンを表示
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showAppSettingsView = true
                } label: {
                    Image(systemName: "gearshape")
                    Text("設定")
                }
            }
            // タイトル部分をメニューボタンにする
            ToolbarTitleMenu {
                if (parentId == nil) {
                    Button("すべて") {
                        filterMode = .all
                    }
                    Button("撮影履歴") {
                        filterMode = .recordedOnly
                    }
                }
                Button("シーン一覧") {
                    filterMode = .sceneOnly
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
        .navigationTitle(viewTitle)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // 空データの追加 (デバッグ用)
    #if DEBUG
    private func addEmpty(isScene: Bool) {
        let video: Video = .init(id: generateId())
        video.title = self.format.string(from: video.recordedStart)
        video.isScene = isScene
        video.parentId = self.parentId
        self.context.insert(video)
    }
    #endif
    
    // 重複しないUUIDの生成
    private func generateId() -> UUID {
        let id: UUID = .init()
        return videos.contains{ $0.id == id } ? generateId() : id
    }

    // 動画の削除
    private func delete() {
        // 動画ファイルの削除
        self.showDeleteFilesFailedAlert =  !FileHelper.deleteFiles(urls: [self.deletingVideo!.fileUrl])
        // レコードの削除
        self.context.delete(self.deletingVideo!)
        // 削除指定を解除
        self.deletingVideo = nil
    }
    
    // 動画の全削除
    private func deleteAll() {
        // 動画ファイルの削除
        if (self.filterMode == .all) {
            self.showDeleteFilesFailedAlert =  !FileHelper.deleteAllFiles()
        } else {
            let urls: [URL] = self.filteredVideos.map{ $0.fileUrl }
            self.showDeleteConfirmAlert = !FileHelper.deleteFiles(urls: urls)
        }
        
        // レコードの削除
        for video in self.filteredVideos {
            self.context.delete(video)
        }
    }
}

#Preview {
    NavigationStack{
        VideoListView().modelContainer(for: [Video.self])
    }
}
