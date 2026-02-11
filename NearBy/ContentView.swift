//
//  ContentView.swift
//  NearBy
//
//  Created by Rafat on 2026-01-31.
//

import SwiftUI

struct ContentView: View {
    
    enum Tab {
        case home, map, places, favorites, profile
    }
    
    @StateObject private var auth = AuthService.shared
    @State private var isLoaded = false
    @State private var tab: Tab = .map
    
    var body: some View {
        
        Group {
            if !isLoaded {
                
                ZStack {
                    Color(.systemBackground)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 20) {
                        Image("NearByIcon")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 80, height: 80)
                        
                        Text("NearBy")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        ProgressView()
                            .scaleEffect(1.2)
                    }
                }
                .task {
                    
                    auth.fetchCurrentUser { _ in
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            isLoaded = true
                        }
                    }
                }
            }
            else if auth.currentUser == nil {
                AuthGate()
            }
            else {
                
                ZStack(alignment: .bottom) {
                    
                    VStack {
                        Group {
                            switch tab {
                            case .home:
                                NavigationView {
                                    DashboardView()
                                }
                            case .map:
                                NavigationView {
                                    MapView()
                                }
                            case .places:
                                NavigationView {
                                    PlacesListView()
                                }
                            case .favorites:
                                NavigationView {
                                    FavoritesView()
                                }
                            case .profile:
                                NavigationView {
                                    ProfileView()
                                }
                            }
                        }
                        
                        HStack {
                            TabButton(title: "Home", image: "house.fill", isSelected: tab == .home) {
                                tab = .home
                            }
                            
                            Spacer()
                            
                            TabButton(title: "Map", image: "map.fill", isSelected: tab == .map) {
                                tab = .map
                            }
                            
                            Spacer()
                            
                            TabButton(title: "Places", image: "list.bullet", isSelected: tab == .places) {
                                tab = .places
                            }
                            
                            Spacer()
                            
                            TabButton(title: "Favorites", image: "heart.fill", isSelected: tab == .favorites) {
                                tab = .favorites
                            }
                            
                            Spacer()
                            
                            TabButton(title: "Profile", image: "person.fill", isSelected: tab == .profile) {
                                tab = .profile
                            }
                        }
                        .padding(.vertical, 14)
                        .padding(.horizontal, 30)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 40)
                                .fill(Color.white)
                                .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 0)
                        )
                        .ignoresSafeArea(.keyboard)
                        .ignoresSafeArea(edges: .bottom)
                    }
                }
            }
        }
    }
}

struct TabButton: View {
    let title: String
    let image: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: image)
                    .font(.system(size: 20))
                Text(title)
                    .font(.system(size: 11))
            }
            .foregroundColor(isSelected ? .blue : .black)
        }
    }
}


struct DashboardView: View {
    var body: some View {
        Text("Dashboard - Coming Soon")
            .navigationTitle("Home")
    }
}
struct PlacesListView: View {
    var body: some View {
        Text("Places List - Coming Soon")
            .navigationTitle("Places")
    }
}

struct FavoritesView: View {
    var body: some View {
        Text("Favorites - Coming Soon")
            .navigationTitle("Favorites")
    }
}

#Preview {
    ContentView()
}
