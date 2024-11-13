//
//  URL+Ext.swift
//  CoreML-StyleGAN
//
//  Created by MacBook on 13/08/2024.
//

import Foundation
import UIKit

extension URL {
    
    static func privacy() -> URL {
        
        return URL(string: "https://appchunks.com/#privacy")!
    }
    
    static func terms() -> URL {
        
        return URL(string: "https://appchunks.com/#terms")!
    }
    
    static func openUrl(_ url: URL) {
        
        if #available(iOS 10.0, *) {
            
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else {
            
            UIApplication.shared.openURL(url)
        }
    }
}
