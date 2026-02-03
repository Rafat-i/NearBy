//
//  RegisterView.swift
//  NearBy
//
//  Created by Rafat on 2026-02-03.
//


import SwiftUI

struct RegisterView: View {
    
    @State private var email = ""
    @State private var password = ""
    @State private var username = ""
    @State private var errorMessage: String?
    @State private var isLoading = false
    
    @StateObject private var auth = AuthService.shared
    
    var body: some View {
        Form {
            Section("Create Your Account") {
                TextField("Username", text: $username)
                    .autocorrectionDisabled()
                
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
                    signUpUser()
                } label: {
                    if isLoading {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                    } else {
                        Text("Sign Up")
                            .frame(maxWidth: .infinity)
                            .fontWeight(.semibold)
                    }
                }
                .disabled(email.isEmpty || password.isEmpty || username.isEmpty || isLoading)
            }
        }
    }
    
    private func signUpUser() {
        errorMessage = nil
        
        guard !username.trimmingCharacters(in: .whitespaces).isEmpty else {
            self.errorMessage = "Username is required"
            return
        }
        
        guard Validators.isValidEmail(email) else {
            self.errorMessage = "Please enter a valid email address"
            return
        }
        
        guard Validators.isValidPassword(password) else {
            self.errorMessage = "Password must be at least 6 characters"
            return
        }
        
        isLoading = true
        
        auth.signUp(email: email, password: password, username: username) { result in
            isLoading = false
            
            switch result {
            case .success:
                self.errorMessage = nil
            case .failure(let failure):
                self.errorMessage = failure.localizedDescription
            }
        }
    }
}

#Preview {
    RegisterView()
}
