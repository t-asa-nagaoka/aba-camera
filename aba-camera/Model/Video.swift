//
//  Video.swift
//  aba-camera
//
//  Created by shiolab_asakura on 2025/01/19.
//

import Foundation
import SwiftData
import AVFoundation

@Model
class Video : SwitchHistoryProtocol {
    @Attribute(.unique) var id: UUID
    
    var created: Date
    var recordedStart: Date
    var recordedEnd: Date
    var fileName: String
    var fileType: String
    var title: String
    var memo: String
    var isScene: Bool
    var parentId: UUID?
    var happend: Date
    var subjective: Bool
    
    @Transient var fileUrl: URL {
        if (self.fileName != "") {
            return Video.generateFileUrl(fileName: self.fileName, fileType: self.fileType)
        }
        
        return Video.generateFileUrl(id: self.id, fileType: self.fileType)
    }
    
    init() {
        let date: Date = .init()
        
        self.id = .init()
        self.created = date
        self.recordedStart = date
        self.recordedEnd = date
        self.fileName = ""
        self.fileType = "mp4"
        self.title = ""
        self.memo = ""
        self.isScene = false
        self.parentId = nil
        self.happend = date
        self.subjective = false
    }
    
    init(id: UUID) {
        let date: Date = .init()
        
        self.id = id
        self.created = date
        self.recordedStart = date
        self.recordedEnd = date
        self.fileName = ""
        self.fileType = "mp4"
        self.title = ""
        self.memo = ""
        self.isScene = false
        self.parentId = nil
        self.happend = date
        self.subjective = false
    }
    
    init(id: UUID, recordedStart: Date, recordedEnd: Date, fileType: String) {
        let date: Date = .init()
        
        self.id = id
        self.created = date
        self.recordedStart = recordedStart
        self.recordedEnd = recordedEnd
        self.fileName = ""
        self.fileType = fileType
        self.title = ""
        self.memo = ""
        self.isScene = false
        self.parentId = nil
        self.happend = date
        self.subjective = false
    }
    
    init(id: UUID, recordedStart: Date, recordedEnd: Date, fileType: String, parentId: UUID, switchHistory: SwitchHistoryProtocol) {
        self.id = id
        self.created = .init()
        self.recordedStart = recordedStart
        self.recordedEnd = recordedEnd
        self.fileName = ""
        self.fileType = fileType
        self.title = ""
        self.memo = ""
        self.isScene = true
        self.parentId = parentId
        self.happend = switchHistory.happend
        self.subjective = switchHistory.subjective
    }
    
    static func create(id: UUID, source: URL) async -> Video? {
        // 動画ソースをアプリのDocumentフォルダにコピー
        let fileType: String = source.pathExtension
        let url: URL = Video.generateFileUrl(id: id, fileType: fileType)
        
        do {
            try FileManager.default.copyItem(at: source, to: url)
        } catch {
            print("-- Video.create : File Copy Error --")
            print("source: " + source.path)
            print("copyTo: " + url.path)
            print(error)
            return nil
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
        
        // 新しい動画インスタンスを返す
        return .init(id:id, recordedStart: recordedStart, recordedEnd: recordedEnd, fileType: fileType)
    }
    
    func extract(id: UUID, switchHistory: SwitchHistoryProtocol, before: Int, after: Int) async -> Video? {
        // 抽出開始・終了点の日時を算出
        let recordedStart: Date = calcRecordedStart(switchHistory:switchHistory, before: before)
        let recordedEnd: Date = calcRecordedEnd(switchHistory:switchHistory, after: after)
        
        // 抽出開始・終了点の動画開始時点からの秒数を取得
        let start: TimeInterval = recordedStart.timeIntervalSince(self.recordedStart)
        let end: TimeInterval = recordedEnd.timeIntervalSince(self.recordedStart)
        
        // 抽出後の再生時間が1秒未満なら中止
        let length: Double = end - start
        if (length < 1) {
            print("-- Video.extract : Date Validation Failed --")
            
            let format: DateFormatter = .init()
            format.dateFormat = "yyyy/MM/dd HH:mm:ss"
            
            print("recordedStart: " + format.string(from: recordedStart))
            print("recordedEnd: " + format.string(from: recordedEnd))
            print("length: " + String(length))
            
            return nil
        }
        
        // 元動画のデータから動画・音声トラック・タイムスケールを取得
        let sourceAsset: AVURLAsset = .init(url: self.fileUrl)
        let srcVideoTracks: [AVAssetTrack] = try! await sourceAsset.loadTracks(withMediaType: .video)
        let srcAudioTracks: [AVAssetTrack] = try! await sourceAsset.loadTracks(withMediaType: .audio)
        let srcVideoTrack: AVAssetTrack = srcVideoTracks[0]
        let srcAudioTrack: AVAssetTrack = srcAudioTracks[0]
        let timeScale: CMTimeScale = try! await srcVideoTrack.load(.naturalTimeScale)
        
        // 出力用のCompositionおよび動画・音声トラックを生成
        let composition = AVMutableComposition()
        guard let videoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else {
            print("-- Video.extract : Create Video Track Error --")
            return nil
        }
        guard let audioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) else {
            print("-- Video.extract : Create Audio Track Error --")
            return nil
        }
        
        // 元動画のトラックから抽出した部分を出力トラックに挿入
        let timeRange: CMTimeRange = .init(start: CMTime(seconds: start, preferredTimescale: timeScale), end: CMTime(seconds: end, preferredTimescale: timeScale))
        try! videoTrack.insertTimeRange(timeRange, of: srcVideoTrack, at: .zero)
        try! audioTrack.insertTimeRange(timeRange, of: srcAudioTrack, at: .zero)
        
        // シーン動画の出力
        guard let session = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) else {
            print("-- Video.extract : Create Export Session Error --")
            return nil
        }
        
