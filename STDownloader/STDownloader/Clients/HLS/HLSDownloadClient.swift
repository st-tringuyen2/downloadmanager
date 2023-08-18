//
//  HLSDownloadClient.swift
//  DownloadManager
//
//  Created by Tri Nguyen T. [2] on 09/08/2023.
//

import Foundation

public protocol HLSDownloadClient {
    func download(from fileMetaData: FileMetaData)
    func pause(id: UUID)
    func resume(id: UUID)
    func resume(fileMetaData: FileMetaData)
}
