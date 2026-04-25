//
//  SecuritySettingsView.swift
//  TheRahil
//
//  Created by Alireza Hashemi on 2026/3/6.
//

import SwiftUI

struct SecuritySettingsView: View {
    @AppStorage("local_app_passcode") private var storedPasscode: String = ""
    
    @State private var isSettingPasscode = false
    @State private var isVerifyingPasscode = false
    
    var body: some View {
        List {
            Section(header: Text("App Lock")) {
                if storedPasscode.isEmpty {
                    Button(action: { isSettingPasscode = true }) {
                        HStack {
                            Image(systemName: "lock.open")
                                .foregroundColor(.orange)
                            Text("Set App Passcode")
                            Spacer()
                            Text("Off")
                                .foregroundColor(.secondary)
                        }
                    }
                } else {
                    Button(action: { isVerifyingPasscode = true }) {
                        HStack {
                            Image(systemName: "lock.shield.fill")
                                .foregroundColor(.green)
                            Text("Change Passcode")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Button(role: .destructive) {
                        storedPasscode = ""
                    } label: {
                        HStack {
                            Text("Disable App Lock")
                            Spacer()
                            Text("On")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            Section(footer: Text("This passcode is required to open the app after you have logged in with your company account.")) {
                EmptyView()
            }
        }
        .navigationTitle("Security")
        .sheet(isPresented: $isSettingPasscode) {
            PasscodeSetupView(isPresented: $isSettingPasscode) { code in
                storedPasscode = code
            }
        }
        .sheet(isPresented: $isVerifyingPasscode) {
            PasscodeVerifyView(isPresented: $isVerifyingPasscode, currentPasscode: storedPasscode) {
                isSettingPasscode = true
            }
        }
    }
}

struct PasscodeSetupView: View {
    @Binding var isPresented: Bool
    let onPasscodeSet: (String) -> Void
    
    @State private var step = 1
    @State private var passcode = ""
    @State private var confirmPasscode = ""
    @State private var error = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Text(step == 1 ? "Create a passcode" : "Confirm your passcode")
                    .font(.title2)
                    .fontWeight(.bold)
                
                SecureField("Enter passcode", text: step == 1 ? $passcode : $confirmPasscode)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .font(.title)
                    .padding()
                
                if !error.isEmpty {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                Button(step == 1 ? "Next" : "Confirm") {
                    handleStep()
                }
                .buttonStyle(.borderedProminent)
                .disabled((step == 1 ? passcode : confirmPasscode).isEmpty)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Set Passcode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
            }
        }
    }
    
    func handleStep() {
        if step == 1 {
            if passcode.count < 4 {
                error = "Passcode must be at least 4 digits"
                return
            }
            step = 2
            error = ""
        } else {
            if confirmPasscode == passcode {
                onPasscodeSet(passcode)
                isPresented = false
            } else {
                error = "Passcodes did not match"
                confirmPasscode = ""
            }
        }
    }
}

struct PasscodeVerifyView: View {
    @Binding var isPresented: Bool
    let currentPasscode: String
    let onSuccess: () -> Void
    
    @State private var inputPasscode = ""
    @State private var error = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Text("Enter current passcode")
                    .font(.title2)
                    .fontWeight(.bold)
                
                SecureField("Passcode", text: $inputPasscode)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .font(.title)
                    .padding()
                
                if !error.isEmpty {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                Button("Verify") {
                    if inputPasscode == currentPasscode {
                        onSuccess()
                        isPresented = false
                    } else {
                        error = "Incorrect passcode"
                        inputPasscode = ""
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(inputPasscode.isEmpty)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Verify")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
            }
        }
    }
}
