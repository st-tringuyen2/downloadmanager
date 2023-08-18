//
//  SceneDelegate.swift
//  DownloadManager
//
//  Created by Tri Nguyen T. [2] on 31/07/2023.
//

import UIKit
import STDownloader

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    private var navigationController: UINavigationController?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        window = UIWindow(windowScene: windowScene)
        
        let hlsClient = AVAssetDownloadURLSessionClient()
        let hlsDownloader = HLSDownloader(client: hlsClient)
        hlsClient.delegate = hlsDownloader
        
        let fileClient = URLSessionDownloadClient()
        let fileDownloader = FileDownloader(client: fileClient)
        fileClient.delegate = fileDownloader
        
        let internetDownloader = InternetDownloader(fileDownloader: fileDownloader, hlsDownloader: hlsDownloader)
        fileDownloader.delegate = internetDownloader
        hlsDownloader.delegate = internetDownloader
        let downloadManagerViewController = DownloadManagerComposer.makeDownloadManagerViewController(downloader: internetDownloader)
        navigationController = UINavigationController(rootViewController: downloadManagerViewController)
        
        window?.rootViewController = navigationController
        window?.makeKeyAndVisible()
    }
}

