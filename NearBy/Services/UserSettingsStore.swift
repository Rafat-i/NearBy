//
//  UserSettingsStore.swift
//  NearBy
//
//  Created by Rafat on 2026-03-09.
//

import Foundation
import CoreData
import Combine

@MainActor
final class UserSettingsStore: ObservableObject {
    static let shared = UserSettingsStore()

    @Published var defaultRadius: Double = 9000
    @Published var mapStyle: String = "standard"
    @Published var units: String = "metric"

    private let coreData = CoreDataManager.shared
    private var loadedUserId: String?

    private init() {}

    func loadForCurrentUser() {
        guard let userId = AuthService.shared.currentUser?.id else {
            loadedUserId = nil
            defaultRadius = 9000
            mapStyle = "standard"
            units = "metric"
            return
        }

        guard loadedUserId != userId else { return }
        loadedUserId = userId

        let predicate = NSPredicate(format: "id == %@", userId)
        if let prefs = try? coreData.fetchFirst(UserPreferences.self, predicate: predicate) {
            defaultRadius = prefs.defaultRadius > 0 ? prefs.defaultRadius : 9000
            mapStyle = prefs.mapStyle ?? "standard"
            units = prefs.units ?? "metric"
            return
        }

        let prefs = coreData.create(UserPreferences.self)
        prefs.id = userId
        prefs.defaultRadius = 9000
        prefs.mapStyle = "standard"
        prefs.units = "metric"
        try? coreData.saveContext()
    }

    func save(defaultRadius: Double, mapStyle: String, units: String) {
        guard let userId = AuthService.shared.currentUser?.id else { return }

        self.defaultRadius = defaultRadius
        self.mapStyle = mapStyle
        self.units = units

        let predicate = NSPredicate(format: "id == %@", userId)
        let prefs = (try? coreData.fetchFirst(UserPreferences.self, predicate: predicate))
            ?? coreData.create(UserPreferences.self)

        prefs.id = userId
        prefs.defaultRadius = defaultRadius
        prefs.mapStyle = mapStyle
        prefs.units = units

        let userPredicate = NSPredicate(format: "userId == %@", userId)
        if let userEntity = try? coreData.fetchFirst(UserEntity.self, predicate: userPredicate) {
            prefs.user = userEntity
        }

        try? coreData.saveContext()
    }
}

