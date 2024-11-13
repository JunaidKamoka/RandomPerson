//
//  Alert+Ext.swift
//  CoreML-StyleGAN
//
//  Created by MacBook on 13/08/2024.
//

import Foundation
import UIKit

extension UIViewController {
    
    func showAlert(withTitle title: String = "Hashtag", message: String? = nil, okayTitle: String = "OK", cancelTitle: String? = nil, okCall: @escaping () -> () = {}, cancelCall: @escaping () -> () = {}) {
        // print(title ?? appName)
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: okayTitle, style: .default, handler: { _ in
            okCall()
        }))
        if cancelTitle != nil {
            alert.addAction(UIAlertAction(title: cancelTitle, style: .cancel, handler: { _ in
                cancelCall()
            }))
        }
        
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    }
}
