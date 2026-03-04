//
//  MapView.swift
//  NearBy
//
//  Created by Ace of Heart on 2026-02-06.
//



import SwiftUI
import MapKit
import CoreLocation
import Combine


enum TransportMode: String, CaseIterable, Identifiable {
    case automobile = "Driving"
    case cycling    = "Cycling"
    case walking    = "Walking"
    case any        = "Best"

    var id: String { rawValue }

    var mkType: MKDirectionsTransportType {
        switch self {
        case .automobile: return .automobile
        case .cycling:    return .any
        case .walking:    return .walking
        case .any:        return .any
        }
    }

    var icon: String {
        switch self {
        case .automobile: return "car.fill"
        case .cycling:    return "bicycle"
        case .walking:    return "figure.walk"
        case .any:        return "arrow.triangle.swap"
        }
    }

    var color: Color {
        switch self {
        case .automobile: return .blue
        case .cycling:    return .orange
        case .walking:    return .green
        case .any:        return .purple
        }
    }
}


struct SearchSuggestion: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let source: Source

    enum Source {
        case firebase
        case mapKit
    }
}


final class SearchCompleterDelegate: NSObject, MKLocalSearchCompleterDelegate, ObservableObject {
    @Published var suggestions: [MKLocalSearchCompletion] = []

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        suggestions = completer.results
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        suggestions = []
    }
}


struct MapView: View {

    private let lasalleCollege = CLLocationCoordinate2D(latitude: 45.4915, longitude: -73.5815)

    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var zoomLevel: Double = 2_000
    @State private var didAutoCenter: Bool = false
    @State private var currentCenter: CLLocationCoordinate2D?

    @State private var places: [Place] = []
    @State private var isLoading = true
    @State private var selectedPlace: Place?

    @State private var searchText: String = ""
    @State private var isSearchBarFocused: Bool = false
    @State private var destination: CLLocationCoordinate2D?
    @State private var route: MKRoute?
    @State private var distance: Double = 0
    @State private var timeDuration: Double = 0
    @State private var isSearching: Bool = false
    @State private var errorMessage: String?

    @State private var selectedTransport: TransportMode = .automobile

    @StateObject private var locationManager = LocationManager()
    @StateObject private var completerDelegate = SearchCompleterDelegate()

    private let completer = MKLocalSearchCompleter()

    var combinedSuggestions: [SearchSuggestion] {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return [] }

        let query = searchText.lowercased()

        let firebaseSuggestions: [SearchSuggestion] = places
            .filter { $0.name.lowercased().contains(query) }
            .prefix(3)
            .map {
                SearchSuggestion(
                    title: $0.name,
                    subtitle: $0.address,
                    source: .firebase
                )
            }

        let mapKitSuggestions: [SearchSuggestion] = completerDelegate.suggestions
            .prefix(5)
            .map {
                SearchSuggestion(
                    title: $0.title,
                    subtitle: $0.subtitle,
                    source: .mapKit
                )
            }

        var seen = Set<String>()
        var merged: [SearchSuggestion] = []

        for s in firebaseSuggestions + mapKitSuggestions {
            let key = s.title.lowercased()
            if !seen.contains(key) {
                seen.insert(key)
                merged.append(s)
            }
        }

