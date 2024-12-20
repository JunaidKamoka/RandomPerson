//
//  ViewController.swift
//  CoreML-StyleGAN
//
//  Created by DAISUKE MAJIMA on 2021/12/26.
//

import UIKit
import CoreML
import Lottie

class ViewController: UIViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var btnPremiumOutlet: UIButton!
    @IBOutlet weak var premiumLottieView: UIView!
    @IBOutlet weak var promptTF: UITextField!
    
    @IBOutlet weak var resolutionLabel: UILabel! // Reso Label

    let resolutions = AspectRatio.allCases
    var selectedResolutions: AspectRatio = .portrait

    let viewModel = ImageGeneratorViewModel()
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    private let blurEffectView: UIVisualEffectView = {
        let blurEffect = UIBlurEffect(style: .light)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.translatesAutoresizingMaskIntoConstraints = false
        return blurView
    }()
    
    private var isShowed = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        self.runMobileStyleGAN()
        
        IAPViewModel.shared.receiptValidation(isLoader: false)
        self.animationSetup()
        
        // Set up the blur effect view
        view.addSubview(blurEffectView)
        NSLayoutConstraint.activate([
            blurEffectView.topAnchor.constraint(equalTo: view.topAnchor),
            blurEffectView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            blurEffectView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            blurEffectView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        // Set up the activity indicator
        view.addSubview(activityIndicator)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        self.setupBindings()
        self.hideLoading()
        self.resolutionLabel.text = self.selectedResolutions.rawValue
//        self.loadPicker()
    }
    
    private func setupBindings() {
        viewModel.onImageDownloaded = { [weak self] image in
            self?.hideLoading()
            self?.imageView.image = image
        }
        
        viewModel.onError = { [weak self] errorMessage in
            self?.activityIndicator.stopAnimating()
            let alert = UIAlertController(title: "Error", message: errorMessage, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self?.present(alert, animated: true)
        }
    }
    
    private func animationSetup() {
        
        let premiumAnimViewSubView: LottieAnimationView = LottieAnimationView()
        
        premiumAnimViewSubView.animation = LottieAnimation.named("Premium")
        premiumAnimViewSubView.loopMode = .loop
        premiumAnimViewSubView.translatesAutoresizingMaskIntoConstraints = false // Disable autoresizing mask
        premiumAnimViewSubView.frame = self.premiumLottieView.bounds
        premiumAnimViewSubView.contentMode = .scaleAspectFit
        
        if premiumAnimViewSubView.superview == nil {
            self.premiumLottieView.addSubview(premiumAnimViewSubView)
            
            // Center aiAnimSubView within aiAnimView
            NSLayoutConstraint.activate([
                premiumAnimViewSubView.centerXAnchor.constraint(equalTo: premiumLottieView.centerXAnchor),
                premiumAnimViewSubView.centerYAnchor.constraint(equalTo: premiumLottieView.centerYAnchor),
                premiumAnimViewSubView.widthAnchor.constraint(equalTo: premiumLottieView.widthAnchor), // Optional: Match width
                premiumAnimViewSubView.heightAnchor.constraint(equalTo: premiumLottieView.heightAnchor) // Optional: Match height
            ])
        }
        
        // Optionally restart the animation
        premiumAnimViewSubView.play()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if self.isShowed == false && IAPViewModel.shared.isPurchased == false {
            
            self.isShowed = true
            let iapVC = self.storyboard?.instantiateViewController(withIdentifier: IAPVC.className) as! IAPVC
            iapVC.modalPresentationStyle = .fullScreen
            self.present(iapVC, animated: true)
        }
        
        if IAPViewModel.shared.isPurchased == true {
            
            self.btnPremiumOutlet.isHidden = true
        }
        
    }
    
    @IBAction func btnPremium() {
        
        let iapVC = self.storyboard?.instantiateViewController(withIdentifier: IAPVC.className) as! IAPVC
        iapVC.modalPresentationStyle = .fullScreen
        self.present(iapVC, animated: true)
    }
    
    @IBAction func runAgainButtonTapped(_ sender: UIButton) {
        
                guard IAPViewModel.shared.canProceed() == true else {return}
        
        guard let promptText = promptTF.text, !promptText.isEmpty else {
               // Show alert if the prompt is empty
               let alert = UIAlertController(title: "Error", message: "Please enter a prompt/instruction before proceeding. For example, you can include details like age, gender, and description (e.g., 'Portrait of a young woman with blonde hair and a bright smile').", preferredStyle: .alert)
               alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
               present(alert, animated: true, completion: nil)
               return
           }
        
        self.showLoading()
        viewModel.generateImage(
            prompt: promptText,
            ratio: self.selectedResolutions
        )
    }
    
    @IBAction func saveButtonTapped(_ sender: UIButton) {
        
        guard let outputImage = viewModel.image else {
            return
        }
        
        _ = ImageSaver(image: outputImage) {
            
            let ac = UIAlertController(title: NSLocalizedString("saved!",value: "saved!", comment: ""), message: NSLocalizedString("Saved in photo library",value: "Saved in photo library", comment: ""), preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(ac, animated: true)
        } onFail: { error in
            
            // we got back an error!
            let ac = UIAlertController(title: "Save error", message: error?.localizedDescription, preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(ac, animated: true)
        }
        
    }
    
    // Function to show the loader with blur effect
    func showLoading() {
        blurEffectView.isHidden = false
        activityIndicator.startAnimating()
    }

    // Function to hide the loader and the blur effect
    func hideLoading() {
        blurEffectView.isHidden = true
        activityIndicator.stopAnimating()
    }
    
    @IBAction func resoTapped(_ sender: UIButton) {
        // Create an action sheet style alert controller
        let alertController = UIAlertController(title: "Select Resolution", message: nil, preferredStyle: .actionSheet)
        
        // Add each resolution as an action in the alert controller
        for resolution in resolutions {
            alertController.addAction(UIAlertAction(title: resolution.rawValue, style: .default, handler: { [weak self] _ in
                // Update the label with the selected resolution
                self?.resolutionLabel.text = resolution.rawValue
                self?.selectedResolutions = resolution
            }))
        }
        
        // Add a cancel action to close the alert
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        // Check if the device is an iPad
        if let popoverController = alertController.popoverPresentationController {
            // Set the source view and source rect for the popover on iPad
            popoverController.sourceView = sender
            popoverController.sourceRect = sender.bounds
            popoverController.permittedArrowDirections = .any
        }
        
        // Present the alert controller
        present(alertController, animated: true, completion: nil)
    }
    
}

