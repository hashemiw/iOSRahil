//
//  History.swift
//  TheRahil
//
//  Created by Alireza Hashemi on 2026/1/20.
//

import Foundation
import SwiftUI


struct HistoryItem: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let time: Date
    let type: String
    let icon: String
    let color: Color
}
