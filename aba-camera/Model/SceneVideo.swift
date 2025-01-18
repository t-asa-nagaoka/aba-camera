//
//  SceneVideo.swift
//  aba-camera
//
//  Created by shiolab_asakura on 2025/01/15.
//


import Foundation
import SwiftData
import AVFoundation

@Model
class SceneVideo : VideoProtocol, VideoInfoProtocol, ExtractPointProtocol {
    @Attribute(.unique)
    var id: UUID
    var recordedStart: Date
    var recordedEnd: Date
    var fileType: String
    @Transient
    var videoUrl: URL {
        get {
            let dir: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let fileName: String = "scene-" + id.uuidString + "." + fileType
            return dir.appendingPathComponent(fileName)
        }
    }
    var title: String
    var memo: String
    var happendDate: Date
    var subjective: Bool
    var extractedDate: Date
    var parent: RecordedVideo?
    
    init() {
        let date: Date = .init()
        
        self.id = .init()
        self.recordedStart = date
        self.recordedEnd = date
        // fileTypeはバージョンアップ時に出力形式が変わっても過去の動画が閲覧できるよう敢えて変数としている
        self.fileType = "mp4"
        self.title = ""
        self.memo = ""
        self.happendDate = date
        self.subjective = false
        self.extractedDate = date
        self.parent = nil
    }
    
    func extract(parent: RecordedVideo, extractPoint: ExtractPointProtocol, before: Int, after: Int) async -> Bool {
        // 抽出開始・終了点の日時を算出
        let recordedStart: Date = SceneVideo.calcRecordedStart(parent: parent, extractPoint:extractPoint, before: before)
        let recordedEnd: Date = SceneVideo.calcRecordedEnd(parent: parent, extractPoint:extractPoint, after: after)
        
        // 抽出開始・終了点の動画開始時点からの秒数を取得
        let start: TimeInterval = recordedStart.timeIntervalSince(parent.recordedStart)
        let end: TimeInterval = recordedEnd.timeIntervalSince(parent.recordedStart)
        
        // 抽出後の再生時間が1秒未満なら中止
        let length: Double = end - start
        if (length < 1) {
            print("-- SceneVideo.extract : Date Validation Failed --")
            
            let format: DateFormatter = .init()
            format.dateFormat = "yyyy/MM/dd HH:mm:ss"
            
            print("recordedStart: " + format.string(from: recordedStart))
            print("recordedEnd: " + format.string(from: recordedEnd))
            print("length: " + String(length))
            
            return false
        }
        
        // 元動画のデータから動画・音声トラック・タイムスケールを取得
        let sourceAsset: AVURLAsset = .init(url: parent.videoUrl)
        let srcVideoTracks: [AVAssetTrack] = try! await sourceAsset.loadTracks(withMediaType: .video)
        let srcAudioTracks: [AVAssetTrack] = try! await sourceAsset.loadTracks(withMediaType: .audio)
        let srcVideoTrack: AVAssetTrack = srcVideoTracks[0]
        let srcAudioTrack: AVAssetTrack = srcAudioTracks[0]
        let timeScale: CMTimeScale = try! await srcVideoTrack.load(.naturalTimeScale)
        
        // 出力用のCompositionおよび動画・音声トラックを生成
        let composition = AVMutableComposition()
        guard let videoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else {
            print("-- SceneVideo.extract : Create Video Track Error --")
            return false
        }
        guard let audioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) else {
            print("-- SceneVideo.extract : Create Audio Track Error --")
            return false
        }
        
        // 元動画のトラックから抽出した部分を出力トラックに挿入
        let timeRange: CMTimeRange = .init(start: CMTime(seconds: start, preferredTimescale: timeScale), end: CMTime(seconds: end, preferredTimescale: timeScale))
        try! videoTrack.insertTimeRange(timeRange, of: srcVideoTrack, at: .zero)
        try! audioTrack.insertTimeRange(timeRange, of: srcAudioTrack, at: .zero)
        
        // シーン動画の出力
        guard let session = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) else {
            print("-- SceneVideo.extract : Create Export Session Error --")
            return false
        }
        
        do {
            try await session.export(to: self.videoUrl, as: .mp4)
        } catch {
            print("-- SceneVideo.extract : Export Error --")
            print(error)
            return false
        }
        
        // 出力したファイルをiCloudバックアップから除外
        _ = FileHelper.setAsExcludedBackup(url: self.videoUrl)
        
        // レコードとして保存する情報を更新
        self.recordedStart = recordedStart
        self.recordedEnd = recordedEnd
        self.happendDate = extractPoint.happendDate
        self.subjective = extractPoint.subjective
        self.extractedDate = .init()
        self.parent = parent
        
        return true
    }
    
    static private func calcRecordedStart(parent: RecordedVideo, extractPoint: ExtractPointProtocol, before: Int) -> Date {
        let recordedStart: Date = Calendar.current.date(byAdding:.second, value: before > 0 ? -before : -1, to:extractPoint.happendDate)!
        return recordedStart >= parent.recordedStart ? recordedStart : parent.recordedStart
    }
    
    static private func calcRecordedEnd(parent: RecordedVideo, extractPoint: ExtractPointProtocol, after: Int) -> Date {
        let recordedEnd: Date = Calendar.current.date(byAdding:.second, value: after > 0 ? after : 1, to:extractPoint.happendDate)!
        return recordedEnd <= parent.recordedEnd ? recordedEnd : parent.recordedEnd
    }
    
    func deleteSource() -> Bool {
        return FileHelper.deleteFiles(urls: [videoUrl])
    }
}
