//
//  InternetDownloader.swift
//  STDownloader
//
//  Created by Tri Nguyen T. [2] on 18/08/2023.
//

import Foundation

public class InternetDownloader: Downloader {
    public var delegate: DownloadDelegate?
    
    private let fileDownloader: Downloader
    private let hlsDownloader: Downloader
    
    private var downloadList = [FileMetaData]()

    public init(fileDownloader: Downloader, hlsDownloader: Downloader) {
        self.fileDownloader = fileDownloader
        self.hlsDownloader = hlsDownloader
    }
    
    public func download(from fileMetaData: FileMetaData) {
        downloadList.append(fileMetaData)
        if fileMetaData.type == .hls {
            hlsDownloader.download(from: fileMetaData)
        } else {
            fileDownloader.download(from: fileMetaData)
        }
    }
    
    public func pause(id: UUID) {
        if let file = downloadList.first(where: { $0.id == id }) {
            if file.type == .hls {
                hlsDownloader.pause(id: id)
            } else {
                fileDownloader.pause(id: id)
            }
        }
    }
    
    public func resume(id: UUID) {
        if let file = downloadList.first(where: { $0.id == id }) {
            if file.type == .hls {
                hlsDownloader.resume(id: id)
            } else {
                fileDownloader.resume(id: id)
            }
        }
    }
    
    public func updateDownloadList(_ list: [FileMetaData]) {
        downloadList.append(contentsOf: list)
        list.forEach { file in
            if file.type == .hls {
                hlsDownloader.updateDownloadList(list)
            } else {
                fileDownloader.updateDownloadList(list)
            }
        }
    }
}

extension InternetDownloader: DownloadDelegate {
    public func didComplete(with error: Error, for id: UUID) {
        delegate?.didComplete(with: error, for: id)
    }
    
    public func downloadingProgess(_ progress: Float, for id: UUID) {
        delegate?.downloadingProgess(progress, for: id)
    }
    
    public func didFinishDownloading(for id: UUID) {
        delegate?.didFinishDownloading(for: id)
    }
    
    public func willDownloadTo(location: URL, for id: UUID) {
        delegate?.willDownloadTo(location: location, for: id)
    }
}
