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
    
    // For save image
    var outputImage: UIImage?
    var ciContext = CIContext()
    
    private var isShowed = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.runMobileStyleGAN()
        
        IAPViewModel.shared.receiptValidation(isLoader: false)
        self.animationSetup()
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
    
    func runMobileStyleGAN() {
        do {
            
            // Mapping
            
            let mappingNetwork = try mappingNetwork(configuration: MLModelConfiguration())
            let input = try MLMultiArray(shape: [1,512] as [NSNumber], dataType: MLMultiArrayDataType.float32)
            
            for i in 0...input.count - 1 {
                input[i] = NSNumber(value: Float32.random(in: -1...1))
            }
            let mappingInput = mappingNetworkInput(var_: input)
            
            let mappingOutput = try mappingNetwork.prediction(input: mappingInput)
            let style = mappingOutput.var_134
            
            // Synthesis
            
            let synthesisNetwork = try synthesisNetwork(configuration: MLModelConfiguration())
            
            let mlinput = synthesisNetworkInput(style: style)
            let output = try synthesisNetwork.prediction(input: mlinput)
            let buffer = output.activation_out
            let ciImage = CIImage(cvPixelBuffer: buffer)
            guard let safeCGImage = ciContext.createCGImage(ciImage, from: ciImage.extent) else { print("Could not create cgimage."); return}
            let image = UIImage(cgImage: safeCGImage)
            
            UIView.transition(with: imageView,
                              duration: 0.5, // Animation duration
                              options: .transitionCrossDissolve, // Smooth fade effect
                              animations: {
                self.imageView.image = image
            },
                              completion: nil)
            outputImage = image
            
        } catch let error {
            fatalError("\(error)")
        }
    }
    
    @IBAction func btnPremium() {
        
        let iapVC = self.storyboard?.instantiateViewController(withIdentifier: IAPVC.className) as! IAPVC
        iapVC.modalPresentationStyle = .fullScreen
        self.present(iapVC, animated: true)
    }
    
    @IBAction func runAgainButtonTapped(_ sender: UIButton) {
        
        guard IAPViewModel.shared.canProceed() == true else {return}
        self.runMobileStyleGAN()
    }
    
    @IBAction func saveButtonTapped(_ sender: UIButton) {
        
        guard let outputImage = outputImage else {
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
    
}

