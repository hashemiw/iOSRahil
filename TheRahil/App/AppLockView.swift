//
// AppLockView.swift
// TheRahil
//
// Created by Alireza Hashemi on 2026/3/6.
//

import SwiftUI

struct AppLockView: View {
    @Binding var isUnlocked: Bool
    let passcode: String
    
    @State private var input = ""
    @State private var error = ""
    @State private var isShaking = false
    @State private var showUnlock = false
    
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 15), count: 3)
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.blue.opacity(0.3),
                    Color(UIColor.systemBackground)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.15))
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .blue.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .scaleEffect(showUnlock ? 1.1 : 1.0)
                .animation(.spring(response: 0.5, dampingFraction: 0.6), value: showUnlock)
                
                VStack(spacing: 8) {
                    Text("App Locked")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text("Enter passcode to continue")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                HStack(spacing: 15) {
                    ForEach(0..<4, id: \.self) { index in
                        Circle()
                            .stroke(input.count > index ? Color.blue : Color.gray.opacity(0.3), lineWidth: 2)
                            .frame(width: 20, height: 20)
                            .background(
                                Circle()
                                    .fill(input.count > index ? Color.blue : Color.clear)
                                    .frame(width: 12, height: 12)
                            )
                    }
                }
                .offset(x: isShaking ? 10 : 0)
                .animation(.easeInOut(duration: 0.1).repeatCount(3), value: isShaking)
                

                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(1...9, id: \.self) { number in
                        NumberButton(number: "\(number)") {
                            appendNumber("\(number)")
                        }
                    }
                    
                    Button {

                    } label: {
                        EmptyView()
                    }
                    
                    NumberButton(number: "0") {
                        appendNumber("0")
                    }
                    
                    Button {
                        deleteLast()
                    } label: {
                        Image(systemName: "delete.left.fill")
                            .font(.title2)
                            .foregroundColor(.red.opacity(0.8))
                            .frame(width: 70, height: 70)
                            .background(Color.red.opacity(0.1))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 30)
                

                if !error.isEmpty {
                    Text(error)
                        .font(.callout)
                        .fontWeight(.medium)
                        .foregroundColor(.red)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(Color.red.opacity(0.1))
                        )
                        .transition(.opacity.combined(with: .scale))
                }
                
                Spacer()
            }
            .padding()
        }
        .onAppear {
            input = ""
            error = ""
            print("🔒 [AppLockView] Stored Passcode is: '\(passcode)'")
        }
    }
    
    private func appendNumber(_ number: String) {
        guard input.count < 4 else { return }
        withAnimation(.easeOut(duration: 0.1)) {
            input += number
        }
        
        if input.count == 4 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                verifyPasscode()
            }
        }
    }
    
    private func deleteLast() {
        guard !input.isEmpty else { return }
        withAnimation(.easeOut(duration: 0.1)) {
            input.removeLast()
        }
    }
    
    func verifyPasscode() {
        func convertToEnglish(_ input: String) -> String {
            let persianNumbers = ["۰": "0", "۱": "1", "۲": "2", "۳": "3", "۴": "4", "۵": "5", "۶": "6", "۷": "7", "۸": "8", "۹": "9"]
            var result = input
            for (persian, english) in persianNumbers {
                result = result.replacingOccurrences(of: persian, with: english)
            }
            return result
        }
        
        let cleanInput = convertToEnglish(input.trimmingCharacters(in: .whitespacesAndNewlines))
        let cleanPasscode = convertToEnglish(passcode.trimmingCharacters(in: .whitespacesAndNewlines))
        
        print("[AppLockView] User Input: '\(cleanInput)' | Stored: '\(cleanPasscode)' | Match: \(cleanInput == cleanPasscode)")
        
        if cleanInput == cleanPasscode {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                showUnlock = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isUnlocked = false
            }
        } else {
            error = "Incorrect Passcode"
            input = ""
            isShaking = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isShaking = false
            }
        }
    }
}

struct NumberButton: View {
    let number: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(number)
                .font(.system(size: 28, weight: .medium, design: .rounded))
                .foregroundColor(.primary)
                .frame(width: 70, height: 70)
                .background(
                    Circle()
                        .fill(Color(UIColor.secondarySystemBackground))
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                )
        }
    }
}
