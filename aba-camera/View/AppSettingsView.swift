//
//  CameraView.swift
//  aba-camera
//
//  Created by shiolab_asakura on 2025/01/13.
//

import SwiftUI

struct AppSettingsView: View {
    
    @Environment(\.dismiss) var dismiss
    @AppStorage("endpointUrl") var endpointUrl: String = ""
    @AppStorage("videoHighQuality") var videoHighQuality: Bool = false
    @AppStorage("beforeSeconds") var beforeSeconds: Int = 20
    @AppStorage("afterSeconds") var afterSeconds: Int = 60
    @State private var showDeleteConfirmAlert: Bool
    @State private var showDeleteFilesSuccessAlert: Bool
    @State private var showDeleteFilesFailedAlert : Bool
    
    init() {
        showDeleteConfirmAlert = false
        showDeleteFilesSuccessAlert = false
        showDeleteFilesFailedAlert = false
    }
    
    var body: some View {
        Form{
            Section (header: Text("エンドポイントURL").font(.body), footer: Text("心拍データ取得システム (Webシステム) に登録したデバイスの「接続先URL」(履歴取得用) を入力します。").font(.body)) {
                TextField("URLを入力", text: $endpointUrl)
                    .textInputAutocapitalization(.never)
                    //.disableAutocorrection(true)
                    .keyboardType(.URL)
            }
            Section (header: Text("撮影設定").font(.body)) {
                Toggle("高画質撮影", isOn: $videoHighQuality)
            }
            Section (header: Text("ポイント前後の抽出時間 (秒数)").font(.body)) {
                HStack {
                    Text("前: ").foregroundStyle(Color.secondary)
                    TextField("秒数を入力", value: $beforeSeconds, format: .number)
                        .keyboardType(.numberPad)
                }
                HStack {
                    Text("後: ").foregroundStyle(Color.secondary)
                    TextField("秒数を入力", value: $afterSeconds, format: .number)
                        .keyboardType(.numberPad)
                }
            }
            Section (header: Text("ストレージ").font(.body)) {
                Button("すべての一時ファイルを削除", role: .destructive){
                    showDeleteConfirmAlert = true
                }
            }
        }
        // 一時ファイル削除前の確認アラート
        .alert("すべての一時ファイルを削除しますか?", isPresented: $showDeleteConfirmAlert) {
            Button("キャンセル", role: .cancel) {}
            Button("全削除", role: .destructive){
                showDeleteFilesSuccessAlert =  FileHelper.deleteTemporaryFiles()
                showDeleteFilesFailedAlert = !showDeleteFilesSuccessAlert
            }
        }
        // 一時ファイル削除成功時のアラート
        .alert("すべての一時ファイルを削除しました。", isPresented: $showDeleteFilesSuccessAlert) {}
        // 一時ファイル削除失敗時のアラート
        .alert("一部またはすべての一時ファイルを削除できませんでした。", isPresented: $showDeleteFilesFailedAlert) {}
        // ツールバーに完了ボタンを設置
        .toolbar{
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    dismiss()
                } label: {
                    Text("完了").bold()
                }
            }
        }
        .navigationBarBackButtonHidden()
        .navigationTitle("設定")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    
}

#Preview {
    NavigationStack{
        AppSettingsView()
    }
}
