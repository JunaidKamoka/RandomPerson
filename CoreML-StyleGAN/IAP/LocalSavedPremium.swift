//
//  LocalSavedPremium.swift
//  Hashtag Generator
//
//  Created by MacBook on 12/08/2024.
//


import Foundation

struct LocalSavedPremium {
    
    static func get(complition: @escaping ([Premium])->Void) {
        
        let defaults = UserDefaults.standard
        
        if let data = defaults.data(forKey: "premium2") {
            
            let array = try! PropertyListDecoder().decode([Premium].self, from: data)
            complition(array)
        }
    }
    
    static func save(_ premium: [Premium]) {
        
        if let data = try? PropertyListEncoder().encode(premium) {
            UserDefaults.standard.set(data, forKey: "premium2")
        }
    }
    
}
