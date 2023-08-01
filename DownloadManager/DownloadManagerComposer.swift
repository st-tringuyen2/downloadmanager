//
//  DownloadManagerComposer.swift
//  DownloadManager
//
//  Created by Tri Nguyen T. [2] on 01/08/2023.
//

import UIKit

class DownloadManagerComposer {
    
    static func makeDownloadManagerViewController() -> DownloadManagerViewController {
        let downloader = FileDownloader()
        let downloadManagerViewModel = DownloadManagerViewModel(downloader: downloader)
        let downloadManagerViewController = DownloadManagerViewController(viewModel: downloadManagerViewModel)
        
        return downloadManagerViewController
    }
}
