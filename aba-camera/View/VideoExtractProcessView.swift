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
    
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) var dismiss
    @AppStorage("beforeSeconds") var before: Int = 20
    @AppStorage("afterSeconds") var after: Int = 60
    @Binding var switchHistories: [SwitchHistory]
    @Query private var videos: [Video]
    @State private var progress: Int
    @State private var cancelled: Bool
    
    private var success: Int {
        return self.switchHistories.count{ $0.status == .success }
    }
    
    private var failed: Int {
        return self.switchHistories.count{ $0.status == .failed }
    }
    
    private var total: Int {
        return self.switchHistories.count
    }
    
    init(parent: Video, switchHistories: Binding<[SwitchHistory]>) {
        self.parent = parent
        self._switchHistories = switchHistories
        self.progress = 0
        self.cancelled = false
    }
    
    var body: some View {
        VStack{
            Text("動画を抽出しています").font(.title3).padding(.vertical,12)
            Text(String(progress) + " / " + String(total)).font(.title3).padding(.vertical,12)
            ProgressView(value: Double(progress), total: Double(total)).padding(.all,12)
            HStack{
                Text("成功: " + String(success))
                Text("失敗: " + String(failed))
            }.padding(.bottom,12)
            Button("キャンセル") {
                cancelled = true
            }.font(.title3).bold().padding(.vertical,12).disabled(cancelled)
        }
        .onAppear{
            Task{
                await doProcess()
                dismiss()
            }
        }
    }
    
    // 処理の実行
    private func doProcess() async {
        // 以前の実行結果のリセット
        resetStatus()
        
        // 動画の抽出
        while (!self.cancelled && self.progress < self.total) {
            let switchHistory: SwitchHistory = self.switchHistories[self.progress]
            let id: UUID = generateId()
            // 正常に抽出できた場合のみレコード追加
            let result: Video? = await self.parent.extract(id: id, switchHistory: switchHistory, before: self.before, after: self.after)
            if let video = result {
                // タイトルを元の動画と同一にする
                video.title = self.parent.title
                
                // レコード追加
                self.context.insert(video)
                try! self.context.save()
            }
            // 結果の反映
            updateStatus(isSuccess: result != nil)
            // 進捗状況の更新
            self.progress += 1
        }
    }
    
    // 以前の実行結果のリセット
    private func resetStatus() {
        for index in 0 ..< self.total {
            self.switchHistories[index].status = .none
        }
    }
    
    // 結果の反映
    private func updateStatus(isSuccess: Bool) {
        self.switchHistories[self.progress].status = isSuccess ? .success : .failed
    }
    
    // 重複しないUUIDの生成
    private func generateId() -> UUID {
        let id: UUID = .init()
        return videos.contains{ $0.id == id } ? generateId() : id
    }
    
}

#Preview {
    NavigationStack{
        VideoExtractProcessView(parent: .init(), switchHistories: .constant([]))
            .modelContainer(for: [Video.self])
    }
}
