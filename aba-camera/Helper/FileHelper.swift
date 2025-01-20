//
//  FileHelper.swift
//  aba-camera
//
//  Created by shiolab_asakura on 2025/01/17.
//

import Foundation

class FileHelper {
    
    static func setAsExcludedBackup(url: URL) -> Bool {
        var _url: URL = url
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        
        do {
            try _url.setResourceValues(values)
        } catch let error {
            print("-- FileHelper.setAsExcludedBackup : Error --")
            print("source: " + _url.path)
            print(error)
            return false
        }
        
        return true
    }
    
    static func validateFileName(fileName: String) -> Bool {
        // 禁止文字 参考: https://www.curict.com/item/6e/6e3772c.html

        let invalid: Bool = fileName.isEmpty
        || fileName.hasPrefix("video-")
        || fileName == "."
        || fileName.contains("\"")
        || fileName.contains("<")
        || fileName.contains(">")
        || fileName.contains("|")
        || fileName.contains(":")
        || fileName.contains(";")
        || fileName.contains("*")
        || fileName.contains("?")
        || fileName.contains("¥")
        || fileName.contains("/")
        || fileName.contains("\\")
        return !invalid
    }
    
    static func deleteFiles(urls: [URL]) -> Bool {
        let deleteSuccess: Int = urls.count {
            do {
                try FileManager.default.removeItem(at: $0)
            } catch {
                if (!FileManager.default.fileExists(atPath: $0.path)) {
                    return true
                }
                print("-- FileHelper.deleteFiles : Delete File Error --")
                print("source: " + $0.path)
                print(error)
                return false
            }
            return true
        }
        
        return deleteSuccess == urls.count
    }
    
    static func deleteAllFiles() -> Bool {
        let dir: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let files: [String] = try! FileManager.default.contentsOfDirectory(atPath: dir.path)
        let urls: [URL] = files.map { dir.appendingPathComponent($0) }
        return FileHelper.deleteFiles(urls: urls)
    }
    
    static func deleteTemporaryFiles() -> Bool {
        let dir: URL = FileManager.default.temporaryDirectory
        let files: [String] = try! FileManager.default.contentsOfDirectory(atPath: dir.path)
        let urls: [URL] = files.map { dir.appendingPathComponent($0) }
        return FileHelper.deleteFiles(urls: urls)
    }
}
