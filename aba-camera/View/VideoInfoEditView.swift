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
    @Binding var title: String
    @Binding var memo: String
    
    init(video: Video, title: Binding<String>, memo: Binding<String>) {
        self.video = video
        self._title = title
        self._memo = memo
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
                    self.title = video.title
                    self.memo = video.memo
                    dismiss()
                } label: {
                    Text("キャンセル")
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    video.title = self.title
                    video.memo = self.memo
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
        VideoInfoEditView(video: .init(), title: .constant(""), memo: .constant(""))
    }
}
