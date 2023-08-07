//
//  HLSDownloader.swift
//  DownloadManager
//
//  Created by Tri Nguyen T. [2] on 07/08/2023.
//

import Foundation

class HLSDownloader: Downloader {
    var delegate: DownloadDelegate?
    
    private var downloadList = [FileMetaData]()
    private var downloadLocations = [UUID: URL]()

    func download(from fileMetaData: FileMetaData) {
        
    }
    
    func updateDownloadList(_ list: [FileMetaData]) {
        
    }
}
