//
//  MapView.swift
//  NearBy
//
//  Created by Rafat on 2026-02-06.
//


import SwiftUI
import MapKit
import CoreLocation
import Combine

struct MapView: View {

    private let lasalleCollege = CLLocationCoordinate2D(latitude: 45.4915, longitude: -73.5815)

    @StateObject private var vm              = MapViewModel()
    @StateObject private var locationManager = LocationManager()
    @StateObject private var settings        = UserSettingsStore.shared

    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var currentCenter: CLLocationCoordinate2D?
    @State private var isNavBarVisible: Bool = true

    var body: some View {
        ZStack {
            mapLayer
            controlsOverlay
        }
        .navigationBarHidden(true)
        .safeAreaInset(edge: .bottom) {
            if let msg = vm.errorMessage { errorMessageView(msg) }
        }
        .onAppear { setup() }
        .onReceive(locationManager.$userLocation) { newLocation in
            guard let loc = newLocation else { return }
            vm.currentUserLocation = loc
            vm.updateCompleterRegion(loc)
            guard !vm.didAutoCenter, vm.route == nil else { return }
            vm.didAutoCenter = true
            cameraPosition = .camera(MapCamera(centerCoordinate: loc, distance: vm.zoomLevel))
        }
        .onChange(of: vm.selectedTransport) { _, _ in
            guard vm.destination != nil else { return }
            vm.runSearch()
        }
        .onChange(of: settings.defaultRadius) { _, newRadius in
            vm.zoomLevel = newRadius
        }
    }

    private var mapLayer: some View {
        Map(position: $cameraPosition) {
            if let userLocation = locationManager.userLocation {
                Annotation("You", coordinate: userLocation) {
                    ZStack {
                        Circle().fill(.blue).frame(width: 20, height: 20)
                        Circle().stroke(.white, lineWidth: 3).frame(width: 20, height: 20)
                    }
                }
            }

            if let dest = vm.destination {
                Marker(vm.searchText, coordinate: dest).tint(.red)
            }

            if let route = vm.route {
                MapPolyline(route.polyline).stroke(vm.selectedTransport.color, lineWidth: 5)
            }

            ForEach(vm.places) { place in
                Annotation(place.name, coordinate: place.coordinate) {
                    Image(systemName: vm.categoryIcon(for: place.category))
                        .resizable()
                        .foregroundStyle(.white)
                        .frame(width: 20, height: 20)
                        .padding(8)
                        .background(vm.categoryColor(for: place.category).gradient, in: .circle)
                        .shadow(radius: 3)
                        .onTapGesture { vm.selectedPlace = place }
                }
            }
        }
        .ignoresSafeArea()
        .mapStyle(
            settings.mapStyle == "imagery" ? .imagery :
            settings.mapStyle == "hybrid"  ? .hybrid  : .standard
        )
        .onMapCameraChange { context in currentCenter = context.region.center }
        .sheet(item: $vm.selectedPlace) { place in
            NavigationView { PlaceDetailView(place: place) }
        }
        .onTapGesture { vm.isSearchBarFocused = false }
    }

