//
//  AppTextField.swift
//  Rahil
//
//  Created by Alireza Hashemi on 2026/1/1.
//

import SwiftUI

struct AppTextField: View {
    let title: String
    @Binding var text: String
    var isSecure: Bool = false

    var body: some View {
        Group {
            if isSecure {
                SecureField(title, text: $text)
            } else {
                TextField(title, text: $text)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}
