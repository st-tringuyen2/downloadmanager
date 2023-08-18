//
//  HLSDownloader.swift
//  DownloadManager
//
//  Created by Tri Nguyen T. [2] on 07/08/2023.
//

import Foundation

public class HLSDownloader: NSObject, Downloader {
    public weak var delegate: DownloadDelegate?
    
    private var downloadList = [FileMetaData]()
    private var downloadLocations = [UUID: URL]()
    
    private let client: HLSDownloadClient
    
    public init(client: HLSDownloadClient) {
        self.client = client
    }
    
    public func download(from fileMetaData: FileMetaData) {
        client.download(from: fileMetaData)
        downloadList.append(fileMetaData)
    }
    
    public func pause(id: UUID) {
        client.pause(id: id)
    }
    
    public func resume(id: UUID) {
        client.resume(id: id)
    }
    
    public func updateDownloadList(_ list: [FileMetaData]) {
        downloadList.append(contentsOf: list)
        list.forEach { fileMetaData in
            if fileMetaData.state == .downloading {
                self.client.resume(fileMetaData: fileMetaData)
            }
        }
    }
}

extension HLSDownloader: HLSDownloadClientDelegate {
    public func willDownload(to location: URL, for id: UUID) {
        if let index = downloadList.firstIndex(where:  { $0.id == id }) {
            downloadList[index].saveLocation = location
            delegate?.willDownloadTo(location: location, for: id)
        }
    }
    
    public func didComplete(with error: Error, for id: UUID) {
        delegate?.didComplete(with: error, for: id)
    }
    
    public func downloadingProgress(_ progress: Float, for id: UUID) {
        delegate?.downloadingProgess(progress, for: id)
    }
    
    public func didFinishDownloading(for id: UUID) {
        delegate?.didFinishDownloading(for: id)
    }
}
