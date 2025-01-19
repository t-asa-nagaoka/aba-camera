//
//  ExtractPoint.swift
//  aba-camera
//
//  Created by shiolab_asakura on 2025/01/17.
//

import Foundation

struct ExtractPoint : ExtractPointProtocol {
    var id: Int
    var happend: Date
    var subjective: Bool
    
    init (id: Int) {
        self.id = id
        self.happend = .init()
        self.subjective = false
    }
    
    init (id: Int, extractPoint: ExtractPointProtocol) {
        self.id = id
        self.happend = extractPoint.happend
        self.subjective = extractPoint.subjective
    }
}
