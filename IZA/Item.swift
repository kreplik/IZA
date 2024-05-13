//
//  Item.swift
//  IZA
//
//  Created by Adam Nieslanik on 13.05.2024.
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
