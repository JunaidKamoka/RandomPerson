//
//  ImageGeneratorViewModel.swift
//  RandomPerson
//
//  Created by MacBook on 11/12/2024.
//


import Foundation
import UIKit

class ImageGeneratorViewModel {
    
    let apiKey = Bundle.main.object(forInfoDictionaryKey: "ApiKey") as! String

    private let apiURL = "https://api.getimg.ai/v1/flux-schnell/text-to-image"
    
    var onImageDownloaded: ((UIImage?) -> Void)?
    var onError: ((String) -> Void)?
    var image: UIImage?
    
    private var sizeRestiction = 512
    
    func calculateDimensions(for ratio: AspectRatio, baseWidth: Int = 512) -> (width: Int, height: Int)? {
        let multipliers = ratio.dimensions
        
        // Calculate height based on base width and aspect ratio
        var height = baseWidth * multipliers.heightMultiplier / multipliers.widthMultiplier
        var width = baseWidth
        
        // Ensure both width and height are integers and do not exceed 512
        height = Int(height)  // Ensure height is an integer
        if height > sizeRestiction {
            height = sizeRestiction
            width = Int(sizeRestiction * multipliers.widthMultiplier / multipliers.heightMultiplier) // Ensure width is an integer
        }
        
        if width > sizeRestiction {
            width = sizeRestiction
            height = Int(sizeRestiction * multipliers.heightMultiplier / multipliers.widthMultiplier) // Ensure height is an integer
        }
        
        return (width, height)
    }
    
    func generateImage(prompt: String, ratio: AspectRatio) {
        // Validate the aspect ratio and calculate the dimensions
        guard let dimensions = calculateDimensions(for: ratio) else {
            DispatchQueue.main.async {
                self.onError?("Invalid aspect ratio") // Error message for invalid aspect ratio
            }
            return
        }
        
        // Prepare the API parameters
        let parameters: [String: Any?] = [
            "prompt": prompt,
            "width": dimensions.width,
            "height": dimensions.height,
            "output_format": "png",
            "response_format": "url"
        ]
        
        print(parameters) // Debugging: print the parameters being sent
        
        // Validate the API URL
        guard let url = URL(string: apiURL) else {
            DispatchQueue.main.async {
                self.onError?("Invalid API URL") // Error message for invalid API URL
            }
            return
        }
        
        // Prepare the HTTP POST request
        do {
            let postData = try JSONSerialization.data(withJSONObject: parameters, options: [])
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.timeoutInterval = .infinity
            request.allHTTPHeaderFields = [
                "accept": "application/json",
                "content-type": "application/json",
                "authorization": "Bearer \(apiKey)"
            ]
            request.httpBody = postData
            
            // Perform API request
            let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
                // Handle network errors
                if let error = error {
                    DispatchQueue.main.async {
                        self?.onError?("Network Error: \(error.localizedDescription)") // Detailed network error message
                    }
                    return
                }
                
                // Handle no data received
                guard let data = data else {
                    DispatchQueue.main.async {
                        self?.onError?("No data received") // Error message for no data in response
                    }
                    return
                }
                
                // Handle HTTP status codes
                if let httpResponse = response as? HTTPURLResponse {
                    switch httpResponse.statusCode {
                    case 200:
                        // Success - proceed with parsing the response
                        break
                    case 400:
                        DispatchQueue.main.async {
                            self?.onError?("Bad Request: The server could not understand the request") // HTTP 400 error
                        }
                        return
                    case 401:
                        DispatchQueue.main.async {
                            self?.onError?("Unauthorized: Invalid API key or missing credentials") // HTTP 401 error
                        }
                        return
                    case 500:
                        DispatchQueue.main.async {
                            self?.onError?("Internal Server Error: Something went wrong on the server side") // HTTP 500 error
                        }
                        return
                    default:
                        DispatchQueue.main.async {
                            self?.onError?("HTTP Error: Status code \(httpResponse.statusCode)") // Other HTTP errors
                        }
                        return
                    }
                }
                
                // Debugging: print raw response data
                if let rawResponse = String(data: data, encoding: .utf8) {
                    print("Raw response: \(rawResponse)")
                }
                
                // Parse the JSON response and handle potential parsing errors
                do {
                    guard let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                          let imageURL = jsonResponse["url"] as? String else {
                        DispatchQueue.main.async {
                            self?.onError?("Failed to parse response: Invalid JSON or missing 'url' key")
                        }
                        return
                    }
                    
                    // Download the image from the URL
                    self?.downloadImage(from: imageURL)
                    
                } catch {
                    DispatchQueue.main.async {
                        self?.onError?("Failed to parse response: \(error.localizedDescription)") // JSON parsing error
                    }
                }
            }
            task.resume()
        } catch {
            DispatchQueue.main.async {
                self.onError?("Failed to create request: \(error.localizedDescription)") // Request creation error
            }
        }
    }
    
    private func downloadImage(from urlString: String) {
        guard let url = URL(string: urlString) else {
            onError?("Invalid image URL")
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.onError?(error.localizedDescription)
                }
                return
            }
            
            guard let data = data, let image = UIImage(data: data) else {
                DispatchQueue.main.async {
                    self?.onError?("Failed to download image")
                }
                return
            }
            
            DispatchQueue.main.async {
                self?.onImageDownloaded?(image)
                self?.image = image
            }
        }
        task.resume()
    }
}

enum AspectRatio: String, CaseIterable {
    case square = "Square(1:1)"    // 1:1
    case widescreen = "Wide Screen(16:9)" // 16:9
    case classic = "Classic(4:3)"    // 4:3
    case photography = "Photography(3:2)" // 3:2
    case portrait  = "Portrait(9:16)" // 9:16
    
    var dimensions: (widthMultiplier: Int, heightMultiplier: Int) {
        switch self {
        case .square:
            return (1, 1)
        case .widescreen:
            return (16, 9)
        case .classic:
            return (4, 3)
        case .photography:
            return (3, 4)
        case .portrait:
            return (9, 16)
        }
    }
}