    private var controlsOverlay: some View {
        VStack(spacing: 0) {
            Spacer()

            HStack {
                Spacer()
                zoomControls
            }
            .padding(.horizontal)
            .padding(.bottom, 16)

            if vm.route != nil {
                HStack(alignment: .bottom) {
                    RouteInfoCard(duration: vm.timeDuration, distance: vm.distance, transport: vm.selectedTransport)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.bottom, 12)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            if vm.route != nil || vm.isSearching {
                transportPicker
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            VStack(spacing: 6) {
                HStack(spacing: 10) {
                    searchBar
                    searchButton
                    categoriesButton
                }
                if vm.isSearchBarFocused && !vm.combinedSuggestions.isEmpty {
                    suggestionsDropdown
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 25)
        }
    }

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
                .font(.system(size: 16))

            TextField("Search for a place ...", text: $vm.searchText)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
                .submitLabel(.search)
                .onSubmit {
                    vm.isSearchBarFocused = false
                    vm.runSearch()
                }
                .onChange(of: vm.searchText) { _, newValue in
                    vm.isSearchBarFocused = true
                    vm.completer.queryFragment = newValue
                }

            if !vm.searchText.isEmpty {
                Button {
                    vm.searchText = ""
                    vm.isSearchBarFocused = false
                    vm.completer.queryFragment = ""
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
    }

    private var searchButton: some View {
        Button {
            if vm.route != nil || vm.isSearching {
                vm.clearSearch()
                withAnimation(.easeInOut(duration: 0.3)) { isNavBarVisible = true }
                if let loc = locationManager.userLocation {
                    withAnimation {
                        cameraPosition = .camera(MapCamera(centerCoordinate: loc, distance: vm.zoomLevel))
                    }
                }
            } else {
                vm.isSearchBarFocused = false
                vm.runSearch()
            }
        } label: {
            if vm.isSearching {
                ProgressView().tint(.white)
            } else if vm.route != nil {
                Image(systemName: "xmark").foregroundColor(.white).font(.system(size: 20, weight: .semibold))
            } else {
                Image(systemName: "magnifyingglass").foregroundColor(.white).font(.system(size: 20))
            }
        }
        .frame(width: 50, height: 50)
        .background(vm.route != nil ? Color.red : Color.blue)
        .cornerRadius(10)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
        .disabled(vm.searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && vm.route == nil)
    }

    private var categoriesButton: some View {
        NavigationLink(destination: CategoriesView(filter: MapFilter())) {
            Image(systemName: "slider.vertical.3")
                .font(.system(size: 18))
                .foregroundStyle(.blue)
                .frame(width: 50, height: 50)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
        }
    }

    private var suggestionsDropdown: some View {
        VStack(spacing: 0) {
            ForEach(Array(vm.combinedSuggestions.enumerated()), id: \.element.id) { index, suggestion in
                Button {
                    vm.selectSuggestion(suggestion)
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

                if index < vm.combinedSuggestions.count - 1 {
                    Divider().padding(.leading, 46)
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
                    withAnimation(.easeInOut(duration: 0.2)) { vm.selectedTransport = mode }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: mode.icon).font(.system(size: 13, weight: .semibold))
                        Text(mode.rawValue).font(.system(size: 12, weight: .semibold))
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .foregroundColor(vm.selectedTransport == mode ? .white : .primary)
                    .background(vm.selectedTransport == mode ? mode.color : Color.clear)
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
                    .font(.title2).foregroundStyle(.white)
                    .padding().background(.ultraThinMaterial).clipShape(Circle())
            }.shadow(radius: 4)

            Button(action: zoomOut) {
                Image(systemName: "minus.magnifyingglass")
                    .font(.title2).foregroundStyle(.white)
                    .padding().background(.ultraThinMaterial).clipShape(Circle())
            }.shadow(radius: 4)

            Button(action: goToUserLocation) {
                Image(systemName: "location.fill")
                    .font(.title2).foregroundStyle(.white)
                    .padding().background(.ultraThinMaterial).clipShape(Circle())
            }.shadow(radius: 4)
        }
    }

    private func errorMessageView(_ message: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.red)
            Text(message).foregroundStyle(.red).font(.caption)
            Spacer()
            Button { vm.errorMessage = nil } label: {
                Image(systemName: "xmark.circle.fill").foregroundColor(.gray)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
    }

    private func zoomIn() {
        let center = currentCenter ?? locationManager.userLocation ?? lasalleCollege
        vm.zoomLevel *= 0.8
        withAnimation { cameraPosition = .camera(MapCamera(centerCoordinate: center, distance: vm.zoomLevel)) }
    }

    private func zoomOut() {
        let center = currentCenter ?? locationManager.userLocation ?? lasalleCollege
        vm.zoomLevel *= 1.2
        withAnimation { cameraPosition = .camera(MapCamera(centerCoordinate: center, distance: vm.zoomLevel)) }
    }

    private func goToUserLocation() {
        guard let loc = locationManager.userLocation else { return }
        withAnimation { cameraPosition = .camera(MapCamera(centerCoordinate: loc, distance: vm.zoomLevel)) }
    }

    private func setup() {
        locationManager.requestPermission()
        vm.loadPlaces()
        settings.loadForCurrentUser()
        if settings.defaultRadius > 0 { vm.zoomLevel = settings.defaultRadius }

        let region: MKCoordinateRegion? = locationManager.userLocation.map {
            MKCoordinateRegion(center: $0, span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5))
        }
        vm.setupCompleter(region: region)

        vm.onRouteReady = { route in
            cameraPosition = .region(MKCoordinateRegion(route.polyline.boundingMapRect))
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
                Image(systemName: transport.icon).font(.system(size: 14, weight: .bold))
                Text(transport.rawValue).font(.system(size: 13, weight: .bold))
            }
            .foregroundColor(.white)

            Divider().background(Color.white.opacity(0.4))

            Label {
                Text(String(format: "%.2f km", distance / 1_000))
                    .font(.system(size: 13)).foregroundColor(.white)
            } icon: {
                Image(systemName: "arrow.left.and.right")
                    .foregroundColor(.white.opacity(0.8)).font(.system(size: 11))
            }

            Label {
                Text(TimeFormat(time: duration))
                    .font(.system(size: 13)).foregroundColor(.white)
            } icon: {
                Image(systemName: "clock")
                    .foregroundColor(.white.opacity(0.8)).font(.system(size: 11))
            }
        }
        .padding(12)
        .fixedSize()
        .background(transport.color)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.2), lineWidth: 1))
        .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 3)
    }
}

#Preview {
    NavigationView { MapView() }
}
