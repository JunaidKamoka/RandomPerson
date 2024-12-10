//
//  Float+Ext.swift
//  RandomPerson
//
//  Created by MacBook on 10/12/2024.
//

import UIKit

extension Float {
    /// Rounds the Float to the specified number of decimal places.
    func rounded(toPlaces places: Int) -> Float {
        let divisor = pow(10.0, Float(places))
        return (self * divisor).rounded() / divisor
    }
}
