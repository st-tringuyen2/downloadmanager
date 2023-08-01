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

class FileDownloader: Downloader {
    private var numbersOfDownloadPart: Int {
        return 8
    }
    
    private var downloadList = [FileMetaData]()
    private var downloadPartLocations = [UUID: [URL]]()
    private var rangeRequests = [UUID: [HTTPRangeRequestHeader]]()
    
    func download(from fileMetaData: FileMetaData) {
        createRange(from: fileMetaData)
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
}