        return Array(merged.prefix(6))
    }

    var body: some View {
        ZStack {
            Map(position: $cameraPosition) {
                if let userLocation = locationManager.userLocation {
                    Annotation("You", coordinate: userLocation) {
                        ZStack {
                            Circle()
                                .fill(.blue)
                                .frame(width: 20, height: 20)
                            Circle()
                                .stroke(.white, lineWidth: 3)
                                .frame(width: 20, height: 20)
                        }
                    }
                }

                if let destination {
                    Marker(searchText, coordinate: destination)
                        .tint(.red)
                }

                if let route {
                    MapPolyline(route.polyline)
                        .stroke(selectedTransport.color, lineWidth: 5)
                }

                ForEach(places) { place in
                    Annotation(place.name, coordinate: place.coordinate) {
                        Image(systemName: categoryIcon(for: place.category))
                            .resizable()
                            .foregroundStyle(.white)
                            .frame(width: 20, height: 20)
                            .padding(8)
                            .background(categoryColor(for: place.category).gradient, in: .circle)
                            .shadow(radius: 3)
                            .onTapGesture { selectedPlace = place }
                    }
                }
            }
            .mapStyle(.standard)
            .onMapCameraChange { context in
                currentCenter = context.region.center
            }
            .sheet(item: $selectedPlace) { place in
                NavigationView { PlaceDetailView(place: place) }
            }
            .onTapGesture {
                isSearchBarFocused = false
            }

            VStack(spacing: 0) {
                VStack(spacing: 6) {
                    HStack(spacing: 10) {
                        HStack(spacing: 8) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.gray)
                                .font(.system(size: 16))

                            TextField("Search for a place...", text: $searchText)
                                .textInputAutocapitalization(.never)
                                .disableAutocorrection(true)
                                .submitLabel(.search)
                                .onSubmit {
                                    isSearchBarFocused = false
                                    runSearch()
                                }
                                .onChange(of: searchText) { _, newValue in
                                    isSearchBarFocused = true
                                    completer.queryFragment = newValue
                                }

                            if !searchText.isEmpty {
                                Button {
                                    searchText = ""
                                    isSearchBarFocused = false
                                    completer.queryFragment = ""
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.gray)
                                        .font(.system(size: 16))
                                }
                            }
                        }
                        .padding(12)
                        .background(.ultraThinMaterial)
                        .cornerRadius(10)
                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)

                        Button {
                            if route != nil || isSearching {
                                clearSearch()
                            } else {
                                isSearchBarFocused = false
                                runSearch()
                            }
                        } label: {
                            if isSearching {
                                ProgressView().tint(.white)
                            } else if route != nil {
                                Image(systemName: "xmark")
                                    .foregroundColor(.white)
                                    .font(.system(size: 20, weight: .semibold))
                            } else {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(.white)
                                    .font(.system(size: 20))
                            }
                        }
                        .frame(width: 50, height: 50)
                        .background(route != nil ? Color.red : Color.blue)
                        .cornerRadius(10)
                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
                        .disabled(
                            searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            && route == nil
                        )
                    }

                    if isSearchBarFocused && !combinedSuggestions.isEmpty {
                        suggestionsDropdown
                    }
                }
                .padding(.horizontal)
                .padding(.top, 60)

                if route != nil || isSearching {
                    transportPicker
                        .padding(.horizontal)
                        .padding(.top, 6)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                HStack {
                    Spacer()
                    NavigationLink(destination: CategoriesView(filter: MapFilter())) {
                        Image(systemName: "slider.vertical.3")
                            .font(.title2)
                            .foregroundStyle(.blue)
                            .padding()
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                            .shadow(radius: 6)
                    }
                }
                .padding()

                Spacer()

                HStack {
                    Spacer()
                    zoomControls
                }
                .padding(.horizontal)
                .padding(.bottom, 100)
            }

            if route != nil {
                VStack {
                    Spacer()
                    HStack(alignment: .bottom) {
                        RouteInfoCard(
                            duration:  timeDuration,
                            distance:  distance,
                            transport: selectedTransport
                        )
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 100)
                }
            }

            if isLoading {
                ProgressView().scaleEffect(1.5)
            }
        }
        .navigationBarHidden(true)
        .safeAreaInset(edge: .bottom) {
            if let errorMessage {
                errorMessageView(errorMessage)
            }
        }
        .onAppear {
            loadPlaces()
            completer.delegate = completerDelegate
            completer.resultTypes = [.address, .pointOfInterest, .query]
            if let userLocation = locationManager.userLocation {
                completer.region = MKCoordinateRegion(
                    center: userLocation,
                    span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
                )
            }
        }
        .onReceive(locationManager.$userLocation) { newLocation in
            guard let loc = newLocation else { return }
            completer.region = MKCoordinateRegion(
                center: loc,
                span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
            )
            guard !didAutoCenter, route == nil else { return }
            didAutoCenter = true
            cameraPosition = .camera(MapCamera(centerCoordinate: loc, distance: zoomLevel))
        }
        .onChange(of: selectedTransport) { _, _ in
            guard destination != nil else { return }
            runSearch()
        }
    }


    private var suggestionsDropdown: some View {
        VStack(spacing: 0) {
            ForEach(Array(combinedSuggestions.enumerated()), id: \.element.id) { index, suggestion in
                Button {
                    selectSuggestion(suggestion)
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: suggestion.source == .firebase ? "mappin.circle.fill" : "magnifyingglass")
                            .foregroundColor(suggestion.source == .firebase ? .blue : .gray)
                            .font(.system(size: 16))
                            .frame(width: 24)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(suggestion.title)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.primary)
                                .lineLimit(1)

                            if !suggestion.subtitle.isEmpty {
                                Text(suggestion.subtitle)
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                        }

                        Spacer()

                        if suggestion.source == .firebase {
                            Text("NearBy")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.blue)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(4)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                if index < combinedSuggestions.count - 1 {
                    Divider()
                        .padding(.leading, 46)
                }
            }
        }
        .background(.ultraThinMaterial)
        .cornerRadius(10)
        .shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: 4)
    }


    private var transportPicker: some View {
        HStack(spacing: 0) {
            ForEach(TransportMode.allCases) { mode in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTransport = mode
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: mode.icon)
                            .font(.system(size: 13, weight: .semibold))
                        Text(mode.rawValue)
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .foregroundColor(selectedTransport == mode ? .white : .primary)
                    .background(
                        selectedTransport == mode ? mode.color : Color.clear
                    )
                    .cornerRadius(8)
                }
            }
        }
        .padding(4)
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 2)
    }


    private var zoomControls: some View {
        VStack(spacing: 10) {
            Button(action: zoomIn) {
                Image(systemName: "plus.magnifyingglass")
                    .font(.title2)
                    .foregroundStyle(.white)
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
            .shadow(radius: 4)

            Button(action: zoomOut) {
                Image(systemName: "minus.magnifyingglass")
                    .font(.title2)
                    .foregroundStyle(.white)
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
            .shadow(radius: 4)

            Button(action: goToUserLocation) {
                Image(systemName: "location.fill")
                    .font(.title2)
                    .foregroundStyle(.white)
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
            .shadow(radius: 4)
        }
    }


    private func errorMessageView(_ message: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
            Text(message)
                .foregroundStyle(.red)
                .font(.caption)
            Spacer()
            Button {
                errorMessage = nil
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
    }


    private func loadPlaces() {
        isLoading = true
        FirebaseService.shared.fetchNearbyPlaces { result in
            isLoading = false
            switch result {
            case .success(let fetchedPlaces):
                self.places = fetchedPlaces
            case .failure(let error):
                errorMessage = "Failed to load places: \(error.localizedDescription)"
            }
        }
    }


    private func selectSuggestion(_ suggestion: SearchSuggestion) {
        searchText = suggestion.title
        isSearchBarFocused = false
        completer.queryFragment = ""
        runSearch()
    }


    private func runSearch() {
        Task { @MainActor in
            errorMessage = nil

            let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

            let targetCoord: CLLocationCoordinate2D
            if let existing = destination, query.isEmpty {
                targetCoord = existing
            } else {
                guard !query.isEmpty else { return }
                guard let userLocation = locationManager.userLocation else {
                    errorMessage = "User location is not available yet"
                    return
                }

                isSearching = true
                defer { isSearching = false }

                do {
                    targetCoord = try await searchCoordinate(for: query)
                    destination = targetCoord

                    let newRoute = try await calculateRoute(
                        from: userLocation,
                        to: targetCoord,
                        transport: selectedTransport
                    )
                    applyRoute(newRoute)
                } catch {
                    errorMessage = error.localizedDescription
                }
                return
            }

            guard let userLocation = locationManager.userLocation else {
                errorMessage = "User location is not available yet"
                return
            }

            isSearching = true
            defer { isSearching = false }

            do {
                let newRoute = try await calculateRoute(
                    from: userLocation,
                    to: targetCoord,
                    transport: selectedTransport
                )
                applyRoute(newRoute)
            } catch {
                if selectedTransport != .any {
                    do {
                        let fallback = try await calculateRoute(
                            from: userLocation,
                            to: targetCoord,
                            transport: .any
                        )
                        applyRoute(fallback)
                        errorMessage = "\(selectedTransport.rawValue) not available — showing best route."
                    } catch {
                        errorMessage = error.localizedDescription
                    }
                } else {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func applyRoute(_ newRoute: MKRoute) {
        route        = newRoute
        distance     = newRoute.distance
        timeDuration = newRoute.expectedTravelTime

        let rect   = newRoute.polyline.boundingMapRect
        let region = MKCoordinateRegion(rect)
        cameraPosition = .region(region)
        errorMessage = nil
    }

    private func clearSearch() {
        searchText   = ""
        destination  = nil
        route        = nil
        distance     = 0
        timeDuration = 0
        errorMessage = nil
        isSearchBarFocused = false
        completer.queryFragment = ""

        if let userLocation = locationManager.userLocation {
            withAnimation {
                cameraPosition = .camera(
                    MapCamera(centerCoordinate: userLocation, distance: zoomLevel)
                )
            }
        }
    }


    private func searchCoordinate(for query: String) async throws -> CLLocationCoordinate2D {
        try await withCheckedThrowingContinuation { continuation in
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = query

            if let userLocation = locationManager.userLocation {
                request.region = MKCoordinateRegion(
                    center: userLocation,
                    span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
                )
            }

            MKLocalSearch(request: request).start { response, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let coordinate = response?.mapItems.first?.placemark.coordinate else {
                    continuation.resume(
                        throwing: NSError(
                            domain: "Search",
                            code: 0,
                            userInfo: [NSLocalizedDescriptionKey: "No results found for: \(query)"]
                        )
                    )
                    return
                }
                continuation.resume(returning: coordinate)
            }
        }
    }

    private func calculateRoute(
        from source: CLLocationCoordinate2D,
        to destination: CLLocationCoordinate2D,
        transport: TransportMode
    ) async throws -> MKRoute {
        try await withCheckedThrowingContinuation { continuation in
            let request = MKDirections.Request()
            request.source      = MKMapItem(placemark: MKPlacemark(coordinate: source))
            request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))
            request.transportType = transport.mkType

            MKDirections(request: request).calculate { response, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let route = response?.routes.first else {
                    continuation.resume(
                        throwing: NSError(
                            domain: "Directions",
                            code: 0,
                            userInfo: [
                                NSLocalizedDescriptionKey:
                                    "No \(transport.rawValue.lowercased()) route found"
                            ]
                        )
                    )
                    return
                }
                continuation.resume(returning: route)
            }
        }
    }


    private func zoomIn() {
        let center = currentCenter ?? locationManager.userLocation ?? lasalleCollege
        zoomLevel *= 0.8
        withAnimation {
            cameraPosition = .camera(MapCamera(centerCoordinate: center, distance: zoomLevel))
        }
    }

    private func zoomOut() {
        let center = currentCenter ?? locationManager.userLocation ?? lasalleCollege
        zoomLevel *= 1.2
        withAnimation {
            cameraPosition = .camera(MapCamera(centerCoordinate: center, distance: zoomLevel))
        }
    }

    private func goToUserLocation() {
        guard let userLocation = locationManager.userLocation else { return }
        withAnimation {
            cameraPosition = .camera(MapCamera(centerCoordinate: userLocation, distance: zoomLevel))
        }
    }


    private func categoryIcon(for category: String) -> String {
        switch category.lowercased() {
        case "education":               return "graduationcap.fill"
        case "parks":                   return "tree.fill"
        case "entertainment":           return "theatermasks.fill"
        case "restaurants", "cafes":    return "fork.knife"
        case "shopping":                return "cart.fill"
        case "libraries":               return "book.fill"
        default:                        return "mappin.circle.fill"
        }
    }

    private func categoryColor(for category: String) -> Color {
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


struct RouteInfoCard: View {
    let duration:  Double
    let distance:  Double
    let transport: TransportMode

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: transport.icon)
                    .font(.system(size: 14, weight: .bold))
                Text(transport.rawValue)
                    .font(.system(size: 13, weight: .bold))
            }
            .foregroundColor(.white)

            Divider().background(Color.white.opacity(0.4))

            Label {
                Text(String(format: "%.2f km", distance / 1_000))
                    .font(.system(size: 13))
                    .foregroundColor(.white)
            } icon: {
                Image(systemName: "arrow.left.and.right")
                    .foregroundColor(.white.opacity(0.8))
                    .font(.system(size: 11))
            }

            Label {
                Text(TimeFormat(time: duration))
                    .font(.system(size: 13))
                    .foregroundColor(.white)
            } icon: {
                Image(systemName: "clock")
                    .foregroundColor(.white.opacity(0.8))
                    .font(.system(size: 11))
            }
        }
        .padding(12)
        .fixedSize()
        .background(transport.color)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 3)
    }
}


#Preview {
    NavigationView {
        MapView()
    }
}
