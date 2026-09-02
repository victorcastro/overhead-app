//
//  Item.swift
//  SinkingFound
//
//  Created by Victor Castro on 2/09/26.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
