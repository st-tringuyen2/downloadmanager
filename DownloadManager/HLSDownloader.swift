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
    
    private let client: HLSDownloadClient
    
    init(client: HLSDownloadClient) {
        self.client = client
    }
    
    func download(from fileMetaData: FileMetaData) {
        client.download(from: fileMetaData)
        downloadList.append(fileMetaData)
    }
    
    func updateDownloadList(_ list: [FileMetaData]) {
        downloadList.append(contentsOf: list)
    }
}

extension HLSDownloader: HLSDownloadClientDelegate {
    func willDownload(to location: URL, for id: UUID) {
        if let index = downloadList.firstIndex(where:  { $0.id == id }) {
            downloadList[index].saveLocation = location
        }
    }
    
    func didComplete(with error: Error, for id: UUID) {
        delegate?.didComplete(with: error, for: id)
    }
    
    func downloadingProgress(_ progress: Float, for id: UUID) {
        delegate?.downloadingProgess(progress, for: id)
    }
    
    func didFinishDownloading(for id: UUID) {
        delegate?.didFinishDownloading(for: id)
    }
}
