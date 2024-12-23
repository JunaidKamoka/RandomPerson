//
//  IAPVC.swift
//  Hashtag Generator
//
//  Created by Junaid  Kamoka on 18/03/2024.
//

import Foundation
import UIKit
import StoreKit
import SwiftyStoreKit

class PremiumTVC: UITableViewCell {
    
    @IBOutlet weak var titleLbl: UILabel!
    @IBOutlet weak var descPriceLbl: UILabel!
    @IBOutlet weak var priceLbl: UILabel!
    @IBOutlet weak var durationLbl: UILabel!
    @IBOutlet weak var discountLbl: UILabel!
    @IBOutlet weak var mainView: UIView!
    @IBOutlet weak var bgImgView: UIImageView!
}

struct Premium: Codable {
    
    var title: String!
    var priceDesc: String!
    var currancy: String!
    var productID: String!
    var price: Float? = 0.0
    var isSelected: Bool? = false
}

class IAPVC: UIViewController {
    
    //    @IBOutlet weak var sliderCV: UICollectionView!
    @IBOutlet weak var premTV: UITableView!
    @IBOutlet weak var btnBuyOutlet: UIButton!
    @IBOutlet weak var freeTrialLbl: UILabel!
    
    private var productsArr: [Premium]? {
        
        didSet {
            
            DispatchQueue.main.async {
                
                self.premTV.reloadData()
            }
        }
    }
    
    //    var centeredCollectionViewFlowLayout: CenteredCollectionViewFlowLayout!
    let cellPercentWidth: CGFloat = 0.6
    private var currentSliderIndex: IndexPath!
    
    var totalElements = 10000
    
    private var sliderTimer = Timer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.currentSliderIndex = IndexPath(item: 2, section: 0)
        self.tvSetup()
        self.getProducts()
    }
    
    private func getProducts() {
        
        LocalSavedPremium.get { premiums in
            
            self.productsArr = premiums
        }
        
        DispatchQueue.main.async {
            
            SwiftyStoreKit.retrieveProductsInfo([PremiumProducts.weeklySub,PremiumProducts.yearlySub]) { result in
                
                print(result)
                
                if result.error != nil {
                    self.showAlert(message: "Something Went wrong!", okayTitle: "Ok", cancelCall: {
                        self.dismiss(animated: true)
                    })
                    return
                }
                
                let products = result.retrievedProducts
                
                var productsFormated = [Premium]()
                
                if let prodWeekly = products.first(where: {$0.productIdentifier == PremiumProducts.weeklySub}) {
                    productsFormated.append(Premium(title: prodWeekly.localizedTitle, priceDesc: prodWeekly.localizedPrice, currancy: prodWeekly.priceLocale.currencySymbol, productID: prodWeekly.productIdentifier, price: prodWeekly.price.floatValue, isSelected: false))
                }
                
                if let prodYearly = products.first(where: {$0.productIdentifier == PremiumProducts.yearlySub}) {
                    productsFormated.append(Premium(title: prodYearly.localizedTitle, priceDesc: prodYearly.localizedPrice, currancy: prodYearly.priceLocale.currencySymbol, productID: prodYearly.productIdentifier, price: prodYearly.price.floatValue, isSelected: true))
                    self.btnBuyOutlet.setTitle("Start for Free", for: .normal)
                    UIView.transition(with: self.freeTrialLbl,
                                      duration: 0.5, // Animation duration
                                      options: .transitionCrossDissolve, // Smooth fade effect
                                      animations: {
                        self.freeTrialLbl.text = "3 days Free trial - then pay \(prodYearly.localizedPrice ?? "")/year"
                    },
                                      completion: nil)
                }
                
                print(self.productsArr as Any)
                
                if self.productsArr?.count == 0 || self.productsArr == nil {
                    
                    self.productsArr = productsFormated
                }
                
                LocalSavedPremium.save(productsFormated)
            }
        }
    }
    
    @IBAction func btnBuy() {
        
        guard Reachability.isConnectedToNetwork() == true else {
            
            self.showAlert(message: "Please Check your Internet Connection!")
            return
        }
        
        self.purchaseItem()
    }
    
    @IBAction func btnPrivacy() {
        
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(URL.privacy(), options: [:], completionHandler: nil)
        } else {
            UIApplication.shared.openURL(URL.privacy())
        }
    }
    
    @IBAction func btnTerms() {
        
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(URL.terms(), options: [:], completionHandler: nil)
        } else {
            UIApplication.shared.openURL(URL.terms())
        }
    }
    
    @IBAction func btnRestore() {
        
        self.restorePurchase()
    }
    
    @IBAction func btnClose() {
        
        self.dismiss(animated: true)
    }
    
}

// IAP Work
extension IAPVC {
    
