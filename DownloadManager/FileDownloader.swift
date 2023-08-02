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
    
    public enum Error: Swift.Error {
        case mergeFileError
    }
    
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
    func didComplete(with error: Swift.Error, for id: UUID, at part: Int) {
        removeCompletePartDownload(id, part)
        checkDownloadFinish(for: id)
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
    
    private func removeCompletePartDownload(_ id: UUID, _ part: Int) {
        if var fileDict = fileDownloads.first(where: { $0.key == id}) {
            fileDict.value.removeAll(where: { $0 == part })
            fileDownloads.updateValue(fileDict.value, forKey: fileDict.key)
        }
    }
    
    private func checkDownloadFinish(for id: UUID) {
        if fileDownloads.first(where: { $0.key == id})?.value.isEmpty == true {
            debugPrint("Finish downloaded all parts of id \(id)")
            mergeFile(for: id)
        }
    }
    
    private func mergeFile(for id: UUID) {
        guard downloadPartLocations[id]?.count == numbersOfDownloadPart else {
            delegate?.didComplete(with: FileDownloader.Error.mergeFileError, for: id)
            return
        }
        if let locations = downloadPartLocations[id], let saveLocation = downloadList.first(where: { $0.id == id })?.saveLocation {
            do {
                try writeDataToFile(from: locations, to: saveLocation)
            } catch {
                debugPrint("Try to write data to file \(saveLocation) but failed with \(error)")
                delegate?.didComplete(with: FileDownloader.Error.mergeFileError, for: id)
            }
        }
    }
    
    private func writeDataToFile(from locations: [URL], to fileLocation: URL) throws {
        let maxNumberOfBytesToRead = 5 * 1024 * 1024 // 50MB
        let writer = try FileHandle(forWritingTo: fileLocation)
        try locations.forEach { location in
            let reader = try FileHandle(forReadingFrom: location)
            var dataOrNil = try reader.read(upToCount: maxNumberOfBytesToRead)
            while (dataOrNil?.count ?? 0) > 0 {
                if let data = dataOrNil {
                    try writer.write(contentsOf: data)
                    dataOrNil = reader.readData(ofLength: maxNumberOfBytesToRead)
                }
                try reader.close()
            }
        }
        try writer.close()
    }
}
