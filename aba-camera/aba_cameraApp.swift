//
//  aba_cameraApp.swift
//  aba-camera
//
//  Created by shiolab_asakura on 2025/01/13.
//

import SwiftUI
import SwiftData
import UIKit

@main
struct aba_cameraApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            MainView()
                .modelContainer(for: [RecordedVideo.self, SceneVideo.self])
        }
    }
}
