//
//  VideoInfoEditView.swift
//  aba-camera
//
//  Created by shiolab_asakura on 2025/01/18.
//

import SwiftUI

struct VideoInfoEditView: View {
    private let video: Video
    
    @Environment(\.dismiss) var dismiss
    @State private var title: String
    @State private var memo: String
    @Binding var edited: Bool
    
    init(video: Video, edited: Binding<Bool>) {
        self.video = video
        self.title = video.title
        self.memo = video.memo
        self._edited = edited
    }
    
    var body: some View {
        Form {
            Section (header: Text("タイトル").font(.body)) {
                TextField("タイトルを入力", text:$title)
                    .textInputAutocapitalization(.never)
                    .font(.title3)
                    .bold()
            }
            Section (header: Text("メモ").font(.body)) {
                TextEditor(text:$memo)
                    .textInputAutocapitalization(.never)
            }
        }
        // ツールバーに設定ボタンを設置
        .toolbar{
            ToolbarItem(placement: .navigationBarLeading) {
                Button(role: .cancel) {
                    dismiss()
                } label: {
                    Text("キャンセル")
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    // 変更を反映
                    video.title = self.title
                    video.memo = self.memo
                    self.edited = true
                    
                    // ファイル名をタイトルに合わせる
                    _ = video.rename(fileName: video.title)
                    
                    dismiss()
                } label: {
                    Text("完了").bold()
                }
            }
        }
        .navigationBarBackButtonHidden()
        .navigationTitle("情報の編集")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        VideoInfoEditView(video: .init(), edited: .constant(false))
    }
}
