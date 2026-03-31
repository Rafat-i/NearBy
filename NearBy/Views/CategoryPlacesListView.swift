//
//  CategoryPlacesListView.swift
//  NearBy
//
//  Created by Rafat on 2026-03-30.
//


import SwiftUI
import CoreLocation

struct CategoryPlacesListView: View {
    let category: Category

    @StateObject private var settings = UserSettingsStore.shared
    @State private var places: [Place] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var searchText = ""
    @State private var sortOption = PlacesListViewModel.SortOption.distance
    private let locationManager = LocationManager()

    var filtered: [Place] {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let categoryFiltered = places.filter {
            $0.category.lowercased() == category.name.lowercased()
        }
        let searched = q.isEmpty ? categoryFiltered : categoryFiltered.filter {
            $0.name.lowercased().contains(q) || $0.address.lowercased().contains(q)
        }
        switch sortOption {
        case .name:
            return searched.sorted {
                $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
        case .rating:
            return searched.sorted { $0.rating > $1.rating }
        case .distance:
            guard let user = locationManager.userLocation else { return searched }
            let userLoc = CLLocation(latitude: user.latitude, longitude: user.longitude)
            return searched.sorted {
                userLoc.distance(from: CLLocation(latitude: $0.latitude, longitude: $0.longitude)) <
                userLoc.distance(from: CLLocation(latitude: $1.latitude, longitude: $1.longitude))
            }
        }
    }

    var body: some View {
        
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass").foregroundColor(.secondary)
                TextField("Search \(category.name)…", text: $searchText)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                if !searchText.isEmpty {
                    Button { searchText = "" } label: {
                        Image(systemName: "xmark.circle.fill").foregroundColor(.secondary)
                    }
                }
            }
            .padding(10)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10))

            Picker("Sort", selection: $sortOption) {
                ForEach(PlacesListViewModel.SortOption.allCases) { option in
                    Text(option.rawValue).tag(option)
                }
            }
            .pickerStyle(.segmented)

            if isLoading {
                Spacer()
                ProgressView("Loading \(category.name)…")
                Spacer()
            } else if let error = errorMessage {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 36)).foregroundColor(.secondary)
                    Text(error).font(.caption).foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    Button("Retry") { load() }
                        .buttonStyle(.borderedProminent)
                }
                Spacer()
            } else if filtered.isEmpty {
                Spacer()
                VStack(spacing: 10) {
                    Image(systemName: category.iconName ?? "mappin")
                        .font(.system(size: 44)).foregroundColor(.secondary.opacity(0.4))
                    Text("No \(category.name) found")
                        .font(.headline)
                    Text("Try a different search or sort option.")
                        .font(.caption).foregroundColor(.secondary)
                }
                Spacer()
            } else {
                List(filtered, id: \.id) { place in
                    NavigationLink(destination: PlaceDetailView(place: place)) {
                        PlaceListRow(
                            place: place,
                            distanceText: distanceText(for: place)
                        )
                    }
                }
                .listStyle(.plain)
                .refreshable { load() }
            }
        }
        .padding(.horizontal)
        .navigationTitle(category.name)
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            settings.loadForCurrentUser()
            load()
        }
    }

    private func load() {
        isLoading = true
        errorMessage = nil
        FirebaseService.shared.fetchNearbyPlaces { result in
            isLoading = false
            switch result {
            case .success(let fetched): places = fetched
            case .failure(let error):  errorMessage = error.localizedDescription
            }
        }
    }

    private func distanceText(for place: Place) -> String? {
        guard let user = locationManager.userLocation else { return nil }
        let userLoc = CLLocation(latitude: user.latitude, longitude: user.longitude)
        let meters  = userLoc.distance(from: CLLocation(latitude: place.latitude, longitude: place.longitude))
        if settings.units == "imperial" {
            let feet = meters * 3.28084
            return feet >= 5280
                ? String(format: "%.1f mi", feet / 5280)
                : "\(Int(feet)) ft"
        }
        return meters >= 1000
            ? String(format: "%.1f km", meters / 1000)
            : "\(Int(meters)) m"
    }
}

private struct PlaceListRow: View {
    let place: Place
    let distanceText: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(place.name).font(.headline)
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "star.fill").foregroundColor(.yellow)
                    Text(String(format: "%.1f", place.rating))
                        .font(.caption).foregroundColor(.secondary)
                }
            }
            Text(place.address)
                .font(.subheadline).foregroundColor(.secondary).lineLimit(2)
            if let distanceText {
                Label(distanceText, systemImage: "location")
                    .font(.caption).foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 6)
    }
}

#Preview {
    NavigationStack {
        CategoryPlacesListView(category: Category.defaultCategories[0])
    }
}
