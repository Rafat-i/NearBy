//
//  PlaceDetailsView.swift
//  NearBy
//
//  Created by Rafat on 2026-02-24.
//


import SwiftUI
import MapKit
import CoreData
import Combine

@MainActor
class PlaceDetailViewModel: ObservableObject {

    @Published var isFavorite: Bool = false
    @Published var noteText: String = ""
    @Published var showNoteEditor: Bool = false
    @Published var noteSavedMessage: String?
    @Published var favouriteSavedMessage: String?
    @Published var errorMessage: String?
    @Published var cameraPosition: MapCameraPosition = .automatic

    let place: Place
    private let coreData = CoreDataManager.shared
    private let sync = PlaceSyncCoordinator.shared

    init(place: Place) {
        self.place = place
        cameraPosition = .camera(MapCamera(centerCoordinate: place.coordinate, distance: 800))
        loadPlaceState()
    }

    private func loadPlaceState() {
        guard
            let placeID = place.id,
            let userId = AuthService.shared.currentUser?.id
        else { return }

        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "id == %@", placeID),
            NSPredicate(format: "userId == %@", userId)
        ])
        guard let entity = try? coreData.fetchFirst(PlaceEntity.self, predicate: predicate) else { return }
        isFavorite = entity.isFavorite
        noteText   = entity.userNotes ?? ""
        entity.lastViewed = Date()
        try? sync.saveAndSyncMainContext()
    }

    private func fetchOrCreatePlaceEntity() -> PlaceEntity? {
        guard
            let placeID = place.id,
            let userId = AuthService.shared.currentUser?.id
        else { return nil }

        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "id == %@", placeID),
            NSPredicate(format: "userId == %@", userId)
        ])

        if let existing = try? coreData.fetchFirst(PlaceEntity.self, predicate: predicate) {
            return existing
        }

        guard let entity = NSEntityDescription.insertNewObject(
            forEntityName: "PlaceEntity",
            into: coreData.mainContext
        ) as? PlaceEntity else { return nil }

        entity.id            = placeID
        entity.userId        = userId
        entity.name          = place.name
        entity.address       = place.address
        entity.placeCategory = place.category
        entity.latitude      = place.latitude
        entity.longitude     = place.longitude
        entity.rating        = place.rating
        entity.phone         = place.phone
        entity.website       = place.website
        entity.photoUrl      = place.photoURL
        entity.isFavorite    = false
        entity.lastViewed    = Date()
        return entity
    }

    func toggleFavorite() {
        guard let entity = fetchOrCreatePlaceEntity() else { return }
        let newValue      = !entity.isFavorite
        entity.isFavorite = newValue
        do {
            try sync.saveAndSyncMainContext()
            isFavorite = newValue
            if newValue {
                favouriteSavedMessage = "Added to favourites"
                Task {
                    try? await Task.sleep(for: .seconds(2))
                    favouriteSavedMessage = nil
                }
            }
            let delta   = newValue ? +1 : -1
            let current = AuthService.shared.currentUser?.favoriteCount ?? 0
            AuthService.shared.updateUserStats(favoriteCount: max(0, current + delta)) { _ in }
        } catch {
            errorMessage = "Could not update favourite: \(error.localizedDescription)"
        }
    }

    func saveNote() {
        guard let placeEntity = fetchOrCreatePlaceEntity() else { return }
        placeEntity.userNotes = noteText

        let existingNote = (placeEntity.notes as? Set<NoteEntity>)?.first
        let noteEntity   = existingNote ?? coreData.create(NoteEntity.self)
        noteEntity.id          = noteEntity.id ?? UUID()
        noteEntity.text        = noteText
        noteEntity.createdDate = noteEntity.createdDate ?? Date()
        noteEntity.place       = placeEntity

        if let userId = AuthService.shared.currentUser?.id {
            let pred = NSPredicate(format: "userId == %@", userId)
            noteEntity.user = try? coreData.fetchFirst(UserEntity.self, predicate: pred)
        }

        do {
            try sync.saveAndSyncMainContext()
            noteSavedMessage = "Note saved!"
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { self.noteSavedMessage = nil }
        } catch {
            errorMessage = "Could not save note: \(error.localizedDescription)"
        }
    }
}

