//
//  PlaceSyncCoordinator.swift
//  NearBy
//
//  Created by Rafat on 2026-03-07.
//

import Foundation
import CoreData
import Combine

@MainActor
final class PlaceSyncCoordinator: ObservableObject {
    static let shared = PlaceSyncCoordinator()

    private let sync = PlaceFirebaseSync()
    private let coreData = CoreDataManager.shared

    private var isApplyingRemoteChanges = false

    private var activeUserId: String?

    private init() {}

    func startIfNeeded(userId: String) {
        guard !userId.isEmpty else { return }
        guard activeUserId != userId else { return }
        activeUserId = userId

        sync.startListeningForUser(
            userId: userId,
            context: coreData.mainContext
        ) { [weak self] applying in
            self?.isApplyingRemoteChanges = applying
        } onRemoteApplied: {
        }
    }

    func stop() {
        activeUserId = nil
        sync.stopListening()
    }

    func saveAndSyncMainContext() throws {
        let context = coreData.mainContext

        var changedPlaceIDs: [String] = []
        var deletedIDs: [String] = []

        var saveError: Error?
        context.performAndWait {
            let inserted = context.insertedObjects.compactMap { $0 as? PlaceEntity }
            let updated = context.updatedObjects.compactMap { $0 as? PlaceEntity }
            let deleted = context.deletedObjects.compactMap { $0 as? PlaceEntity }

            deletedIDs = deleted.compactMap { $0.id }
            changedPlaceIDs = (inserted + updated).compactMap { $0.id }.filter { !$0.isEmpty }

            if let userId = activeUserId {
                (inserted + updated)
                    .filter { $0.userId == nil }
                    .forEach { $0.userId = userId }
            }

            do {
                if context.hasChanges {
                    try context.save()
                }
            } catch {
                saveError = error
            }
        }

        if let saveError {
            throw saveError
        }

        guard !isApplyingRemoteChanges else { return }
        guard let userId = activeUserId, !userId.isEmpty else { return }

        deletedIDs.forEach { sync.pushDelete(placeId: $0, forUserId: userId) }

        for placeId in changedPlaceIDs {
            var place: PlaceEntity?
            context.performAndWait {
                let request: NSFetchRequest<PlaceEntity> = PlaceEntity.fetchRequest()
                request.fetchLimit = 1
                request.predicate = NSPredicate(format: "id == %@", placeId)
                place = try? context.fetch(request).first
            }

            guard let place else { continue }

            let notes = (place.userNotes ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            let shouldExistRemotely = place.isFavorite || !notes.isEmpty

            if shouldExistRemotely {
                sync.pushUpsert(place: place, forUserId: userId)
            } else {
                sync.pushDelete(placeId: placeId, forUserId: userId)
            }
        }
    }
}

