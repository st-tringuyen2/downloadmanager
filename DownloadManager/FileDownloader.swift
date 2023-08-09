//
//  FileDownloader.swift
//  DownloadManager
//
//  Created by Tri Nguyen T. [2] on 01/08/2023.
//

import Foundation

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
    
    private let fileManager: FileManager
    
    public weak var delegate: DownloadDelegate?
    private let client: FileDownloadClient
    
    init(client: FileDownloadClient, fileManager: FileManager = .default) {
        self.client = client
        self.fileManager = fileManager
    }
    
    func updateDownloadList(_ list: [FileMetaData]) {
        downloadList.append(contentsOf: list)
        list.forEach { fileMetaData in
            createRange(from: fileMetaData)
        }
    }
    
    private func updateFileDownload(from id: UUID, with part: Int) {
        if fileDownloads[id] == nil {
            fileDownloads[id] = [part]
        } else {
            fileDownloads[id]?.append(part)
        }
    }
    
    func download(from fileMetaData: FileMetaData) {
        downloadList.append(fileMetaData)
        createRange(from: fileMetaData)
        startDownload(from: fileMetaData)
    }
    
    private func createRange(from fileMetaData: FileMetaData) {
        guard numbersOfDownloadPart > 0 else {
            downloadPartLocations[fileMetaData.id] = []
            return
        }
        let sizeOfPart = fileMetaData.size / numbersOfDownloadPart
        
        guard sizeOfPart > 0 else {
            downloadPartLocations[fileMetaData.id] = []
            return
        }
        
        var startRange = 0
        var endRange = 0
        var ranges = [HTTPRangeRequestHeader]()
        var partLocations = [URL]()
        
        for i in 0..<numbersOfDownloadPart {
            let saveLocation = fileMetaData.saveLocation.deletingLastPathComponent()
            partLocations.append(saveLocation.appendingPathComponent(fileMetaData.name + ".part\(i)"))
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
            fileDownloads[fileMetaData.id] = [0]
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

extension FileDownloader: FileDownloadClientDelegate {
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
        moveFile(from: location, with: id, at: part)
        removeCompletePartDownload(id, part)
        checkDownloadFinish(for: id)
    }
    
    func restoreDownloadSession(for id: UUID, part: Int) {
        updateFileDownload(from: id, with: part)
    }
}

extension FileDownloader {
    private func totalDownloadProgress(for id: UUID) -> Float {
        guard let progress = downloadProgress[id] else { return 0 }
        return numbersOfDownloadPart > 0 ? progress.reduce(0, { $0 + $1.value }) / Float(numbersOfDownloadPart) : progress.reduce(0, { $0 + $1.value })
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
            if numbersOfDownloadPart > 0 {
                mergeFile(for: id)
            }
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
                delegate?.didFinishDownloading(for: id)
            } catch {
                debugPrint("Try to write data to file \(saveLocation) but failed with \(error)")
                delegate?.didComplete(with: FileDownloader.Error.mergeFileError, for: id)
            }
        }
    }
    
    private func writeDataToFile(from locations: [URL], to fileLocation: URL) throws {
        var maxNumberOfBytesToRead = 50 * 1024 * 1024 // 50MB
        let writer = try FileHandle(forWritingTo: fileLocation)
        try locations.forEach { location in
            let reader = try FileHandle(forReadingFrom: location)
            var dataOrNil = try reader.read(upToCount: maxNumberOfBytesToRead)
            while (dataOrNil?.count ?? 0) > 0 {
                if let data = dataOrNil {
                    try writer.write(contentsOf: data)
                    maxNumberOfBytesToRead += maxNumberOfBytesToRead
                    dataOrNil = try reader.read(upToCount: maxNumberOfBytesToRead)
                }
                try reader.close()
            }
            try fileManager.removeItem(at: location)
        }
        try writer.close()
    }
    
    private func moveFile(from location: URL, with id: UUID, at part: Int) {
        if numbersOfDownloadPart == 0, let saveLocation = downloadList.first(where: { $0.id == id })?.saveLocation {
            try? writeDataToFile(from: [location], to: saveLocation)
        } else {
            for (index, partLocation) in (downloadPartLocations[id] ?? []).enumerated() {
                if part == index {
                    try? fileManager.moveItem(at: location, to: partLocation)
                }
            }
        }
    }
}
