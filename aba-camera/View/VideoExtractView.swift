//
//  VideoExtractView.swift
//  aba-camera
//
//  Created by Taichi Asakura on 2025/01/21.
//

import SwiftUI

struct VideoExtractView: View {
    private let video: Video
    
    @AppStorage("endpointUrl") var endpointUrl: String = ""
    @AppStorage("beforeSeconds") var beforeSeconds: Int = 20
    @AppStorage("afterSeconds") var afterSeconds: Int = 60
    @State private var switchHistories: [SwitchHistory]
    @State private var id: Int
    @State private var date: Date
    @State private var second: Int
    @State private var subjective: Bool
    
    private let format: DateFormatter
    
    private var url: URL? {
        return .init(string: self.endpointUrl)
    }
    
    init(video: Video) {
        self.video = video
        self.switchHistories = []
        self.id = 1
        self.date = video.recordedStart
        self.second = Calendar.current.component(.second, from: video.recordedStart)
        self.subjective = false
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
            if (url != nil){
                Section (header: Text("心拍スイッチ連携").font(.body)) {
                    Button {
                        
                    } label: {
                        Label("Webから心拍スイッチ履歴を取得", systemImage: "globe")
                    }
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
                }
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
                    Text(String(beforeSeconds))
                    Text("秒前")
                    Text("から")
                    Text(String(afterSeconds))
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
        // ツールバーに抽出ボタンを設置
        .toolbar{
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    
                } label: {
                    Image(systemName: "movieclapper")
                    Text("抽出")
                }
                .disabled(switchHistories.count == 0)
            }
        }
        .navigationTitle("行動シーンの抽出")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func add() {
        let date: Date =  Calendar.current.date(bySetting: .second, value: self.second, of: self.date)!
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
