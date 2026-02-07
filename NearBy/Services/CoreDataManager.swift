//
//  CoreDataManager.swift
//  NearBy
//
//  Created by Chadi Faour on 2026-02-07.
//

import Foundation
import CoreData

final class CoreDataManager {
    
    static let shared = CoreDataManager()
    
    private let persistentContainer: NSPersistentContainer
    
    var mainContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    var backgroundContext: NSManagedObjectContext {
        return persistentContainer.newBackgroundContext()
    }
    
    private init() {
        persistentContainer = NSPersistentContainer(name: "NearBy")
        
        let description = persistentContainer.persistentStoreDescriptions.first
        description?.shouldInferMappingModelAutomatically = true
        description?.shouldMigrateStoreAutomatically = true
        
        persistentContainer.loadPersistentStores { storeDescription, error in
        if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        
        persistentContainer.viewContext.automaticallyMergesChangesFromParent = true
        persistentContainer.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
    
    func saveContext() throws {
        let context = mainContext
        if context.hasChanges {
            try context.save()
        }
    }
    
    func save(context: NSManagedObjectContext) throws {
        if context.hasChanges {
            try context.save()
        }
    }
    
    func saveContextAsync(completion: ((Result<Void, Error>) -> Void)? = nil) {
        let context = mainContext
        
        context.perform {
            do {
                if context.hasChanges {
                    try context.save()
                }
                completion?(.success(()))
            } catch {
                completion?(.failure(error))
            }
        }
    }
    
    func create<T: NSManagedObject>(_ entityType: T.Type) -> T {
        return T(context: mainContext)
    }
    
    func fetch< T: NSManagedObject>(_ entityType: T.Type, predicate: NSPredicate? = nil, sortDescriptors: [NSSortDescriptor]? = nil, fetchLimit: Int? = nil)
    throws -> [T] {
        let request = NSFetchRequest<T>(entityName: String(describing: entityType))
        request.predicate = predicate
        request.sortDescriptors = sortDescriptors
        
        if let limit = fetchLimit {
            request.fetchLimit = limit
        }
        
        return try mainContext.fetch(request)
    }
    
    func fetchAsync<T: NSManagedObject>(_ entityType: T.Type,
                                        predicate: NSPredicate? = nil,
                                        sortDescriptors: [NSSortDescriptor]? = nil,
                                        fetchLimit: Int? = nil,
                                        completion: @escaping (Result<[T], Error>) -> Void) {
        
        let context = backgroundContext
        context.perform{
            let request = NSFetchRequest<T>(entityName: String(describing: entityType))
            request.predicate = predicate
            request.sortDescriptors = sortDescriptors
            
            if let limit = fetchLimit {
                request.fetchLimit = limit
            }
            
            do {
                let results = try context.fetch(request)
                completion(.success(results))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    func fetchByID<T: NSManagedObject>(_ entityType: T.Type, objectID: NSManagedObjectID) throws -> T? {
        return try mainContext.existingObject(with: objectID) as? T
    }
    
    func delete(_ object: NSManagedObject) {
        mainContext.delete(object)
    }
    
    func deleteAll(_ objects: [NSManagedObject]) {
        objects.forEach { mainContext.delete($0)}
    }
    
    func batchDelete<T: NSManagedObject>(_ entityType: T.Type, predicate: NSPredicate? = nil) throws {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: String(describing: entityType))
        fetchRequest.predicate = predicate
        
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        batchDeleteRequest.resultType = .resultTypeObjectIDs
        
        let result = try mainContext.execute(batchDeleteRequest) as? NSBatchDeleteResult
        
        guard let objectIDArray = result?.result as? [NSManagedObjectID] else { return }
        
        let changes = [NSDeletedObjectsKey: objectIDArray]
        NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [mainContext])
    }
    
    func performBackgroundTask(_ operation: @escaping (NSManagedObjectContext) throws -> Void) throws {
        let context = backgroundContext
        
        var thrownError: Error?
        
        context.performAndWait {
            do {
                try operation(context)
                if context.hasChanges {
                    try context.save()
                }
            } catch {
                thrownError = error
            }
        }
        if let error = thrownError {
            throw error
        }
    }
    
    func performBackgroundTaskAsync(_ operation: @escaping (NSManagedObjectContext) throws -> Void, completion: @escaping (Result<Void, Error>) -> Void) {
        let context = backgroundContext
        
        context.perform {
            do {
                try operation(context)
                if context.hasChanges {
                    try context.save()
                }
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    func count<T: NSManagedObject>(_ entityType: T.Type, predicate: NSPredicate? = nil) throws -> Int {
        let request = NSFetchRequest<T>(entityName: String(describing: entityType))
        request.predicate = predicate
        return try mainContext.count(for: request)
    }
    
    func exists<T: NSManagedObject>(_ entityType: T.Type, predicate: NSPredicate) -> Bool {
        do {
            let count = try count(entityType, predicate: predicate)
            return count > 0
        } catch {
            return false
        }
    }
    
    func resetAllData() throws {
        let entities = persistentContainer.managedObjectModel.entities
        
        for entity in entities {
            guard let entityName = entity.name else { continue }
            
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
            let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            
            try mainContext.execute(batchDeleteRequest)
        }
        
        try saveContext()
    }
    
    func createChildContext(concurrencyType: NSManagedObjectContextConcurrencyType = .mainQueueConcurrencyType) -> NSManagedObjectContext {
        let childContext = NSManagedObjectContext(concurrencyType: concurrencyType)
        childContext.parent = mainContext
        return childContext
    }
}

extension CoreDataManager {
    
    func fetchFirst<T: NSManagedObject>(_ entityType: T.Type, predicate: NSPredicate? = nil) throws -> T? {
        return try fetch(entityType, predicate: predicate, fetchLimit: 1).first
    }
    
    func fetchAll<T: NSManagedObject>(_ entityType: T.Type) throws -> [T] {
        return try fetch(entityType)
    }
}
