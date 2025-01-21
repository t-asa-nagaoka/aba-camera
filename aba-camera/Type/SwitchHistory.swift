//
//  SwitchHistory.swift
//  aba-camera
//
//  Created by shiolab_asakura on 2025/01/17.
//

import Foundation

struct SwitchHistory : SwitchHistoryProtocol {
    var id: Int
    var happend: Date
    var subjective: Bool
    
    init(id: Int, happend: Date, subjective: Bool) {
        self.id = id
        self.happend = happend
        self.subjective = subjective
    }
}
