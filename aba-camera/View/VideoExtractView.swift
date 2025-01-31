//
//  VideoExtractView.swift
//  aba-camera
//
//  Created by Taichi Asakura on 2025/01/21.
//

import SwiftUI

struct VideoExtractView: View {
    private let video: Video
    
    @AppStorage("endpointUrl") var url: String = ""
    @AppStorage("beforeSeconds") var before: Int = 20
    @AppStorage("afterSeconds") var after: Int = 60
    @State private var switchHistories: [SwitchHistory]
    @State private var id: Int
    @State private var date: Date
    @State private var second: Int
    @State private var subjective: Bool
    @State private var fetching: Bool
    @State private var showFetchFailedAlert: Bool
    @State private var showVideoExtractProcessView: Bool
    
    private let format: DateFormatter
    
    private var canFetch: Bool {
        return URL(string: self.url) != nil
    }
    
    init(video: Video) {
        self.video = video
        self.switchHistories = []
        self.id = 1
        self.date = video.recordedStart
        self.second = Calendar.current.component(.second, from: video.recordedStart)
        self.subjective = false
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
                Section (header: Text("心拍スイッチ連携").font(.body)) {
                    Button {
                        Task {
                            await fetch()
                        }
                    } label: {
                        Label("Webから心拍スイッチ履歴を取得", systemImage: "globe")
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
                Toggle("主観スイッチ", isOn: $subjective)
                Button {
                    add()
                } label: {
                    Label("心拍スイッチ履歴を追加", systemImage: "plus")
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
                    Text("作動")
                    Text(String(before))
                    Text("秒前")
                    Text("から")
                    Text(String(after))
                    Text("秒後")
                }
            }
            // 抽出ポイントの一覧
            if (switchHistories.count > 0) {
                Section (header: Text("心拍スイッチ履歴 (抽出ポイント)").font(.body)) {
                    ForEach(switchHistories, id: \.id) { switchHistory in
                        VStack(alignment: .leading) {
                            Text(format.string(from:switchHistory.happend))
                            Text(switchHistory.subjective ? "主観スイッチ" : "心拍 (客観) スイッチ").foregroundStyle(Color.secondary)
                            if (switchHistory.status == .success) {
                                Text("抽出成功").foregroundStyle(Color.blue).bold()
                            } else if (switchHistory.status == .failed) {
                                Text("抽出失敗").foregroundStyle(Color.red).bold()
                            }
                        }.swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                delete(id: switchHistory.id)
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
                    Label("すべての履歴を削除", systemImage: "trash").foregroundStyle(Color.red)
                }
            }
        }
        // Webからの履歴取得失敗時
        .alert("履歴の取得に失敗しました。", isPresented: $showFetchFailedAlert) {}
        // ツールバーに抽出ボタンを設置
        .toolbar{
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showVideoExtractProcessView = true
                } label: {
                    Image(systemName: "movieclapper")
                    Text("抽出")
                }
                .disabled(switchHistories.count == 0)
            }
        }
        // 抽出処理画面への遷移
        .fullScreenCover(isPresented: $showVideoExtractProcessView) {
            VideoExtractProcessView(parent: video, switchHistories: $switchHistories)
        }
        .navigationTitle("行動シーンの抽出")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func fetch() async {
        self.fetching = true
        
        let switchHistories: [SwitchHistory]? = await  SwitchHistory.fetch(url: self.url, start: self.video.recordedStart, end: self.video.recordedEnd)
        
        if let switchHistories = switchHistories {
            for switchHistory in switchHistories {
                self.switchHistories.append(.init(id: self.id, switchHistory: switchHistory))
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
        let switchHistory: SwitchHistory = .init(id: self.id, happend: date, subjective: self.subjective)
        self.switchHistories.append(switchHistory)
        self.id += 1
    }
    
    private func delete(id: Int) {
        self.switchHistories.removeAll{ $0.id == id }
    }
    
    private func deleteAll() {
        self.switchHistories.removeAll()
    }
}

#Preview {
    NavigationStack{
        VideoExtractView(video: .init())
    }
}
