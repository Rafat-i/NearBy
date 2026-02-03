//
//  AuthService.swift
//  NearBy
//
//  Created by Rafat on 2026-02-03.
//


import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore

class AuthService: ObservableObject {
    
    static let shared = AuthService()
    
    @Published var currentUser: User?
    
    private let db = Firestore.firestore()
    
    func signUp(email: String, password: String, username: String, completion: @escaping (Result<User, Error>) -> Void) {
        
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                print(error.localizedDescription)
                return completion(.failure(error))
            }
            
            guard let user = result?.user else {
                return completion(.failure(SimpleError("No user found")))
            }
            
            let uid = user.uid
            let appUser = User(id: uid, email: email, username: username, favoriteCount: 0, visitedPlacesCount: 0)
            
            do {
                try self.db.collection("users").document(uid).setData(from: appUser) { error in
                    if let error = error {
                        print(error.localizedDescription)
                        return completion(.failure(error))
                    }
                    
                    DispatchQueue.main.async {
                        self.currentUser = appUser
                    }
                    
                    completion(.success(appUser))
                }
            } catch {
                completion(.failure(SimpleError("Unable to create Profile")))
            }
        }
    }
    
    func login(email: String, password: String, completion: @escaping (Result<User, Error>) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                completion(.failure(error))
            } else if let user = result?.user {
                
                self.fetchCurrentUser { res in
                    switch res {
                    case .failure(let failure):
                        completion(.failure(failure))
                        
                    case .success(let userObj):
                        if let appUser = userObj {
                            completion(.success(appUser))
                        } else {
                            let email = result?.user.email ?? "No Email Found"
                            let name = result?.user.displayName ?? "No Name Found"
                            let appUser = User(email: email, username: name)
                            
                            do {
                                try self.db.collection("users").document(user.uid).setData(from: appUser) { error in
                                    if let error = error {
                                        completion(.failure(error))
                                    }
                                    
                                    DispatchQueue.main.async {
                                        self.currentUser = appUser
                                    }
                                    completion(.success(appUser))
                                }
                            } catch {
                                completion(.failure(error))
                            }
                        }
                    }
                }
            }
        }
    }
    
    func fetchCurrentUser(completion: @escaping (Result<User?, Error>) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            DispatchQueue.main.async {
                self.currentUser = nil
            }
            return completion(.success(nil))
        }
        
        db.collection("users").document(uid).getDocument { snap, error in
            if let error = error { return completion(.failure(error)) }
            guard let snap = snap else { return completion(.success(nil)) }
            
            do {
                let user = try snap.data(as: User.self)
                DispatchQueue.main.async { self.currentUser = user }
                completion(.success(user))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    func updateUsername(username: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            return completion(.success(()))
        }

        db.collection("users").document(uid).updateData([
            "username": username
        ]) { error in
            if let error = error {
                return completion(.failure(error))
            } else {
                self.fetchCurrentUser { _ in
                    completion(.success(()))
                }
            }
        }
    }
    
    func updateUserStats(favoriteCount: Int? = nil, visitedPlacesCount: Int? = nil, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            return completion(.success(()))
        }
        
        var updateData: [String: Any] = [:]
        
        if let favoriteCount = favoriteCount {
            updateData["favoriteCount"] = favoriteCount
        }
        
        if let visitedPlacesCount = visitedPlacesCount {
            updateData["visitedPlacesCount"] = visitedPlacesCount
        }
        
        db.collection("users").document(uid).updateData(updateData) { error in
            if let error = error {
                return completion(.failure(error))
            } else {
                self.fetchCurrentUser { _ in
                    completion(.success(()))
                }
            }
        }
    }
    
    func signOut() -> Result<Void, Error> {
        do {
            try Auth.auth().signOut()
            DispatchQueue.main.async {
                self.currentUser = nil
            }
            return .success(())
        } catch {
            print("Sign out error: \(error.localizedDescription)")
            return .failure(error)
        }
    }
}
