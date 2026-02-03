//
//  ProfileView.swift
//  NearBy
//
//  Created by Rafat on 2026-02-03.
//


import SwiftUI

struct ProfileView: View {
    @ObservedObject private var auth = AuthService.shared
    @State private var newUsername = ""
    @State private var errorText: String?
    @State private var successMessage: String?
    @State private var showEditUsername = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Profile Information") {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(auth.currentUser?.username ?? "User")
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            Text(auth.currentUser?.email ?? "")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.leading, 8)
                    }
                    .padding(.vertical, 8)
                }
                
                Section("Statistics") {
                    HStack {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
                        Text("Favorite Places")
                        Spacer()
                        Text("\(auth.currentUser?.favoriteCount ?? 0)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Image(systemName: "mappin.and.ellipse")
                            .foregroundColor(.blue)
                        Text("Places Visited")
                        Spacer()
                        Text("\(auth.currentUser?.visitedPlacesCount ?? 0)")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("Account Settings") {
                    Button {
                        showEditUsername = true
                    } label: {
                        HStack {
                            Image(systemName: "pencil")
                            Text("Edit Username")
                        }
                    }
                }
                
                if let errorText {
                    Section {
                        Text(errorText)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                
                if let successMessage {
                    Section {
                        Text(successMessage)
                            .foregroundColor(.green)
                            .font(.caption)
                    }
                }

                Section {
                    Button(role: .destructive) {
                        let result = auth.signOut()
                        if case .failure(let err) = result {
                            errorText = err.localizedDescription
                        } else {
                            errorText = nil
                            successMessage = nil
                        }
                    } label: {
                        HStack {
                            Spacer()
                            Image(systemName: "arrow.right.square")
                            Text("Log Out")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Profile")
            .sheet(isPresented: $showEditUsername) {
                EditUsernameView(
                    currentUsername: auth.currentUser?.username ?? "",
                    onSave: { newName in
                        updateUsername(newName)
                    }
                )
            }
            .onAppear {
                auth.fetchCurrentUser { _ in }
            }
        }
    }
    
    private func updateUsername(_ newName: String) {
        let trimmed = newName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            errorText = "Username cannot be empty"
            successMessage = nil
            return
        }

        auth.updateUsername(username: trimmed) { result in
            switch result {
            case .success:
                errorText = nil
                successMessage = "Username updated successfully!"
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    successMessage = nil
                }
            case .failure(let err):
                errorText = err.localizedDescription
                successMessage = nil
            }
        }
    }
}

struct EditUsernameView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var username: String
    let onSave: (String) -> Void
    
    init(currentUsername: String, onSave: @escaping (String) -> Void) {
        _username = State(initialValue: currentUsername)
        self.onSave = onSave
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Update Username") {
                    TextField("Username", text: $username)
                        .autocorrectionDisabled()
                }
            }
            .navigationTitle("Edit Username")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(username)
                        dismiss()
                    }
                    .disabled(username.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

#Preview {
    ProfileView()
}
