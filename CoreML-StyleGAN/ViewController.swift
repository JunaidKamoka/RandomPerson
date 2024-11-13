//
//  ViewController.swift
//  CoreML-StyleGAN
//
//  Created by DAISUKE MAJIMA on 2021/12/26.
//

import UIKit
import CoreML

class ViewController: UIViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var btnPremiumOutlet: UIButton!
    
    // For save image
    var outputImage: UIImage?
    var ciContext = CIContext()
    
    private var isShowed = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.runMobileStyleGAN()
        
        IAPViewModel.shared.receiptValidation(isLoader: false)
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
            
            imageView.image = image
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

