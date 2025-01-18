//
//  VideoInfoEditView.swift
//  aba-camera
//
//  Created by shiolab_asakura on 2025/01/18.
//

import SwiftUI

struct VideoInfoEditView: View {
    
    @Environment(\.dismiss) var dismiss
    @Binding var title: String
    @Binding var memo: String
    
    private let current: VideoInfoProtocol
    
    init(current: VideoInfoProtocol, title: Binding<String>, memo: Binding<String>) {
        self.current = current
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
                    self.title = current.title
                    self.memo = current.memo
                    dismiss()
                } label: {
                    Text("キャンセル")
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
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
        VideoInfoEditView(current: RecordedVideo(), title: .constant(""), memo: .constant(""))
    }
}
