//
//  ImageSaver.swift
//  CoreML-StyleGAN
//
//  Created by MacBook on 13/11/2024.
//


import UIKit
import UniformTypeIdentifiers
import MobileCoreServices

class ImageSaver: NSObject, UIDocumentPickerDelegate {
    
    var onSuccess: (() -> ()) = {}
    var onFail: ((Error?) -> ()) = { _ in }
    
    init(image: UIImage, onSuccess: @escaping (() -> ()), onFail: @escaping ((Error?) -> ())) {
        self.onSuccess = onSuccess
        self.onFail = onFail
        super.init()
        
        #if targetEnvironment(macCatalyst)
        if #available(iOS 14.0, *) {
            presentDocumentPicker(for: image)
        } else {
            presentFolderPickerAndSaveImage(image)
        }
        #else
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(saveError), nil) // Save to Photos on iOS
        #endif
    }
    
    // Use UIDocumentPicker for iOS 14+ Mac Catalyst
    @available(iOS 14.0, *)
    func presentDocumentPicker(for image: UIImage) {
        guard let imageData = image.pngData() else {
            DispatchQueue.main.async {
                self.onFail(nil)
            }
            return
        }

        // Create a temporary file for the image
        let tempDirectory = FileManager.default.temporaryDirectory
        let tempFileURL = tempDirectory.appendingPathComponent("AppChunks.png")

        do {
            // Write the image data to the temporary file
            try imageData.write(to: tempFileURL)
            
            // Present UIDocumentPickerViewController to allow user to select a folder and file name
            let documentPicker = UIDocumentPickerViewController(forExporting: [tempFileURL], asCopy: true)
            documentPicker.delegate = self
            documentPicker.allowsMultipleSelection = false
            documentPicker.shouldShowFileExtensions = true
            
            // Present the document picker (ensure you have access to a view controller)
            if let viewController = UIApplication.shared.windows.first?.rootViewController {
                viewController.present(documentPicker, animated: true) {
                    DispatchQueue.main.async {
                        self.onSuccess()
                    }
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.onFail(error)
            }
        }
    }

    // Fallback for earlier Mac Catalyst versions to pick folder and save image manually
    func presentFolderPickerAndSaveImage(_ image: UIImage) {
        guard let imageData = image.pngData() else {
            DispatchQueue.main.async {
                self.onFail(nil)
            }
            return
        }

        // Use legacy UTType to pick a folder in earlier versions
        let documentPicker = UIDocumentPickerViewController(documentTypes: [kUTTypeFolder as String], in: .open)
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = false
        documentPicker.directoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        
        // Present the document picker
        if let viewController = UIApplication.shared.windows.first?.rootViewController {
            viewController.present(documentPicker, animated: true) {
                DispatchQueue.main.async {
                    self.onSuccess()
                }
            }
        }
    }

    // UIDocumentPickerDelegate method to handle folder selection
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        // Use the first folder selected (if any)
        guard let selectedFolderURL = urls.first else {
            DispatchQueue.main.async {
                self.onFail(nil) // No folder selected
            }
            return
        }

        // Get the path where the image should be saved
        let imageFileURL = selectedFolderURL.appendingPathComponent("AppChunks.png")

        // Get the image data
        guard let imageData = UIImage().pngData() else {
            DispatchQueue.main.async {
                self.onFail(nil)
            }
            return
        }

        // Save the image to the selected folder
        do {
            try imageData.write(to: imageFileURL)
            DispatchQueue.main.async {
                self.onSuccess() // Call success on main thread
            }
        } catch {
            DispatchQueue.main.async {
                self.onFail(error) // Call fail on main thread
            }
        }
    }

    // UIDocumentPickerDelegate method for cancellation
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        DispatchQueue.main.async {
            self.onFail(nil) // User cancelled the picker
        }
    }

    // Error handling for iOS
    @objc func saveError(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            DispatchQueue.main.async {
                self.onFail(error)
            }
        } else {
            DispatchQueue.main.async {
                self.onSuccess()
            }
        }
    }
}
