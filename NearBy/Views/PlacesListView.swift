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
        case rating   = "Rating"
        case name     = "Name"

        var id: String { rawValue }
    }

    @Published var places: [Place] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchText = ""
    @Published var selectedCategory: Category?
    @Published var selectedDistance: Double? = nil
    @Published var minimumRating: Double = 0
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

    var activeFilterCount: Int {
        (selectedCategory != nil ? 1 : 0) +
        (selectedDistance != nil ? 1 : 0) +
        (minimumRating > 0 ? 1 : 0)
    }

    var filteredAndSorted: [Place] {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let userLoc: CLLocation? = {
            guard let u = locationManager.userLocation else { return nil }
            return CLLocation(latitude: u.latitude, longitude: u.longitude)
        }()

        let filtered = places.filter { place in
            let matchesText = q.isEmpty
                || place.name.lowercased().contains(q)
                || place.address.lowercased().contains(q)
                || place.category.lowercased().contains(q)

            let matchesCategory = selectedCategory == nil
                || place.category.lowercased() == selectedCategory?.name.lowercased()

            let matchesDistance: Bool = {
                guard let maxDist = selectedDistance, let userLoc else { return true }
                let placeLoc = CLLocation(latitude: place.latitude, longitude: place.longitude)
                return userLoc.distance(from: placeLoc) <= maxDist
            }()

            let matchesRating = place.rating >= minimumRating

            return matchesText && matchesCategory && matchesDistance && matchesRating
        }

        switch sortOption {
        case .name:
            return filtered.sorted {
                $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
        case .rating:
            return filtered.sorted { $0.rating > $1.rating }
        case .distance:
            guard let userLoc else { return filtered }
            return filtered.sorted {
                userLoc.distance(from: CLLocation(latitude: $0.latitude, longitude: $0.longitude)) <
                userLoc.distance(from: CLLocation(latitude: $1.latitude, longitude: $1.longitude))
            }
        }
    }

    func distanceText(for place: Place, units: String) -> String? {
        guard let user = locationManager.userLocation else { return nil }
        let userLoc = CLLocation(latitude: user.latitude, longitude: user.longitude)
        let meters  = userLoc.distance(from: CLLocation(latitude: place.latitude, longitude: place.longitude))
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
}

struct PlacesListView: View {
    @StateObject private var vm       = PlacesListViewModel()
    @StateObject private var settings = UserSettingsStore.shared
    @State private var showFilter     = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 10) {
                HStack(spacing: 10) {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass").foregroundColor(.secondary)
                        TextField("Search places", text: $vm.searchText)
                            .textInputAutocapitalization(.never)
                            .disableAutocorrection(true)
                        if !vm.searchText.isEmpty {
                            Button { vm.searchText = "" } label: {
                                Image(systemName: "xmark.circle.fill").foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(10)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                    Button { showFilter = true } label: {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "slider.horizontal.3")
                                .font(.title3)
                                .padding(10)
                                .background(
                                    vm.activeFilterCount > 0
                                    ? Color.blue
                                    : Color(.secondarySystemBackground)
                                )
                                .foregroundColor(vm.activeFilterCount > 0 ? .white : .primary)
                                .clipShape(RoundedRectangle(cornerRadius: 10))

                            if vm.activeFilterCount > 0 {
                                Text("\(vm.activeFilterCount)")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(4)
                                    .background(Color.red)
                                    .clipShape(Circle())
                                    .offset(x: 6, y: -6)
                            }
                        }
                    }
                }

                Picker("Sort", selection: $vm.sortOption) {
                    ForEach(PlacesListViewModel.SortOption.allCases) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(.segmented)

                if vm.activeFilterCount > 0 {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            if let cat = vm.selectedCategory {
                                activeChip(label: cat.name) { vm.selectedCategory = nil }
                            }
                            if let dist = vm.selectedDistance {
                                activeChip(label: distanceLabel(dist)) { vm.selectedDistance = nil }
                            }
                            if vm.minimumRating > 0 {
                                activeChip(label: "\(formatRating(vm.minimumRating))★ min") {
                                    vm.minimumRating = 0
                                }
                            }
                        }
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
                            .font(.system(size: 36)).foregroundColor(.secondary)
                        Text("No places found").font(.headline)
                        Text("Try changing your search or filters.")
                            .font(.caption).foregroundColor(.secondary)
                        if vm.activeFilterCount > 0 {
                            Button("Clear Filters") {
                                vm.selectedCategory = nil
                                vm.selectedDistance = nil
                                vm.minimumRating    = 0
                            }
                            .buttonStyle(.borderedProminent)
                            .padding(.top, 4)
                        }
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
                if vm.places.isEmpty { vm.load() }
            }
            .sheet(isPresented: $showFilter) {
                FilterView(
                    selectedCategory: $vm.selectedCategory,
                    selectedDistance: $vm.selectedDistance,
                    minimumRating:    $vm.minimumRating
                )
            }
            .alert("Error", isPresented: .constant(vm.errorMessage != nil), actions: {
                Button("OK") { vm.errorMessage = nil }
            }, message: {
                Text(vm.errorMessage ?? "")
            })
        }
    }

    private func activeChip(label: String, onRemove: @escaping () -> Void) -> some View {
        HStack(spacing: 4) {
            Text(label).font(.caption).fontWeight(.medium)
            Button { onRemove() } label: {
                Image(systemName: "xmark").font(.system(size: 9, weight: .bold))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.blue.opacity(0.12))
        .foregroundColor(.blue)
        .clipShape(Capsule())
    }

    private func distanceLabel(_ meters: Double) -> String {
        meters >= 1000
            ? String(format: "%.0f km", meters / 1000)
            : "\(Int(meters)) m"
    }

    private func formatRating(_ rating: Double) -> String {
        rating == Double(Int(rating)) ? "\(Int(rating))" : String(format: "%.1f", rating)
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
            HStack {
                Text(place.category)
                    .font(.caption)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(Color.blue.opacity(0.12))
                    .clipShape(Capsule())
                Spacer()
                if let distanceText {
                    Label(distanceText, systemImage: "location")
                        .font(.caption).foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 6)
    }
}

#Preview {
    PlacesListView()
}
