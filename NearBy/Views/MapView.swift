//
//  MapView.swift
//  NearBy
//
//  Created by Ace of Heart on 2026-02-06.
//

//
//  MapView.swift
//  NearBy
//
//  Created by Ace of Heart on 2026-02-06.
//

import SwiftUI
import MapKit
import CoreLocation

struct MapView: View {
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var places: [Place] = []
    @State private var isLoading = true
    @StateObject private var locationManager = LocationManager()
    
    var body: some View {
        ZStack {
            Map(position: $cameraPosition) {
              
                UserAnnotation()
                
                // Places from Firebase
                ForEach(places) { place in
                    Annotation(place.name, coordinate: place.coordinate) {
                        Image(systemName: categoryIcon(for: place.category))
                            .resizable()
                            .foregroundStyle(.white)
                            .frame(width: 20, height: 20)
                            .padding(8)
                            .background(categoryColor(for: place.category).gradient, in: .circle)
                    }
                }
            }
            .mapControls {
                MapUserLocationButton()
                MapCompass()
            }
            
            VStack {
                SearchBarView()
                
                HStack {
                    Spacer()
                    NavigationLink(destination: ProfileView()) {
                        Image(systemName: "slider.vertical.3")
                            .font(.system(size: 30, weight: .bold))
                            .foregroundColor(.white)
                            .padding()
                            .background(Circle().fill(.blue))
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
            
            if isLoading {
                ProgressView()
                    .scaleEffect(1.5)
            }
        }
        .navigationTitle("Map")
        .onAppear {
            locationManager.requestPermission()
            loadPlaces()
        }
    }
    
    private func loadPlaces() {
        isLoading = true
        FirebaseService.shared.fetchNearbyPlaces { result in
            isLoading = false
            switch result {
            case .success(let fetchedPlaces):
                self.places = fetchedPlaces
                print("Loaded \(fetchedPlaces.count) places from Firebase")
            case .failure(let error):
                print("Error loading places: \(error)")
            }
        }
    }
    
    private func categoryIcon(for category: String) -> String {
        switch category.lowercased() {
        case "education": return "graduationcap.fill"
        case "parks": return "tree.fill"
        case "entertainment": return "theatermasks.fill"
        case "restaurants", "cafes": return "fork.knife"
        default: return "mappin.circle.fill"
        }
    }
    
    private func categoryColor(for category: String) -> Color {
        switch category.lowercased() {
        case "education": return .red
        case "parks": return .green
        case "entertainment": return .blue
        case "restaurants": return .orange
        default: return .purple
        }
    }
}

#Preview {
    NavigationView {
        MapView()
    }
}
