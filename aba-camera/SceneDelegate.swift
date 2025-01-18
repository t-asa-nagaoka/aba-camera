//
//  SceneDelegate.swift
//  aba-camera
//
//  Created by shiolab_asakura on 2025/01/15.
//

// 画面回転制御用: https://dev.classmethod.jp/articles/swiftui-update-rotation-ios16/
import SwiftUI
import UIKit

class SceneDelegate: NSObject, ObservableObject, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        self.window = windowScene.keyWindow
    }
}
