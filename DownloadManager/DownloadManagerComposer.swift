//
//  DownloadManagerComposer.swift
//  DownloadManager
//
//  Created by Tri Nguyen T. [2] on 01/08/2023.
//

import UIKit
import STDownloader

class DownloadManagerComposer {
    
    static func makeDownloadManagerViewController(downloader: Downloader) -> DownloadManagerViewController {
        let downloadManagerViewModel = DownloadManagerViewModel(downloader: downloader, downloadStore: UserDefaults.standard)
        let downloadManagerViewController = DownloadManagerViewController(viewModel: downloadManagerViewModel)
        
        return downloadManagerViewController
    }
}
