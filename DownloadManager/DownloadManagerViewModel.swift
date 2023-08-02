//
//  DownloadManagerViewModel.swift
//  DownloadManager
//
//  Created by Tri Nguyen T. [2] on 01/08/2023.
//

import Foundation

class DownloadManagerViewModel {
    private var downloadList = [DownloadCellModel]()
    
    private var downloader: Downloader
    
    init(downloader: Downloader) {
        self.downloader = downloader
        self.downloader.delegate = self
    }

    var numbersOfItems: Int {
        return downloadList.count
    }
    
    func item(for index: Int) -> DownloadCellModel {
        return downloadList[index]
    }
}

extension DownloadManagerViewModel {
    func download(from fileMetaData: FileMetaData) {
        downloader.download(from: fileMetaData)
    }
}

extension DownloadManagerViewModel: DownloadDelegate {
    func didComplete(with error: Error, for id: UUID) {
        
    }
    
    func downloadingProgess(_ progress: Float, for id: UUID) {
        print(progress)
    }
    
    func didFinishDownloading(to location: URL, for id: UUID) {
        
    }
}
