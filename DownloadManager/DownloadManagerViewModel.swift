//
//  DownloadManagerViewModel.swift
//  DownloadManager
//
//  Created by Tri Nguyen T. [2] on 01/08/2023.
//

import Foundation

class DownloadManagerViewModel {
    private var downloadList = [DownloadCellModel]()
    
    private let downloader: Downloader
    
    init(downloader: Downloader) {
        self.downloader = downloader
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
