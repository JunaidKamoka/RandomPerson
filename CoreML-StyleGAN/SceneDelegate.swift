//
//  SceneDelegate.swift
//  CoreML-StyleGAN
//
//  Created by 間嶋大輔 on 2021/12/26.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        #if targetEnvironment(macCatalyst)
        if let sizeRestrictions = windowScene.sizeRestrictions {
            
            // Reduced size by 10% (scaled down)
            let fixedHeight: CGFloat = 864 * 1.2  // 90% of the original width
            let fixedWidth: CGFloat = fixedHeight * 3 / 4  // Maintain 4:3 aspect ratio
            
            let fixedSize = CGSize(width: fixedWidth, height: fixedHeight)
            
            print("fixedSize: ",fixedSize)
            sizeRestrictions.minimumSize = fixedSize
            sizeRestrictions.maximumSize = fixedSize
        }
        
        #endif
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }


}

