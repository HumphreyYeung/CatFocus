//
//  Item.swift
//  CatFocus
//
//  Created by Humphrey Yeung on 6/14/26.
//

import Foundation

struct Item: Identifiable, Equatable {
    let id: UUID
    let timestamp: Date
    
    init(id: UUID = UUID(), timestamp: Date) {
        self.id = id
        self.timestamp = timestamp
    }
}
