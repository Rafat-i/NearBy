//
//  Validators.swift
//  NearBy
//
//  Created by Rafat on 2026-02-03.
//


import Foundation

enum Validators {
    static func isValidEmail(_ email: String) -> Bool {
        let pattern = #"^\S+@\S+\.\S+$"#
        return email.range(of: pattern, options: .regularExpression) != nil
    }
    
    static func isValidPassword(_ password: String) -> Bool {
        password.count >= 6
    }
}

struct SimpleError: Error {
    let message: String
    
    init(_ message: String) {
        self.message = message
    }
    
    var localizedDescription: String { message }
}
