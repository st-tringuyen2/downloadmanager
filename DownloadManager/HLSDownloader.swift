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
    
    private let client: DownloadClient
    
    init(client: DownloadClient) {
        self.client = client
    }
    
    func download(from fileMetaData: FileMetaData) {
        client.download(from: fileMetaData)
    }
    
    func updateDownloadList(_ list: [FileMetaData]) {
        downloadList.append(contentsOf: list)
    }
}
