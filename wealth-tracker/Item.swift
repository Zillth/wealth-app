//
//  Item.swift
//  wealth-tracker
//
//  Created by Alan Flores on 23/05/26.
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
