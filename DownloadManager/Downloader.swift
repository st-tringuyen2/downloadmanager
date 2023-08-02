//
//  Downloader.swift
//  DownloadManager
//
//  Created by Tri Nguyen T. [2] on 01/08/2023.
//

import Foundation

protocol Downloader {
    var delegate: DownloadDelegate? { get set }
    func download(from fileMetaData: FileMetaData)
}
