//
//  VideoExtractView.swift
//  aba-camera
//
//  Created by Taichi Asakura on 2025/01/21.
//

import SwiftUI

struct VideoExtractView: View {
    private let video: Video
    
    @AppStorage("apiUrl") var apiUrl: String = ""
    @AppStorage("beforeSeconds") var before: Int = 20
    @AppStorage("afterSeconds") var after: Int = 60
    @State private var extractPoints: [ExtractPoint]
    @State private var id: Int
    @State private var date: Date
    @State private var second: Int
    @State private var fetching: Bool
    @State private var showFetchFailedAlert: Bool
    @State private var showVideoExtractProcessView: Bool
    
    private let format: DateFormatter
    
    private var canFetch: Bool {
        return URL(string: self.apiUrl) != nil
    }
    
    init(video: Video) {
        self.video = video
        self.extractPoints = []
        self.id = 1
        self.date = video.recordedStart
        self.second = Calendar.current.component(.second, from: video.recordedStart)
        self.fetching = false
        self.showFetchFailedAlert = false
        self.showVideoExtractProcessView = false
        self.format = .init()
        self.format.dateFormat = "yyyy/MM/dd HH:mm:ss"
        
        // うるう秒処理
        if (self.second == 60) {
            self.second = 59
        }
    }
    
    var body: some View {
        // 描画するViewのレイアウト
        Form {
            // 自動
            if (canFetch){
                Section (header: Text("Webシステム連携").font(.body)) {
                    Button {
                        Task {
                            await fetch(subjective: true)
                        }
                    } label: {
                        Label("アイコンデータ (主観記録) を取得", systemImage: "globe")
                    }.disabled(fetching)
                    Button {
                        Task {
                            await fetch(subjective: false)
                        }
                    } label: {
                        Label("IoTスイッチ履歴 (客観記録) を取得", systemImage: "globe")
                    }.disabled(fetching)
                }
            }
            // 手動
            Section (header: Text("手動入力").font(.body)) {
                DatePicker("日時", selection: $date,  displayedComponents: [.date, .hourAndMinute])
                Picker(selection: $second, label: Text("秒")) {
                    ForEach(0..<60) { index in
                        Text(String(format: "%02d", index))
                    }
                }
                Button {
                    add()
                } label: {
                    Label("抽出ポイントを追加", systemImage: "plus")
                }.disabled(fetching)
            }
            // 元の動画の情報
            Section (header: Text("元の動画").font(.body)) {
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
            // 抽出条件
            Section (header: Text("抽出条件").font(.body)) {
                HStack {
                    Text("検出")
                    Text(String(before))
                    Text("秒前")
                    Text("から")
                    Text(String(after))
                    Text("秒後")
                }
            }
            // 抽出ポイントの一覧
            if (extractPoints.count > 0) {
                Section (header: Text("抽出ポイント").font(.body)) {
                    ForEach(extractPoints, id: \.id) { extractPoint in
                        VStack(alignment: .leading) {
                            Text(format.string(from:extractPoint.happend))
                            if (extractPoint.subjective != nil) {
                                Text(extractPoint.subjective! ? "アイコンデータ (主観)" : "IoTスイッチ (客観)").foregroundStyle(Color.secondary)
                            } else {
                                Text("手動入力").foregroundStyle(Color.secondary)
                            }
                            if (extractPoint.status == .success) {
                                Text("抽出成功").foregroundStyle(Color.blue).bold()
                            } else if (extractPoint.status == .failed) {
                                Text("抽出失敗").foregroundStyle(Color.red).bold()
                            }
                        }.swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                delete(id: extractPoint.id)
                            } label: {
                                Image(systemName: "trash.fill")
                            }
                        }
                    }
                }
            }
            // 抽出ポイントの一覧
            Section {
                Button(role: .destructive){
                    deleteAll()
                } label: {
                    Label("すべてのポイントを削除", systemImage: "trash").foregroundStyle(Color.red)
                }
            }
        }
        // Webからのデータ取得失敗時
        .alert("データの取得に失敗しました。", isPresented: $showFetchFailedAlert) {}
        // ツールバーに抽出ボタンを設置
        .toolbar{
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showVideoExtractProcessView = true
                } label: {
                    Image(systemName: "movieclapper")
                    Text("抽出")
                }
                .disabled(extractPoints.count == 0)
            }
        }
        // 抽出処理画面への遷移
        .fullScreenCover(isPresented: $showVideoExtractProcessView) {
            VideoExtractProcessView(parent: video, extractPoints: $extractPoints)
        }
        .navigationTitle("シーン動画の抽出")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func fetch(subjective: Bool) async {
        self.fetching = true
        
        let extractPoints: [ExtractPoint]? = await ExtractPoint.fetch(apiUrl: self.apiUrl, subjective: subjective, start: self.video.recordedStart, end: self.video.recordedEnd)
        
        if let extractPoints = extractPoints {
            for extractPoint in extractPoints {
                self.extractPoints.append(.init(id: self.id, extractPoint: extractPoint))
                self.id += 1
            }
        } else {
            self.showFetchFailedAlert = true
        }
        
        self.fetching = false
    }
    
    private func add() {
        let secDiff: Int = self.second - Calendar.current.component(.second, from: self.date)
        let date: Date =  Calendar.current.date(byAdding: .second, value: secDiff, to: self.date)!
        let extractPoint: ExtractPoint = .init(id: self.id, happend: date, subjective: nil)
        self.extractPoints.append(extractPoint)
        self.id += 1
    }
    
    private func delete(id: Int) {
        self.extractPoints.removeAll{ $0.id == id }
    }
    
    private func deleteAll() {
        self.extractPoints.removeAll()
    }
}

#Preview {
    NavigationStack{
        VideoExtractView(video: .init())
    }
}
