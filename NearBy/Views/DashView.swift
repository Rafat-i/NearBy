//
//  DashView.swift
//  NearBy
//
//  Created by Chadi Faour on 2026-03-08.
//

import SwiftUI
import CoreData
import Combine

@MainActor
class DashboardViewModel: ObservableObject {
    @Published var favouriteCount: Int = 0
    @Published var recentPlaces: [PlaceEntity] = []
    @Published var totalVisited: Int = 0
    @Published var userName: String = "Explorer"
    
    private let coreData = CoreDataManager.shared
    
    init() { load() }
    
    func load() {
        userName = AuthService.shared.currentUser?.username ?? "Explorer"

        guard let userId = AuthService.shared.currentUser?.id else {
            totalVisited = 0
            favouriteCount = 0
            recentPlaces = []
            return
        }

        let predicate = NSPredicate(format: "userId == %@", userId)
        let allPlaces = (try? coreData.fetch(PlaceEntity.self, predicate: predicate)) ?? []
        totalVisited = allPlaces.filter { $0.lastViewed != nil }.count
        favouriteCount = allPlaces.filter { $0.isFavorite }.count

        AuthService.shared.updateUserStats(
            favoriteCount: favouriteCount,
            visitedPlacesCount: totalVisited
        ) { _ in }
        
        recentPlaces = allPlaces
            .filter { $0.lastViewed != nil }
            .sorted {($0.lastViewed ?? .distantPast) > ($1.lastViewed ?? .distantPast)}
            .prefix(5).map { $0 }
    }
}


struct DashView: View {
    @StateObject private var vm = DashboardViewModel()
    
    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good Morning,"
        case 12..<17: return "Good Afternoon,"
        default: return "Good Evening,"
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(greeting)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(vm.userName)
                            .font(.largeTitle).fontWeight(.bold)
                    }
                    .padding(.top, 8)
                    
                    HStack(spacing: 12) {
                        StatCard(value: "\(vm.totalVisited)", label: "Visited", icon: "mappin.circle.fill", color: .blue)
                        StatCard(value: "\(vm.favouriteCount)", label: "Favourites", icon: "heart.fill", color: .red)
                        StatCard(value: "\(vm.recentPlaces.count)", label: "Recent", icon: "clock.fill", color: .orange)
                    }
                    
                    if !vm.recentPlaces.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Recent Viewed")
                                .font(.headline).fontWeight(.semibold)
                            
                            VStack(spacing: 10) {
                                ForEach(vm.recentPlaces, id: \.id) { entity in
                                    NavigationLink(destination:
                                                    PlaceDetailView(place: makePlace(from: entity))
                                        .onDisappear { vm.load() }
                                    ) {
                                        RecentRow(entity: entity)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    } else {
                        VStack(spacing: 12) {
                            Image(systemName: "map")
                                .font(.system(size: 44))
                                .foregroundColor(.secondary.opacity(0.4))
                            Text("No places visited yet")
                                .font(.subheadline).foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)
                    }
                    Spacer(minLength: 32)
                }
                .padding(.horizontal)
            }
            .navigationTitle("NearBy")
            .navigationBarTitleDisplayMode(.large)
            .onAppear { vm.load() }
        }
    }
    private func makePlace(from entity: PlaceEntity) -> Place {
        Place(
            id: entity.id,
            name: entity.name ?? "",
            category: entity.placeCategory ?? "",
            address: entity.address ?? "",
            latitude: entity.latitude,
            longitude: entity.longitude,
            rating: entity.rating,
            phone: entity.phone,
            photoURL: entity.photoUrl,
            website: entity.website
        )
    }
}

struct StatCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)
                .frame(width: 38, height: 38)
                .background(color.opacity(0.12))
                .clipShape(Circle())
            Text(value)
                .font(.title3).fontWeight(.bold)
            Text(label)
                .font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
    }
}

struct RecentRow: View {
    let entity: PlaceEntity
    
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: categoryIcon(entity.placeCategory ?? ""))
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
                .padding(10)
                .background(categoryColor(entity.placeCategory ?? "").gradient, in: .circle)
            
            VStack(alignment: .leading, spacing: 3) {
                Text(entity.name ?? "")
                    .font(.subheadline).fontWeight(.semibold)
                    .foregroundColor(.primary).lineLimit(1)
                Text(entity.address ?? "")
                    .font(.caption).foregroundColor(.secondary).lineLimit(1)
            }
            Spacer()
            
            HStack(spacing: 4) {
                Image(systemName: "chevron.right").font(.caption2).foregroundColor(.secondary)
            }
        }
        .padding(14)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func categoryIcon(_ category: String) -> String {
        switch category.lowercased() {
        case "education":    return "graduationcap.fill"
        case "parks":        return "tree.fill"
        case "entertainment": return "theatermasks.fill"
        case "restaurants":  return "fork.knife"
        case "cafes":        return "cup.and.saucer.fill"
        case "shopping":      return "cart.fill"
        case "libraries":    return "book.fill"
        default:             return "mappin.circle.fill"
        }
    }
    
    private func categoryColor(_ category: String) -> Color {
        switch category.lowercased() {
        case "education":   return .orange
        case "parks":       return .green
        case "entertainment": return .purple
        case "restaurants": return .red
        case "cafes":       return .brown
        case "shopping":     return .pink
        case "libraries":   return .blue
        default:            return .gray
        }
    }
}

#Preview {
    DashView()
}
