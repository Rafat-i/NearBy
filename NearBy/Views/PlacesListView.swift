//
//  PlacesListView.swift
//  NearBy
//
//  Created by Rafat on 2026-03-09.
//

import SwiftUI
import CoreLocation
import Combine

@MainActor
final class PlacesListViewModel: ObservableObject {
    enum SortOption: String, CaseIterable, Identifiable {
        case distance = "Distance"
        case rating = "Rating"
        case name = "Name"

        var id: String { rawValue }
    }

    @Published var places: [Place] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchText = ""
    @Published var selectedCategory: Category?
    @Published var sortOption: SortOption = .distance

    private let locationManager = LocationManager()

    func load() {
        isLoading = true
        errorMessage = nil

        FirebaseService.shared.fetchNearbyPlaces { [weak self] result in
            guard let self else { return }
            self.isLoading = false
            switch result {
            case .success(let fetched):
                self.places = fetched
            case .failure(let error):
                self.errorMessage = "Unable to fetch places: \(error.localizedDescription)"
            }
        }
    }

    var filteredAndSorted: [Place] {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        let filtered = places.filter { place in
            let matchesText = q.isEmpty
                || place.name.lowercased().contains(q)
                || place.address.lowercased().contains(q)
                || place.category.lowercased().contains(q)
            let matchesCategory = selectedCategory == nil
                || place.category.lowercased() == selectedCategory?.name.lowercased()
            return matchesText && matchesCategory
        }

        switch sortOption {
        case .name:
            return filtered.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .rating:
            return filtered.sorted { $0.rating > $1.rating }
        case .distance:
            guard let user = locationManager.userLocation else { return filtered }
            let userLoc = CLLocation(latitude: user.latitude, longitude: user.longitude)
            return filtered.sorted {
                distance(from: userLoc, to: $0.coordinate) < distance(from: userLoc, to: $1.coordinate)
            }
        }
    }

    func distanceText(for place: Place, units: String) -> String? {
        guard let user = locationManager.userLocation else { return nil }
        let userLoc = CLLocation(latitude: user.latitude, longitude: user.longitude)
        let meters = distance(from: userLoc, to: place.coordinate)
        if units == "imperial" {
            let feet = meters * 3.28084
            if feet >= 5280 {
                return String(format: "%.1f mi", feet / 5280)
            }
            return "\(Int(feet)) ft"
        }
        if meters >= 1000 {
            return String(format: "%.1f km", meters / 1000)
        }
        return "\(Int(meters)) m"
    }

    private func distance(from user: CLLocation, to destination: CLLocationCoordinate2D) -> CLLocationDistance {
        let destinationLoc = CLLocation(latitude: destination.latitude, longitude: destination.longitude)
        return user.distance(from: destinationLoc)
    }
}

struct PlacesListView: View {
    @StateObject private var vm = PlacesListViewModel()
    @StateObject private var settings = UserSettingsStore.shared

    var body: some View {
        NavigationStack {
            VStack(spacing: 10) {
                HStack(spacing: 10) {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("Search places", text: $vm.searchText)
                            .textInputAutocapitalization(.never)
                            .disableAutocorrection(true)
                    }
                    .padding(10)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                    Menu {
                        Button("All Categories") { vm.selectedCategory = nil }
                        ForEach(Category.defaultCategories) { category in
                            Button(category.name) { vm.selectedCategory = category }
                        }
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                            .font(.title3)
                            .padding(10)
                            .background(Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }

                Picker("Sort", selection: $vm.sortOption) {
                    ForEach(PlacesListViewModel.SortOption.allCases) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(.segmented)

                if let category = vm.selectedCategory {
                    HStack {
                        Label("Category: \(category.name)", systemImage: category.iconName ?? "line.3.horizontal.decrease.circle")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button("Clear") { vm.selectedCategory = nil }
                            .font(.caption)
                    }
                }

                if vm.isLoading {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if vm.filteredAndSorted.isEmpty {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "map")
                            .font(.system(size: 36))
                            .foregroundColor(.secondary)
                        Text("No places found")
                            .font(.headline)
                        Text("Try changing your search, category, or sort options.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else {
                    List(vm.filteredAndSorted, id: \.id) { place in
                        NavigationLink(destination: PlaceDetailView(place: place)) {
                            PlaceListRow(
                                place: place,
                                distanceText: vm.distanceText(for: place, units: settings.units)
                            )
                        }
                    }
                    .listStyle(.plain)
                    .refreshable { vm.load() }
                }
            }
            .padding(.horizontal)
            .navigationTitle("Places")
            .onAppear {
                settings.loadForCurrentUser()
                if vm.places.isEmpty {
                    vm.load()
                }
            }
            .alert("Error", isPresented: .constant(vm.errorMessage != nil), actions: {
                Button("OK") { vm.errorMessage = nil }
            }, message: {
                Text(vm.errorMessage ?? "")
            })
        }
    }
}

private struct PlaceListRow: View {
    let place: Place
    let distanceText: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(place.name)
                    .font(.headline)
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                    Text(String(format: "%.1f", place.rating))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Text(place.address)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)

            HStack {
                Text(place.category)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.blue.opacity(0.12))
                    .clipShape(Capsule())
                Spacer()
                if let distanceText {
                    Label(distanceText, systemImage: "location")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 6)
    }
}

#Preview {
    PlacesListView()
}

