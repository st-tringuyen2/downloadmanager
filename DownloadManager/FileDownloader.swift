//
//  FileDownloader.swift
//  DownloadManager
//
//  Created by Tri Nguyen T. [2] on 01/08/2023.
//

import Foundation

public struct HTTPRangeRequestHeader: Hashable {
    let start: Int
    let end: Int
}

class URLSessionDownloadClient: NSObject, DownloadClient {
    private var activeDownloadsMap = [UUID: [Int: URLSessionDownloadTask]]()

    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.background(withIdentifier: String(describing: self))
        let session = URLSession(configuration: config, delegate: self, delegateQueue: .none)
        
        return session
    }()
    
    func download(from fileMetaData: FileMetaData, for part: Int, with range: HTTPRangeRequestHeader?) {
        var request = URLRequest(url: fileMetaData.url)
        if let range = range {
            request.setValue("bytes=\(range.start)-\(range.end)", forHTTPHeaderField: "Range")
        }
        let downloadTask = session.downloadTask(with: request)
        downloadTask.resume()
        if var activeDownload = activeDownloadsMap[fileMetaData.id] {
            activeDownload[part] = downloadTask
            activeDownloadsMap[fileMetaData.id] = activeDownload
        } else {
            activeDownloadsMap[fileMetaData.id] = [part: downloadTask]
        }
    }
}

extension URLSessionDownloadClient: URLSessionDownloadDelegate {
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        
    }
}

protocol DownloadClient {
    func download(from fileMetaData: FileMetaData, for part: Int, with range: HTTPRangeRequestHeader?)
}

class FileDownloader: Downloader {
    private var numbersOfDownloadPart: Int {
        return 8
    }
    
    private var downloadList = [FileMetaData]()
    private var downloadPartLocations = [UUID: [URL]]()
    private var fileDownloads = [UUID: [Int]]()
    private var rangeRequests = [UUID: [HTTPRangeRequestHeader]]()
    
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
