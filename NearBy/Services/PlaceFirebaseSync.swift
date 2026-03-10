//
//  PlaceFirebaseSync.swift
//  NearBy
//
//  Created by Rafat on 2026-03-07.
//

import Foundation
import FirebaseFirestore
import CoreData


final class PlaceFirebaseSync {
    private var db: Firestore { Firestore.firestore() }
    private var listener: ListenerRegistration?

    private var currentUserId: String?

    deinit {
        listener?.remove()
    }

    func stopListening() {
        listener?.remove()
        listener = nil
    }

    
    func startListeningForUser(
        userId: String,
        context: NSManagedObjectContext,
        onApplyingRemote: @escaping (Bool) -> Void,
        onRemoteApplied: @escaping () -> Void
    ) {
        stopListening()

        currentUserId = userId

        let collection = db
            .collection("users")
            .document(userId)
            .collection("userPlaces")

        listener = collection.addSnapshotListener { [weak self] snapshot, error in
            guard let self else { return }

            if let error {
                print("Firestore listen error (userPlaces):", error)
            }

            guard let snapshot else { return }

            DispatchQueue.main.async {
                onApplyingRemote(true)
            }

            context.perform {
                for change in snapshot.documentChanges {
                    let doc = change.document
                    let docID = doc.documentID

                    switch change.type {
                    case .added, .modified:
                        self.upsertPlace(
                            docID: docID,
                            data: doc.data(),
                            into: context
                        )
                    case .removed:
                        self.deletePlace(
                            docID: docID,
                            from: context
                        )
                    }
                }

                do {
                    try context.save()
                } catch {
                    print("Core Data save error while applying remote place changes:", error)
                }

                DispatchQueue.main.async {
                    onApplyingRemote(false)
                    onRemoteApplied()
                }
            }
        }
    }

    func pushUpsert(place: PlaceEntity, forUserId userId: String) {
        guard let placeId = place.id, !placeId.isEmpty else { return }

        let ref = db
            .collection("users")
            .document(userId)
            .collection("userPlaces")
            .document(placeId)

        ref.setData(serialize(place: place), merge: true)
    }

    func pushDelete(placeId: String, forUserId userId: String) {
        guard !placeId.isEmpty else { return }

        db.collection("users")
            .document(userId)
            .collection("userPlaces")
            .document(placeId)
            .delete()
    }


    private func upsertPlace(
        docID: String,
        data: [String: Any],
        into context: NSManagedObjectContext
    ) {
        let request: NSFetchRequest<PlaceEntity> = PlaceEntity.fetchRequest()
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "id == %@", docID)

        let entity = (try? context.fetch(request).first) ?? PlaceEntity(context: context)

        entity.id = docID
        if let userId = currentUserId {
            entity.userId = userId
        }
        entity.name = data["name"] as? String
        entity.address = data["address"] as? String
        entity.placeCategory = data["placeCategory"] as? String
        entity.phone = data["phone"] as? String
        entity.website = data["website"] as? String
        entity.photoUrl = data["photoUrl"] as? String

        if let rating = data["rating"] as? Double {
            entity.rating = rating
        }

        if let lat = data["latitude"] as? Double {
            entity.latitude = lat
        }

        if let lon = data["longitude"] as? Double {
            entity.longitude = lon
        }

        if let isFav = data["isFavorite"] as? Bool {
            entity.isFavorite = isFav
        }

        if let notes = data["userNotes"] as? String {
            entity.userNotes = notes
        }

        if let ts = data["lastViewed"] as? Timestamp {
            entity.lastViewed = ts.dateValue()
        }
    }

    private func deletePlace(
        docID: String,
        from context: NSManagedObjectContext
    ) {
        let request: NSFetchRequest<PlaceEntity> = PlaceEntity.fetchRequest()
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "id == %@", docID)

        if let entity = try? context.fetch(request).first {
            entity.isFavorite = false
            entity.userNotes = nil
        }
    }


    private func serialize(place: PlaceEntity) -> [String: Any] {
        var out: [String: Any] = [
            "name": place.name ?? "",
            "address": place.address ?? "",
            "placeCategory": place.placeCategory ?? "",
            "latitude": place.latitude,
            "longitude": place.longitude,
            "rating": place.rating,
            "isFavorite": place.isFavorite
        ]

        if let phone = place.phone {
            out["phone"] = phone
        }

        if let website = place.website {
            out["website"] = website
        }

        if let photo = place.photoUrl {
            out["photoUrl"] = photo
        }

        if let notes = place.userNotes, !notes.isEmpty {
            out["userNotes"] = notes
        } else {
            out["userNotes"] = FieldValue.delete()
        }

        if let lastViewed = place.lastViewed {
            out["lastViewed"] = lastViewed
        }

        return out
    }
}

