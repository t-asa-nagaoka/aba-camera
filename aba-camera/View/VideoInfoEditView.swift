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
    @State private var titleInput: String
    @State private var memoInput: String
    @Binding var edited: Bool
    
    init(video: Video, edited: Binding<Bool>) {
        self.video = video
        self.titleInput = video.title
        self.memoInput = video.memo
        self._edited = edited
    }
    
    var body: some View {
        Form {
            Section (header: Text("タイトル").font(.body)) {
                TextField("タイトルを入力", text:$titleInput)
                    .textInputAutocapitalization(.never)
                    .font(.title3)
                    .bold()
            }
            Section (header: Text("メモ").font(.body)) {
                TextEditor(text:$memoInput)
                    .textInputAutocapitalization(.never)
            }
        }
        // ツールバーにボタンを設置
        .toolbar{
            if #available(iOS 26.0, *) {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(role: .close) {
                        dismiss()
                    } label: {
                        Text("キャンセル")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(role: .confirm) {
                        // 変更を反映
                        video.title = self.titleInput
                        video.memo = self.memoInput
                        self.edited = true
                        
                        // ファイル名をタイトルに合わせる
                        _ = video.rename(fileName: video.title)
                        
                        dismiss()
                    } label: {
                        Image(systemName: "checkmark")
                        Text("完了").bold()
                    }
                }
            } else {
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
                        video.title = self.titleInput
                        video.memo = self.memoInput
                        self.edited = true
                        
                        // ファイル名をタイトルに合わせる
                        _ = video.rename(fileName: video.title)
                        
                        dismiss()
                    } label: {
                        Image(systemName: "checkmark")
                        Text("完了").bold()
                    }
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