struct PlaceDetailView: View {

    @StateObject private var vm: PlaceDetailViewModel

    init(place: Place) {
        _vm = StateObject(wrappedValue: PlaceDetailViewModel(place: place))
    }

    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    mapSnapshotSection
                    headerCard
                        .padding(.horizontal)
                        .padding(.top, -28)
                    quickActionsRow
                        .padding(.horizontal)
                        .padding(.top, 16)
                    infoSection
                        .padding(.horizontal)
                        .padding(.top, 16)
                    notesSection
                        .padding(.horizontal)
                        .padding(.top, 16)
                    if let err = vm.errorMessage {
                        errorBanner(err)
                            .padding(.horizontal)
                            .padding(.top, 12)
                    }
                    Spacer(minLength: 40)
                }
            }
            if let msg = vm.favouriteSavedMessage {
                HStack(spacing: 8) {
                    Image(systemName: "heart.fill").foregroundColor(.red)
                    Text(msg).fontWeight(.medium)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(.ultraThinMaterial, in: Capsule())
                .shadow(radius: 8)
                .padding(.bottom, 24)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: vm.favouriteSavedMessage)
            }

        }
        .ignoresSafeArea(edges: .top)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { vm.toggleFavorite() } label: {
                    Image(systemName: vm.isFavorite ? "heart.fill" : "heart")
                        .foregroundColor(vm.isFavorite ? .red : .primary)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: vm.isFavorite)
                }
            }
        }
        .sheet(isPresented: $vm.showNoteEditor) {
            NoteEditorView(noteText: $vm.noteText, onSave: { vm.saveNote() })
        }
    }

    private var mapSnapshotSection: some View {
        ZStack(alignment: .bottom) {
            Map(position: $vm.cameraPosition) {
                Annotation(vm.place.name, coordinate: vm.place.coordinate) {
                    ZStack {
                        Circle()
                            .fill(categoryColor(vm.place.category).opacity(0.2))
                            .frame(width: 44, height: 44)
                        Image(systemName: categoryIcon(vm.place.category))
                            .foregroundStyle(.white)
                            .font(.system(size: 16, weight: .semibold))
                            .padding(10)
                            .background(categoryColor(vm.place.category).gradient, in: .circle)
                            .shadow(radius: 4)
                    }
                }
            }
            .mapStyle(.standard)
            .frame(height: 240)
            .disabled(true)

            LinearGradient(
                colors: [.clear, Color(.systemBackground)],
                startPoint: .top, endPoint: .bottom
            )
            .frame(height: 80)
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(vm.place.category, systemImage: categoryIcon(vm.place.category))
                    .font(.caption).fontWeight(.semibold)
                    .foregroundColor(categoryColor(vm.place.category))
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(categoryColor(vm.place.category).opacity(0.12))
                    .clipShape(Capsule())
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "star.fill").foregroundColor(.yellow).font(.caption)
                    Text(String(format: "%.1f", vm.place.rating))
                        .font(.caption).fontWeight(.semibold)
                }
                .padding(.horizontal, 10).padding(.vertical, 5)
                .background(Color(.secondarySystemBackground))
                .clipShape(Capsule())
            }
            Text(vm.place.name).font(.title2).fontWeight(.bold)
            Label(vm.place.address, systemImage: "mappin.circle.fill")
                .font(.subheadline).foregroundColor(.secondary).lineLimit(2)
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
    }

    private var quickActionsRow: some View {
        HStack(spacing: 12) {
            actionButton(
                label: vm.noteText.isEmpty ? "Add Note" : "Edit Note",
                icon: "note.text",
                color: .orange
            ) { vm.showNoteEditor = true }

            actionButton(
                label: vm.isFavorite ? "Saved" : "Save",
                icon: vm.isFavorite ? "heart.fill" : "heart",
                color: vm.isFavorite ? .red : .gray
            ) { vm.toggleFavorite() }
        }
    }

    @ViewBuilder
    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("Information")
            VStack(spacing: 0) {
                if let phone = vm.place.phone {
                    infoRow(icon: "phone.fill", label: "Phone", value: phone, color: .green) {
                        if let url = URL(string: "tel://\(phone.filter(\.isNumber))") {
                            UIApplication.shared.open(url)
                        }
                    }
                    Divider().padding(.leading, 56)
                }
                if let website = vm.place.website {
                    infoRow(icon: "globe", label: "Website", value: website, color: .blue) {
                        let s = website.hasPrefix("http") ? website : "https://\(website)"
                        if let url = URL(string: s) { UIApplication.shared.open(url) }
                    }
                    Divider().padding(.leading, 56)
                }
                infoRow(icon: "mappin.and.ellipse", label: "Address",
                        value: vm.place.address, color: .red, action: nil)
                Divider().padding(.leading, 56)
                infoRow(icon: "star.fill", label: "Rating",
                        value: "\(String(format: "%.1f", vm.place.rating)) / 5.0",
                        color: .yellow, action: nil)
            }
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
        }
    }

    @ViewBuilder
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("My Notes")
            if vm.noteText.isEmpty {
                Button { vm.showNoteEditor = true } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill").foregroundColor(.orange)
                        Text("Add a personal note about this place…")
                            .font(.subheadline).foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding(14)
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
                }
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    Text(vm.noteText).font(.subheadline)
                    if let msg = vm.noteSavedMessage {
                        Label(msg, systemImage: "checkmark.circle.fill")
                            .font(.caption).foregroundColor(.green)
                    }
                    HStack {
                        Spacer()
                        Button { vm.showNoteEditor = true } label: {
                            Label("Edit", systemImage: "pencil")
                                .font(.caption).fontWeight(.semibold).foregroundColor(.orange)
                        }
                    }
                }
                .padding(14)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
            }
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title).font(.headline).fontWeight(.semibold).padding(.bottom, 4)
    }

    private func actionButton(label: String, icon: String, color: Color,
                               action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 20)).foregroundColor(color)
                    .frame(width: 44, height: 44)
                    .background(color.opacity(0.12)).clipShape(Circle())
                Text(label)
                    .font(.caption2).fontWeight(.medium)
                    .foregroundColor(.primary).lineLimit(1)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func infoRow(icon: String, label: String, value: String,
                         color: Color, action: (() -> Void)?) -> some View {
        Button { action?() } label: {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .foregroundColor(color).font(.system(size: 16)).frame(width: 28)
                VStack(alignment: .leading, spacing: 2) {
                    Text(label).font(.caption).foregroundColor(.secondary)
                    Text(value)
                        .font(.subheadline)
                        .foregroundColor(action != nil ? .blue : .primary)
                        .lineLimit(2)
                }
                Spacer()
                if action != nil {
                    Image(systemName: "chevron.right").font(.caption).foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 14).padding(.vertical, 12)
        }
        .disabled(action == nil).buttonStyle(.plain)
    }

    private func errorBanner(_ message: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.red)
            Text(message).font(.caption).foregroundColor(.red)
            Spacer()
            Button { vm.errorMessage = nil } label: {
                Image(systemName: "xmark.circle.fill").foregroundColor(.gray)
            }
        }
        .padding(12)
        .background(Color.red.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10))
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

struct NoteEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var noteText: String
    let onSave: () -> Void

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                Text("Write anything useful — hours, tips, reminders…")
                    .font(.subheadline).foregroundColor(.secondary)
                    .padding(.horizontal).padding(.top, 8)
                TextEditor(text: $noteText)
                    .padding(10)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
                    .frame(minHeight: 180)
                Spacer()
            }
            .navigationTitle("My Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { onSave(); dismiss() }.fontWeight(.semibold)
                }
            }
        }
    }
}

#Preview {
    NavigationView {
        PlaceDetailView(
            place: Place(
                id: "preview-1",
                name: "McGill University",
                category: "Education",
                address: "845 Sherbrooke St W, Montreal",
                latitude: 45.5048,
                longitude: -73.5772,
                rating: 4.8,
                phone: "(514) 398-4455",
                website: "mcgill.ca"
            )
        )
    }
}
