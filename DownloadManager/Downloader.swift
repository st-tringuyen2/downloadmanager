//
//  Downloader.swift
//  DownloadManager
//
//  Created by Tri Nguyen T. [2] on 01/08/2023.
//

import Foundation

protocol DownloadDelegate: AnyObject {
    func didComplete(with error: Error, for id: UUID)
    func downloadingProgess(_ progress: Float, for id: UUID)
    func didFinishDownloading(for id: UUID)
}

protocol Downloader {
    var delegate: DownloadDelegate? { get set }
    func download(from fileMetaData: FileMetaData)
    func updateDownloadList(_ list: [FileMetaData])
}
