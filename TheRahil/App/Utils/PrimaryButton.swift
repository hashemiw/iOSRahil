//
//  PrimaryButton.swift
//  Rahil
//
//  Created by Alireza Hashemi on 2026/1/1.
//

import SwiftUI

struct PrimaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, minHeight: 50)
                .background(Color.secondary)
                .cornerRadius(12)
        }
    }
}
