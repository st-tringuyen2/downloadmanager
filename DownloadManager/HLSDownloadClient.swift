//
//  HLSDownloadClient.swift
//  DownloadManager
//
//  Created by Tri Nguyen T. [2] on 09/08/2023.
//

import Foundation

protocol HLSDownloadClient {
    func download(from fileMetaData: FileMetaData)
}
