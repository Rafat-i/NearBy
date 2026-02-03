//
//  AuthGate.swift
//  NearBy
//
//  Created by Rafat on 2026-02-03.
//


import SwiftUI

struct AuthGate: View {
    
    @State private var showLogin = true
    
    var body: some View {
        VStack {
            VStack(spacing: 8) {
                Image(systemName: "map.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("NearBy")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Discover places around you")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 40)
            .padding(.bottom, 30)
            
            Picker("", selection: $showLogin) {
                Text("Login").tag(true)
                Text("Sign Up").tag(false)
            }
            .pickerStyle(.segmented)
            .padding()
            
            if showLogin {
                LoginView()
            } else {
                RegisterView()
            }
            
            Spacer()
        }
    }
}

#Preview {
    AuthGate()
}
