//
//  PremiumProducts.swift
//  Hashtag Generator
//
//  Created by Junaid  Kamoka on 18/03/2024.
//

import Foundation
import StoreKit

public enum ProductObjs: String {
    
    case weeklySubs = "aspersion.weekly"
    case monthlySub = "aspersion.monthly"
    case yearlySub = "aspersion.yearly"
}

public struct PremiumProducts {
    
    static let weeklySub = "aspersion.weekly"
    static let monthlySub = "aspersion.monthly"
    static let yearlySub = "aspersion.yearly"
    
    static let productIDs: Set<String> = [PremiumProducts.weeklySub, PremiumProducts.monthlySub, PremiumProducts.yearlySub]
}
