//
//  UUIDHelper.swift
//  aba-camera
//
//  Created by shiolab_asakura on 2025/01/17.
//

import Foundation

class UUIDHelper {
    static func regenerateId(id: UUID, ids: [UUID], force: Bool = false) -> UUID {
        if (force || ids.contains(id)) {
            return UUIDHelper.regenerateId(id: .init(), ids: ids)
        }
        return id
    }
}
