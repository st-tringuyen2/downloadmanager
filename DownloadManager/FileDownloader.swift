//
//  FileDownloader.swift
//  DownloadManager
//
//  Created by Tri Nguyen T. [2] on 01/08/2023.
//

import Foundation

protocol DownloadDelegate: AnyObject {
    func didComplete(with error: Error, for id: UUID)
    func downloadingProgess(_ progress: Float, for id: UUID)
    func didFinishDownloading(to location: URL, for id: UUID)
}

class FileDownloader: NSObject, Downloader {
    private var numbersOfDownloadPart: Int {
        return 8
    }
    
    private var downloadList = [FileMetaData]()
    private var downloadPartLocations = [UUID: [URL]]()
    private var fileDownloads = [UUID: [Int]]()
    private var rangeRequests = [UUID: [HTTPRangeRequestHeader]]()
    private var downloadProgress = [UUID: [Int: Float]]()
    
    public weak var delegate: DownloadDelegate?
    private let client: DownloadClient
    
    init(client: DownloadClient) {
        self.client = client
    }
    
    func download(from fileMetaData: FileMetaData) {
        createRange(from: fileMetaData)
        startDownload(from: fileMetaData)
    }
    
    private func createRange(from fileMetaData: FileMetaData) {
        let sizeOfPart = fileMetaData.size / numbersOfDownloadPart
        
        guard sizeOfPart > 0 else { return }
        
        var startRange = 0
        var endRange = 0
        var ranges = [HTTPRangeRequestHeader]()
        var partLocations = [URL]()
        
        for i in 0..<numbersOfDownloadPart {
            let saveLocation = fileMetaData.saveLocation.appendingPathComponent(".part\(i)")
            partLocations.append(saveLocation)
            endRange += (sizeOfPart - 1)
            let range = HTTPRangeRequestHeader(start: startRange, end: i == numbersOfDownloadPart - 1 ? fileMetaData.size : endRange - 1)
            ranges.append(range)
            startRange = endRange
        }
        downloadPartLocations[fileMetaData.id] = partLocations
        rangeRequests[fileMetaData.id] = ranges
    }
    
    private func startDownload(from fileMetaData: FileMetaData) {
        guard let ranges = rangeRequests[fileMetaData.id], !ranges.isEmpty else {
            client.download(from: fileMetaData, for: 0, with: nil)
            fileDownloads[fileMetaData.id]?.append(0)
            return
        }
        
        var indexs = [Int]()
        for (index, range) in ranges.enumerated() {
            indexs.append(index)
            fileDownloads[fileMetaData.id] = indexs
            client.download(from: fileMetaData, for: index, with: range)
        }
    }
}

extension FileDownloader: DownloadClientDelegate {
    func didComplete(with error: Error, for id: UUID, at part: Int) {
        print(error, id, part)
    }
    
    func downloadingProgress(_ progress: Float, for id: UUID, at part: Int) {
        if downloadProgress[id] == nil {
            downloadProgress[id] = [part: progress]
        } else {
            downloadProgress[id]?[part] = progress
        }
        delegate?.downloadingProgess(totalDownloadProgress(for: id), for: id)
    }
    
    func didFinishDownloading(to location: URL, for id: UUID, at part: Int) {
        
    }
}

extension FileDownloader {
    private func totalDownloadProgress(for id: UUID) -> Float {
        guard let progress = downloadProgress[id] else { return 0 }
        return progress.reduce(0, { $0 + $1.value }) / Float(numbersOfDownloadPart)
    }
}
