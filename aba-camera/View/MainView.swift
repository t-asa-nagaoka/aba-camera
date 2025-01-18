//
//  ContentView.swift
//  aba-camera
//
//  Created by shiolab_asakura on 2025/01/13.
//

import SwiftUI
import SwiftData

struct MainView: View {
    
    var body: some View {
        NavigationStack{
            RecordedVideoListView()
        }.onAppear{
            // アプリ起動時にすべての一時ファイルを削除
            _ = FileHelper.deleteTemporaryFiles()
        }
    }
}

#Preview {
    MainView()
        .modelContainer(for: [RecordedVideo.self, SceneVideo.self])
}
