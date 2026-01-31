//
//  AuthLoadingView.swift
//  TheRahil
//
//  Created by Alireza Hashemi on 2026/1/17.
//

import SwiftUI

struct AuthLoadingView: View {
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            Color(UIColor.systemBackground)
                .opacity(0.9)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(Color.primary.opacity(0.2))
                        .frame(width: 80, height: 80)
                        .scaleEffect(isAnimating ? 1.5 : 1.0)
                        .opacity(isAnimating ? 0.0 : 1.0)

                    Circle()
                        .fill(Color.primary.opacity(0.4))
                        .frame(width: 80, height: 80)
                        .scaleEffect(isAnimating ? 1.2 : 1.0)
                        .opacity(isAnimating ? 0.0 : 1.0)

                    Circle()
                        .fill(Color.primary)
                        .frame(width: 60, height: 60)
                }
                .animation(
                    Animation.easeInOut(duration: 1.2)
                        .repeatForever(autoreverses: false),
                    value: isAnimating
                )

                Text("Processing...")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}
