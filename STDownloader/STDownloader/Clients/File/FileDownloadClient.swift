//
//  DownloadClient.swift
//  DownloadManager
//
//  Created by Tri Nguyen T. [2] on 01/08/2023.
//

import Foundation

public struct HTTPRangeRequestHeader: Hashable {
    let start: Int
    let end: Int
}

public protocol FileDownloadClient {
    func download(from fileMetaData: FileMetaData, for part: Int, with range: HTTPRangeRequestHeader?)
    func pause(id: UUID)
    func resume(id: UUID, with ranges: [HTTPRangeRequestHeader]?)
}
