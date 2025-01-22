//
//  SwitchHistory.swift
//  aba-camera
//
//  Created by shiolab_asakura on 2025/01/17.
//

import Foundation

enum SwitchHistoryExtractStatus: Int {
    case none = 0
    case success = 1
    case failed = 2
}

struct SwitchHistory : SwitchHistoryProtocol {
    var id: Int
    var happend: Date
    var subjective: Bool
    var status: SwitchHistoryExtractStatus
    
    init(id: Int, happend: Date, subjective: Bool) {
        self.id = id
        self.happend = happend
        self.subjective = subjective
        self.status = .none
    }
}
