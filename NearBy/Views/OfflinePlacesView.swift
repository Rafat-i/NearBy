//
//  OfflinePlacesView.swift
//  NearBy
//
//  Created by Rafat on 2026-03-31.
//


import SwiftUI
import CoreData
import CoreLocation

struct OfflinePlacesView: View {
    @ObservedObject private var network = NetworkMonitor.shared
    @ObservedObject private var settings = UserSettingsStore.shared
    @State private var cachedPlaces: [PlaceEntity] = []
    @State private var searchText   = ""
    @State private var sortOption   = OfflineSort.name
    private let coreData = CoreDataManager.shared
    private let locationManager = LocationManager()

    enum OfflineSort: String, CaseIterable, Identifiable {
        case name      = "Name"
        case rating    = "Rating"
        case favorites = "Favorites"
        var id: String { rawValue }
    }

    var filtered: [PlaceEntity] {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let base = cachedPlaces.filter { entity in
            q.isEmpty
                || (entity.name ?? "").lowercased().contains(q)
                || (entity.address ?? "").lowercased().contains(q)
                || (entity.placeCategory ?? "").lowercased().contains(q)
        }
        switch sortOption {
        case .name:
            return base.sorted {
                ($0.name ?? "").localizedCaseInsensitiveCompare($1.name ?? "") == .orderedAscending
            }
        case .rating:
            return base.sorted { $0.rating > $1.rating }
        case .favorites:
            return base.sorted {
                if $0.isFavorite != $1.isFavorite { return $0.isFavorite }
                return ($0.name ?? "") < ($1.name ?? "")
            }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if network.isConnected {
                    HStack(spacing: 8) {
                        Image(systemName: "wifi")
                        Text("You're back online — showing cached places")
                            .font(.caption)
                    }
                    .foregroundColor(.white)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .background(Color.green)
                    .transition(.opacity)
                } else {
                    HStack(spacing: 8) {
                        Image(systemName: "wifi.slash")
                        Text("Offline mode — showing saved places only")
                            .font(.caption)
                    }
                    .foregroundColor(.white)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .background(Color.orange)
                    .transition(.opacity)
                }

                VStack(spacing: 10) {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass").foregroundColor(.secondary)
                        TextField("Search cached places…", text: $searchText)
                            .textInputAutocapitalization(.never)
                            .disableAutocorrection(true)
                        if !searchText.isEmpty {
                            Button { searchText = "" } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(10)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                    Picker("Sort", selection: $sortOption) {
                        ForEach(OfflineSort.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)

                    if cachedPlaces.isEmpty {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "tray")
                                .font(.system(size: 48))
                                .foregroundColor(.secondary.opacity(0.4))
                            Text("No cached places yet")
                                .font(.headline)
                            Text("Places you view or save as favorites will appear here when you're offline.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }
                        Spacer()
                    } else if filtered.isEmpty {
                        Spacer()
                        VStack(spacing: 8) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 36))
                                .foregroundColor(.secondary)
                            Text("No results for \"\(searchText)\"")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    } else {
                        List(filtered, id: \.id) { entity in
                            NavigationLink(
                                destination: PlaceDetailView(place: makePlace(from: entity))
                            ) {
                                OfflinePlaceRow(entity: entity, units: settings.units, locationManager: locationManager)
                            }
                        }
                        .listStyle(.plain)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 12)
            }
            .animation(.easeInOut(duration: 0.3), value: network.isConnected)
            .navigationTitle("Offline Places")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                settings.loadForCurrentUser()
                loadCachedPlaces()
            }
        }
    }

    private func loadCachedPlaces() {
        guard let userId = AuthService.shared.currentUser?.id else {
            cachedPlaces = []
            return
        }
        let predicate = NSPredicate(format: "userId == %@", userId)
        let sort = NSSortDescriptor(key: "name", ascending: true)
        cachedPlaces = (try? coreData.fetch(
            PlaceEntity.self,
            predicate: predicate,
            sortDescriptors: [sort]
        )) ?? []
    }

    private func makePlace(from entity: PlaceEntity) -> Place {
        Place(
            id:        entity.id,
            name:      entity.name ?? "",
            category:  entity.placeCategory ?? "",
            address:   entity.address ?? "",
            latitude:  entity.latitude,
            longitude: entity.longitude,
            rating:    entity.rating,
            phone:     entity.phone,
            photoURL:  entity.photoUrl,
            website:   entity.website
        )
    }
}


private struct OfflinePlaceRow: View {
    let entity: PlaceEntity
    let units: String
    let locationManager: LocationManager

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: categoryIcon(entity.placeCategory ?? ""))
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
                .padding(10)
                .background(categoryColor(entity.placeCategory ?? "").gradient, in: .circle)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(entity.name ?? "Unknown")
                        .font(.subheadline).fontWeight(.semibold)
                        .lineLimit(1)
                    Spacer()
                    if entity.isFavorite {
                        Image(systemName: "heart.fill")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }

                Text(entity.address ?? "")
                    .font(.caption).foregroundColor(.secondary).lineLimit(1)

                HStack(spacing: 8) {
                    HStack(spacing: 3) {
                        Image(systemName: "star.fill")
                            .font(.caption2).foregroundColor(.yellow)
                        Text(String(format: "%.1f", entity.rating))
                            .font(.caption2).foregroundColor(.secondary)
                    }

                    if let dist = distanceText {
                        Label(dist, systemImage: "location")
                            .font(.caption2).foregroundColor(.secondary)
                    }

                    if entity.userNotes != nil && !(entity.userNotes ?? "").isEmpty {
                        Label("Note", systemImage: "note.text")
                            .font(.caption2).foregroundColor(.orange)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var distanceText: String? {
        guard let user = locationManager.userLocation else { return nil }
        let userLoc  = CLLocation(latitude: user.latitude, longitude: user.longitude)
        let placeLoc = CLLocation(latitude: entity.latitude, longitude: entity.longitude)
        let meters   = userLoc.distance(from: placeLoc)
        if units == "imperial" {
            let feet = meters * 3.28084
            return feet >= 5280
                ? String(format: "%.1f mi", feet / 5280)
                : "\(Int(feet)) ft"
        }
        return meters >= 1000
            ? String(format: "%.1f km", meters / 1000)
            : "\(Int(meters)) m"
    }

    private func categoryIcon(_ category: String) -> String {
        switch category.lowercased() {
        case "education":     return "graduationcap.fill"
        case "parks":         return "tree.fill"
        case "entertainment": return "theatermasks.fill"
        case "restaurants":   return "fork.knife"
        case "cafes":         return "cup.and.saucer.fill"
        case "shopping":      return "cart.fill"
        case "libraries":     return "book.fill"
        default:              return "mappin.circle.fill"
        }
    }

    private func categoryColor(_ category: String) -> Color {
        switch category.lowercased() {
        case "education":     return .orange
        case "parks":         return .green
        case "entertainment": return .purple
        case "restaurants":   return .red
        case "cafes":         return .brown
        case "shopping":      return .pink
        case "libraries":     return .blue
        default:              return .gray
        }
    }
}

#Preview {
    OfflinePlacesView()
}
