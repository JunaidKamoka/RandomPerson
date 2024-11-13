//
//  Loader+Ext.swift
//  CoreML-StyleGAN
//
//  Created by MacBook on 13/08/2024.
//

import Foundation
import NVActivityIndicatorView
import UIKit
import NVActivityIndicatorViewExtended

extension UIViewController: NVActivityIndicatorViewable {
    func showLoader(message: String = "") {
        DispatchQueue.main.async {
            let size = CGSize(width: 40, height: 40)
            self.startAnimating(size,
            message: message,
            messageFont: UIFont.boldSystemFont(ofSize: 13),
            type: NVActivityIndicatorType.ballRotateChase,
            color: .white,
            padding: 0,
            displayTimeThreshold: 0,
            minimumDisplayTime: 0)
        }
    }
    /*
     Hide loader will from remove its superview and hide loader from current view
     */
    func hideLoader() {
        DispatchQueue.main.async {
            self.stopAnimating()
        }
    }
}
