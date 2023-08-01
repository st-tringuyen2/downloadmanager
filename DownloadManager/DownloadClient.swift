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

protocol DownloadClient {
    func download(from fileMetaData: FileMetaData, for part: Int, with range: HTTPRangeRequestHeader?)
}
