//
//  SceneDelegate.swift
//  DownloadManager
//
//  Created by Tri Nguyen T. [2] on 31/07/2023.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    private var navigationController: UINavigationController?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        window = UIWindow(windowScene: windowScene)
        
        let client = AVAssetDownloadURLSessionClient()
        let downloader = HLSDownloader(client: client)
//        client.delegate = downloader
        let downloadManagerViewController = DownloadManagerComposer.makeDownloadManagerViewController(downloader: downloader)
        navigationController = UINavigationController(rootViewController: downloadManagerViewController)
        
        window?.rootViewController = navigationController
        window?.makeKeyAndVisible()
    }
}