        let fileType: String = "mp4"
        let fileUrl: URL = Video.generateFileUrl(id: id, fileType: fileType)
        
        do {
            try await session.export(to: fileUrl, as: .mp4)
        } catch {
            print("-- Video.extract : Export Error --")
            print(error)
            return nil
        }
        
        // 出力したファイルをiCloudバックアップから除外
        _ = FileHelper.setAsExcludedBackup(url: fileUrl)
        
        // 新しい動画インスタンスを返す
        return .init(id: id, recordedStart: recordedStart, recordedEnd: recordedEnd, fileType: fileType, parentId: self.id, switchHistory: switchHistory)
    }
    
    func rename(fileName: String) -> Bool {
        let trimmed = fileName.trimmingCharacters(in: .whitespacesAndNewlines)
        if (!FileHelper.validateFileName(fileName: trimmed)) {
            return false
        }
        
        return rename(fileName: trimmed, count: 0)
    }
    
    private func rename(fileName: String, count: Int) -> Bool {
        let withCount: String = count > 0 ? fileName + "-" + String(count) : fileName
        let url: URL = Video.generateFileUrl(fileName: withCount, fileType: self.fileType)
        
        if (FileManager.default.fileExists(atPath: url.path)) {
            return self.fileUrl == url || rename(fileName: fileName, count: count + 1)
        }
        
        do {
            try FileManager.default.moveItem(at: self.fileUrl, to: url)
        } catch {
            print("-- Video.rename : File Move Error --")
            print("source: " + self.fileUrl.path)
            print("moveTo: " + url.path)
            print(error)
            return false
        }
        
        self.fileName = withCount
        return true
    }
    
    private static func generateFileUrl(id: UUID, fileType: String) -> URL {
        let dir: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileName: String = "video-" + id.uuidString
        return dir.appendingPathComponent(fileName + "." + fileType)
    }
    
    private static func generateFileUrl (fileName : String, fileType: String) -> URL {
        let dir: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return dir.appendingPathComponent(fileName + "." + fileType)
    }
    
    private func calcRecordedStart(switchHistory: SwitchHistoryProtocol, before: Int) -> Date {
        let recordedStart: Date = Calendar.current.date(byAdding:.second, value: before > 0 ? -before : -1, to:switchHistory.happend)!
        return recordedStart >= self.recordedStart ? recordedStart : self.recordedStart
    }
    
    private func calcRecordedEnd(switchHistory: SwitchHistoryProtocol, after: Int) -> Date {
        let recordedEnd: Date = Calendar.current.date(byAdding:.second, value: after > 0 ? after : 1, to:switchHistory.happend)!
        return recordedEnd <= self.recordedEnd ? recordedEnd : self.recordedEnd
    }
}
