//
//  LoginView.swift
//  NearBy
//
//  Created by Rafat on 2026-02-03.
//


import SwiftUI

struct LoginView: View {
    
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String?
    @State private var isLoading = false
    
    @StateObject private var auth = AuthService.shared
    
    var body: some View {
        Form {
            Section("Login to NearBy") {
                TextField("Email", text: $email)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.emailAddress)
                
                SecureField("Password (Min 6 characters)", text: $password)
            }
            
            if let errorMessage = errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .font(.caption)
                }
            }
            
            Section {
                Button {
                    loginUser()
                } label: {
                    if isLoading {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                    } else {
                        Text("Login")
                            .frame(maxWidth: .infinity)
                            .fontWeight(.semibold)
                    }
                }
                .disabled(email.isEmpty || password.isEmpty || isLoading)
            }
        }
    }
    
    private func loginUser() {
        errorMessage = nil
        
        guard Validators.isValidEmail(email) else {
            self.errorMessage = "Please enter a valid email address"
            return
        }
        
        guard Validators.isValidPassword(password) else {
            self.errorMessage = "Password must be at least 6 characters"
            return
        }
        
        isLoading = true
        
        auth.login(email: email, password: password) { result in
            isLoading = false
            
            switch result {
            case .success:
                errorMessage = nil
            case .failure(let err):
                errorMessage = err.localizedDescription
            }
        }
    }
}

#Preview {
    LoginView()
}
