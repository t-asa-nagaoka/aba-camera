//
//  IVideo.swift
//  aba-camera
//
//  Created by shiolab_asakura on 2025/01/14.
//

import Foundation

protocol VideoProtocol {
    var recordedStart: Date { get }
    var recordedEnd: Date { get }
    var fileType: String { get }
    var videoUrl: URL { get }
    
    func deleteSource() -> Bool
}
