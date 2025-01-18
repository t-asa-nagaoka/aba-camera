//
//  RecordedVideo.swift
//  aba-camera
//
//  Created by shiolab_asakura on 2025/01/15.
//

import Foundation
import SwiftData
import AVFoundation

@Model
class RecordedVideo : VideoProtocol, VideoInfoProtocol {
    @Attribute(.unique)
    var id: UUID
    var recordedStart: Date
    var recordedEnd: Date
    var fileType: String
    @Transient
    var videoUrl: URL {
        get {
            let dir: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let fileName: String = "recorded-" + id.uuidString + "." + fileType
            return dir.appendingPathComponent(fileName)
        }
    }
    var title: String
    var memo: String
    @Relationship(deleteRule: .cascade, inverse: \SceneVideo.parent)
    var sceneVideos: [SceneVideo]
    
    init() {
        let date: Date = .init()
        
        self.id = .init()
        self.recordedStart = date
        self.recordedEnd = date
        self.fileType = "mp4"
        self.title = ""
        self.memo = ""
        self.sceneVideos = []
    }
    
    func importSource (source: URL) async -> Bool {
        // 動画ソースをアプリのDocumentフォルダにコピー
        let dir: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileType: String = source.pathExtension
        let fileName: String = "recorded-" + id.uuidString + "." + fileType
        let url: URL = dir.appendingPathComponent(fileName)
        
        do {
            try FileManager.default.copyItem(at: source, to: url)
        } catch {
            print("-- RecordedVideo.importSource : File Copy Error --")
            print("source: " + source.path)
            print("copyTo: " + url.path)
            print(error)
            return false
        }
        
        // コピーしたファイルをiCloudバックアップから除外
        _ = FileHelper.setAsExcludedBackup(url: url)
        
        // 動画データから必要なプロパティを取得
        let videoAsset: AVURLAsset = .init(url: source)
        let (creationDate, duration) = try! await videoAsset.load(.creationDate, .duration)
        
        // 録画開始時刻を取得
        let creationDateValue: Date? = try! await creationDate!.load(.dateValue)
        let recordedStart: Date = creationDateValue!
        
        // 録画時間を算出
        let durationTime = TimeInterval(round(Float(duration.value) / Float(duration.timescale)))
        
        // 録画終了時刻を算出
        let recordedEnd: Date = recordedStart + durationTime
        
        // ソースファイルの削除
        _ = FileHelper.deleteFiles(urls: [source])
        
        // レコードとして保存する情報を更新
        self.recordedStart = recordedStart
        self.recordedEnd = recordedEnd
        self.fileType = fileType
        
        return true
    }
    
    func deleteSource() -> Bool {
        var urls: [URL] = self.sceneVideos.map { $0.videoUrl }
        urls.append(videoUrl)
        return FileHelper.deleteFiles(urls: urls)
    }
}
