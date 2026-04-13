//
//  RatedPlacesList.swift
//  NearBy
//
//  Created by Chadi Faour on 2026-04-07.
//

import SwiftUI
import FirebaseFirestore
import Combine

struct RatedPlace: Identifiable {
    let id: String
    let name: String
    let category: String
    let address: String
    let latitude: Double
    let longitude: Double
    let rating: Double
    let phone: String?
    let userRating: Double
}

@MainActor
class RatedPlacesViewModel: ObservableObject {
    @Published var ratedPlaces: [RatedPlace] = []
    @Published var isLoading: Bool = true
    
    init() { load() }
    
    func load() {
        guard let userID = AuthService.shared.currentUser?.id else { return }
        let db = Firestore.firestore()
        
        db.collection("places").getDocuments { snap, _ in
            guard let docs = snap?.documents else {
                self.isLoading = false
                return
            }
            let group = DispatchGroup()
            var results: [RatedPlace] = []
            
            for doc in docs {
                let data = doc.data()
                let placeID = doc.documentID
                
                group.enter()
                db.collection("places").document(placeID)
                    .collection("ratings").document(userID)
                    .getDocument { ratingSnap, _ in
                        defer { group.leave() }
                        guard let userRating = ratingSnap?.data()?["rating"] as? Double, userRating > 0 else { return }
                        
                        results.append(RatedPlace(id: placeID, name: data["name"] as? String ?? "", category: data["category"] as? String ?? "", address: data["address"] as? String ?? "", latitude: data["latitude"] as? Double ?? 0, longitude: data["longitude"] as? Double ?? 0, rating: data["rating"] as? Double ?? 0, phone: data["phone"] as? String, userRating: userRating))
                    }
            }
            
            group.notify(queue: .main) {
                self.ratedPlaces = results.sorted { $0.userRating > $1.userRating }
                self.isLoading = false
            }
        }
    }
}


struct RatedPlacesList: View {
    @StateObject private var vm = RatedPlacesViewModel()
    
    
    init(vm: RatedPlacesViewModel? = nil) {
        _vm = StateObject(wrappedValue: vm ?? RatedPlacesViewModel())
    }
    var body: some View {
        Group {
            if vm.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if vm.ratedPlaces.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "star.slash")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary.opacity(0.4))
                    Text("No Rated Places Yet")
                        .font(.title3).fontWeight(.semibold)
                    Text("Rate Places from their detail page to see them here")
                        .font(.subheadline).foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(vm.ratedPlaces) { rated in
                        NavigationLink(destination: PlaceDetailView(place: makePlace(from: rated))) {
                            RatedPlaceRow(rated: rated)
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("Rated Places")
        .navigationBarTitleDisplayMode(.large)
        .onAppear { vm.load() }
    }
    
    private func makePlace(from rated: RatedPlace) -> Place {
        Place(
            id: rated.id, name: rated.name, category: rated.category, address: rated.address, latitude: rated.latitude, longitude: rated.longitude, rating: rated.rating, phone: rated.phone
        )
    }
}

struct RatedPlaceRow: View {
    let rated: RatedPlace
    
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: categoryIcon(rated.category))
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
                .padding(10)
                .background(categoryColor(rated.category).gradient, in: .circle)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(rated.name)
                    .font(.subheadline).fontWeight(.semibold)
                    .lineLimit(1)
                Text(rated.address)
                    .font(.caption).foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                HStack(spacing: 2) {
                    ForEach(1...5, id: \.self) { star in
                        Image(systemName: Double(star) <= rated.userRating ? "star.fill" : "star")
                            .font(.system(size: 10))
                            .foregroundColor(.orange)
                    }
                }
                Text(String(format: "%.1f", rated.userRating))
                    .font(.caption2).foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func categoryIcon(_ category: String) -> String {
        switch category.lowercased() {
        case "education": return "graduationcap.fill"
        case "parks":     return "tree.fill"
        case "entertainment": return "theatermasks.fill"
        case "restaurants": return "fork.knife"
        case "cafes": return "cup.and.saucer.fill"
        case "shopping": return "cart.fill"
        case "libraries": return "book.fill"
        default: return"mappin.circle.fill"
        }
    }
    
    private func categoryColor(_ category: String) -> Color {
        switch category.lowercased() {
        case "education": return .orange
        case "parks": return .green
        case "entertainment": return .purple
        case "restaurants": return .red
        case "cafes": return .brown
        case "shopping": return .pink
        case "libraries": return .blue
        default: return .gray
        }
    }
}

#Preview {
    RatedPlacesList()
}
