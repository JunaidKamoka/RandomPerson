//
//  IAPViewModel.swift
//  Hashtag Generator
//
//  Created by Junaid  Kamoka on 18/03/2024.
//

import Foundation
import SwiftyStoreKit
import UIKit

class IAPViewModel: NSObject {
    
    static var shared = IAPViewModel()
        
    var isPurchased: Bool? = false {
        didSet {
            
            UserDefaults.standard.set(self.isPurchased, forKey: "isPurchased")
            
            let topVC = UIApplication.getTopViewController()
            
            if topVC is IAPVC && isPurchased == true {
                topVC?.dismiss(animated: true)
            }
        }
    }
    
    func canProceed() -> Bool {
        
        guard IAPViewModel.shared.isPurchased != true else {return true}
        
        let topVC = UIApplication.getTopViewController()
        let iapVC = topVC?.storyboard?.instantiateViewController(withIdentifier: IAPVC.className) as! IAPVC
        iapVC.modalPresentationStyle = .fullScreen
        
//#if DEBUG || TESTFLIGHT
//        return true
//#endif
        let currentTries = UserDefaults.standard.integer(forKey: "freeTries")
        if currentTries > 1 {
            
            topVC?.present(iapVC, animated: true)
            return false
        } else {
            
            UserDefaults.standard.set(currentTries+1, forKey: "freeTries")
            return true
        }
    }
    
    func receiptValidation(isLoader: Bool) {
        
        verifyReceipt { result in
            
            switch result {
            case .success(let receipt):
                
                if self.verifyProduct(receipt: receipt, productID: .weeklySubs) == true {
                    
                    IAPViewModel.shared.isPurchased = true
                } else if self.verifyProduct(receipt: receipt, productID: .monthlySub) == true {
                    
                    IAPViewModel.shared.isPurchased = true
                } else if self.verifyProduct(receipt: receipt, productID: .yearlySub) == true {
                    
                    IAPViewModel.shared.isPurchased = true
                } else {
                    
                    IAPViewModel.shared.isPurchased = false
                }
                
            case .error:
                //                self.showAlert(self.alertForVerifyReceipt(result))
                print("Receipt Verify Error")
            }
        }
    }
    
    private func verifyProduct(receipt: ReceiptInfo, productID: ProductObjs) -> Bool {
        
        let purchaseResult = SwiftyStoreKit.verifySubscription(
            ofType: .autoRenewable,
            productId: productID.rawValue,
            inReceipt: receipt)
        
        return verifySub(purchaseResult)
    }
    
    private func verifySub(_ result: VerifySubscriptionResult) -> Bool {
        
        switch result {
            
        case .purchased(let purchasedObj):
            
            print("Product is valid until \(purchasedObj)")
            
            self.isPurchased = true
            return true//"Product is valid until \(expiryDate)"
            //            return alertWithTitle("Product is purchased", message: "Product is valid until \(expiryDate)")
            
        case .expired(let expiryDate):
            
            print("Product is expired since \(expiryDate)")
            
            return false//"Product is expired since \(expiryDate)"
            //            return alertWithTitle("Product expired", message: "Product is expired since \(expiryDate)")
            
        case .notPurchased:
            print("This product has never been purchased")
            return false//"This product has never been purchased"
            //            return alertWithTitle("Not purchased", message: "This product has never been purchased")
        }
    }
    
    private func verifyReceipt(completion: @escaping (VerifyReceiptResult) -> Void) {
        
        var appleValidator = AppleReceiptValidator()
        
#if DEBUG
        appleValidator = AppleReceiptValidator(service: .sandbox, sharedSecret: "31bfe776724245ccb3ce9f2d1aeb9999")
#else
        appleValidator = AppleReceiptValidator(service: .production, sharedSecret: "31bfe776724245ccb3ce9f2d1aeb9999")
#endif
        SwiftyStoreKit.verifyReceipt(using: appleValidator, completion: completion)
    }
}

