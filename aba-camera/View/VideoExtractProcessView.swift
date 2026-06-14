//
//  VideoExtractProcessView.swift
//  aba-camera
//
//  Created by Taichi Asakura on 2025/01/22.
//

import SwiftUI
import SwiftData

struct VideoExtractProcessView: View {
    private let parent: Video
    private let autoExtract: Bool
    
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) var dismiss
    @AppStorage("apiUrl") var apiUrl: String = ""
    @AppStorage("beforeSeconds") var before: Int = 20
    @AppStorage("afterSeconds") var after: Int = 60
    @Binding var extractPoints: [ExtractPoint]
    @Query private var videos: [Video]
    @State private var progress: Int
    @State private var task: Task<Void, Never>?
    @State private var showSuccessAlert: Bool
    @State private var showFailedAlert: Bool
    @State private var showNoPointAlert: Bool
    @State private var showCancelAlert: Bool
    @State private var showFetchFailedAlert: Bool
    
    private var cancelled: Bool {
        return self.task?.isCancelled ?? false
    }
    
    private var success: Int {
        return self.extractPoints.count{ $0.status == .success }
    }
    
    private var failed: Int {
        return self.extractPoints.count{ $0.status == .failed }
    }
    
    private var total: Int {
        return self.extractPoints.count
    }
    
    private var progressText: String {
        return String(progress) + " / " + String(total)
    }
    
    private var successText: String {
        return "成功: " + String(success)
    }
    
    private var failedText: String {
        return "失敗: " + String(failed)
    }
    
    init(parent: Video, extractPoints: Binding<[ExtractPoint]>, autoExtract: Bool = false) {
        self.parent = parent
        self.autoExtract = autoExtract
        self._extractPoints = extractPoints
        self.progress = 0
        self.task = nil
        self.showSuccessAlert = false
        self.showFailedAlert = false
        self.showNoPointAlert = false
        self.showCancelAlert = false
        self.showFetchFailedAlert = false
    }
    
    var body: some View {
        VStack{
            Text("動画を抽出しています").font(.title3).padding(.vertical,12)
            Text(progressText).font(.title3).padding(.vertical,12)
            ProgressView(value: Double(progress), total: Double(total)).padding(.all,12)
            HStack{
                Text(successText)
                Text(failedText)
            }.padding(.bottom,12)
            Button("キャンセル") {
                task?.cancel()
            }.font(.title3).bold().padding(.vertical,12).disabled(cancelled)
        }
        .onAppear{
            task = Task{
                await doProcess()
            }
        }
        // 抽出が成功した時
        .alert("抽出に成功しました。", isPresented: $showSuccessAlert) {
            Button("OK") {
                dismiss()
            }
        }
        // 抽出が失敗した時
        .alert("抽出に失敗しました。", isPresented: $showFailedAlert) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text(failedText)
        }
        // 抽出ポイントが0件だった時
        .alert("抽出箇所がありませんでした。", isPresented: $showNoPointAlert) {
            Button("OK") {
                dismiss()
            }
        }
        // 抽出をキャンセルした時
        .alert("抽出をキャンセルしました。", isPresented: $showCancelAlert) {
            Button("OK") {
                dismiss()
            }
        }
        // Webからのデータ取得失敗時
        .alert("Webからのデータ取得に失敗しました。", isPresented: $showFetchFailedAlert) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("後から手動でシーン動画を抽出してください。")
        }
    }
    
    // 処理の実行
    private func doProcess() async {
        // 以前の実行結果のリセット
        resetStatus()
        
        // 自動抽出の場合: Webシステムからデータ取得
        if (self.autoExtract) {
            if (!self.cancelled) {
                await fetch(subjective: true)
            }
            
            if (!self.cancelled) {
                await fetch(subjective: false)
            }
        }
        
        // 動画の抽出
        while (!self.cancelled && self.progress < self.total) {
            let extractPoint: ExtractPoint = self.extractPoints[self.progress]
            let id: UUID = generateId()
            // 正常に抽出できた場合のみレコード追加
            let result: Video? = await self.parent.extract(id: id, extractPoint: extractPoint, before: self.before, after: self.after)
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
            }
            // 結果の反映
            updateStatus(isSuccess: result != nil)
            // 進捗状況の更新
            self.progress += 1
        }
        
        // アラート表示
        if (self.cancelled) {
            self.showCancelAlert = !self.showFetchFailedAlert
        } else if (self.failed > 0) {
            self.showFailedAlert = true
        } else if (self.total == 0) {
            self.showNoPointAlert = true
        } else {
            self.showSuccessAlert = true
        }
    }
    
    // 以前の実行結果のリセット
    private func resetStatus() {
        for index in 0 ..< self.total {
            self.extractPoints[index].status = .none
        }
    }
    
    // Webシステムからのデータ取得
    private func fetch(subjective: Bool) async {
        let extractPoints: [ExtractPoint]? = await ExtractPoint.fetch(apiUrl: self.apiUrl, subjective: subjective, start: self.parent.recordedStart, end: self.parent.recordedEnd)
        
        if let extractPoints = extractPoints {
            self.extractPoints += extractPoints
        } else {
            task?.cancel()
            showFetchFailedAlert = true
        }
    }
    
    // 結果の反映
    private func updateStatus(isSuccess: Bool) {
        self.extractPoints[self.progress].status = isSuccess ? .success : .failed
    }
    
    // 重複しないUUIDの生成
    private func generateId() -> UUID {
        let id: UUID = .init()
        return videos.contains{ $0.id == id } ? generateId() : id
    }
}

#Preview {
    NavigationStack{
        VideoExtractProcessView(parent: .init(), extractPoints: .constant([]))
            .modelContainer(for: [Video.self])
    }
}