    private func purchaseItem() {
        
        self.showLoader()
        
        guard let prodID = self.productsArr?.first(where: {$0.isSelected == true})?.productID else {
            
            self.hideLoader()
            self.showAlert(message: "Something went wrong!")
            ;return}
        
        SwiftyStoreKit.purchaseProduct(prodID, quantity: 1, atomically: true) { result in
            
            self.hideLoader()
            
            switch result {
                
            case .success(let purchase):
                
                print("Purchase Success: \(purchase.productId)")
                
                self.dismiss(animated: true) {
                    
                    IAPViewModel.shared.isPurchased = true
                }
                
            case .error(let error):
                
                switch error.code {
                case .unknown: print("Unknown error. Please contact support")
                case .clientInvalid: print("Not allowed to make the payment")
                case .paymentCancelled: break
                case .paymentInvalid: print("The purchase identifier was invalid")
                case .paymentNotAllowed: print("The device is not allowed to make the payment")
                case .storeProductNotAvailable: print("The product is not available in the current storefront")
                case .cloudServicePermissionDenied: print("Access to cloud service information is not allowed")
                case .cloudServiceNetworkConnectionFailed: print("Could not connect to the network")
                case .cloudServiceRevoked: print("User has revoked permission to use this cloud service")
                default: print((error as NSError).localizedDescription)
                }
                
                self.showAlert(withTitle: "Failed to Purchase", message: "", okayTitle: "OK", cancelTitle: nil) {
                    
                } cancelCall: {
                    
                    print("cancel")
                }
                
            case .deferred(purchase: let purchase):
                print("purchase: ", purchase)
            }
        }
    }
    
    private func restorePurchase() {
        
        self.showLoader()
        
        SwiftyStoreKit.restorePurchases(atomically: true) { results in
            
            self.hideLoader()
            
            for purchase in results.restoredPurchases {
                
                let downloads = purchase.transaction.downloads
                if !downloads.isEmpty {
                    SwiftyStoreKit.start(downloads)
                } else if purchase.needsFinishTransaction {
                    // Deliver content from server, then:
                    SwiftyStoreKit.finishTransaction(purchase.transaction)
                }
            }
            
            if results.restoreFailedPurchases.count > 0 {
                print("Restore Failed: \(results.restoreFailedPurchases)")
                self.showAlert(withTitle: "Failed to Purchase")
                
            } else if results.restoredPurchases.count > 0 {
                
                print("Restore Success: \(results.restoredPurchases)")
                self.showAlert(withTitle: "Restored Successfull!",okCall: {
                    
                    IAPViewModel.shared.isPurchased = true
                    
                    self.dismiss(animated: true) {
                        
                        IAPViewModel.shared.receiptValidation(isLoader: false)
                    }
                }, cancelCall:  {
                    print("cancel")
                })
                
            } else {
                print("Nothing to Restore")
                self.showAlert(withTitle: "Nothing to Restore!")
            }
        }
    }
    
}


// TV Work
extension IAPVC: UITableViewDelegate, UITableViewDataSource {
    
    private func tvSetup() {
        
        self.premTV.delegate = self
        self.premTV.dataSource = self
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        self.productsArr?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: PremiumTVC.className, for: indexPath) as? PremiumTVC ?? PremiumTVC()
        
        print("row", indexPath.row)
        
        let currentProduct = self.productsArr?[indexPath.row]
        cell.titleLbl.text = currentProduct?.title
                
        if currentProduct?.productID == PremiumProducts.weeklySub {
            
            cell.priceLbl.text = (currentProduct?.priceDesc ?? "")//"\(currentProduct?.currancy ?? "") \(((currentProduct?.price ?? 0.0)/7).rounded(toPlaces: 1))"
//            cell.durationLbl.text = "per day"
            cell.descPriceLbl.text = "\(currentProduct?.currancy ?? "") \(((currentProduct?.price ?? 0.0)/7).rounded(toPlaces: 1))" + " per day"
            cell.discountLbl.text = "Save 60%"
            
            cell.durationLbl.text = "Paid Weekly"
        } else if currentProduct?.productID == PremiumProducts.yearlySub {
            
            cell.priceLbl.text = (currentProduct?.priceDesc ?? "")
            cell.durationLbl.text = "Paid Yearly"
            cell.descPriceLbl.text = "\(currentProduct?.currancy ?? "") \(((currentProduct?.price ?? 0.0)/12).rounded(toPlaces: 1))" + " per month"
            cell.discountLbl.text = "Save 70%"
        }
        
        if currentProduct?.isSelected == true {
            
            cell.bgImgView.image = UIImage(resource: .selectedPlanBG)
        } else {
            
            cell.bgImgView.image = UIImage(resource: .unselectedPlanBG)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let prevIndex = self.productsArr?.firstIndex(where: {$0.isSelected == true}) ?? 0
        self.productsArr?[prevIndex].isSelected = false
        
        self.productsArr?[indexPath.row].isSelected = true
        self.premTV.reloadData()
        
        //        self.btnBuyOutlet.setTitle("Continue", for: .normal)
        
        if self.productsArr?[indexPath.row].productID == PremiumProducts.yearlySub {
            
            self.btnBuyOutlet.setTitle("Start for Free", for: .normal)
            self.freeTrialLbl.isHidden = false
            print("3day")
            
            UIView.transition(with: self.freeTrialLbl,
                              duration: 0.5, // Animation duration
                              options: .transitionCrossDissolve, // Smooth fade effect
                              animations: {
                self.freeTrialLbl.text = "3 days Free trial - then pay \(self.productsArr?[indexPath.row].priceDesc ?? "0")/year"
            },
                              completion: nil)
            
        } else {
            
            self.btnBuyOutlet.setTitle("Continue", for: .normal)
            self.freeTrialLbl.isHidden = true
        }
        
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        tableView.frame.height/CGFloat(self.productsArr?.count ?? 0)
    }
}
