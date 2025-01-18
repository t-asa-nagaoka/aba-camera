//
//  ExtractPoint.swift
//  aba-camera
//
//  Created by shiolab_asakura on 2025/01/17.
//

import Foundation

struct ExtractPoint : ExtractPointProtocol {
    var id: Int
    var happendDate: Date
    var subjective: Bool
    
    init (id: Int) {
        self.id = id
        self.happendDate = .init()
        self.subjective = false
    }
    
    init (id: Int, extractPoint: ExtractPointProtocol) {
        self.id = id
        self.happendDate = extractPoint.happendDate
        self.subjective = extractPoint.subjective
    }
}
