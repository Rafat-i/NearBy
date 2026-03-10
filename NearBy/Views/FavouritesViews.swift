//
//  FavouritesViews.swift
//  NearBy
//
//  Created by Chadi Faour on 2026-02-24.
//

import SwiftUI
import CoreData
import Combine


struct FavouritesViews: View {
    @State private var favourites: [PlaceEntity] = []
    private let coreData = CoreDataManager.shared
    private let sync = PlaceSyncCoordinator.shared
    
    var body: some View {
        NavigationStack {
            if favourites.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "heart.slash")
                        .font(.system(size: 50))
                        .foregroundColor(.secondary)
                    Text("No Favorites Yet")
                        .font(.title3).fontWeight(.semibold)
                    Text("Tap the heart to save it here")
                        .font(.subheadline).foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(favourites, id: \.id) { entity in
                        NavigationLink(destination: PlaceDetailView(place: makPlace(from: entity)).onDisappear { load() }) {
                            VStack(spacing: 4) {
                                Text(entity.name ?? "")
                                    .font(.subheadline).fontWeight(.semibold)
                                Text(entity.address ?? "")
                                    .font(.caption).foregroundColor(.secondary)
                                HStack(spacing: 4) {
                                    Image(systemName: "star.fill").font(.caption2).foregroundColor(.yellow)
                                    Text(String(format: "%.1f", entity.rating)).font(.caption2).foregroundColor(.secondary)
                                }
                            }
                        }
                        .swipeActions {
                            Button(role: .destructive) { remove(entity) } label: {
                                Label("Remove", systemImage: "heart.slash.fill")
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("Favourites")
        .onAppear { load() }
    }
    
    private func load() {
        guard let userId = AuthService.shared.currentUser?.id else {
            favourites = []
            return
        }

        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "isFavorite == true"),
            NSPredicate(format: "userId == %@", userId)
        ])

        favourites = (try? coreData.fetch(PlaceEntity.self, predicate: predicate)) ?? []
    }
    
    private func remove(_ entity: PlaceEntity) {
        entity.isFavorite = false
        try? sync.saveAndSyncMainContext()
        load()
    }
    
    private func makPlace(from entity: PlaceEntity) -> Place {
        Place(
            id: entity.id, name: entity.name ?? "", category: entity.placeCategory ?? "", address: entity.address ?? "", latitude: entity.latitude, longitude: entity.longitude, rating: entity.rating, phone: entity.phone, photoURL: entity.photoUrl, website: entity.website
        )
    }
}

#Preview {
    FavouritesViews()
}
