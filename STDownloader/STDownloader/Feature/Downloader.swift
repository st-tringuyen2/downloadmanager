//
//  Downloader.swift
//  DownloadManager
//
//  Created by Tri Nguyen T. [2] on 01/08/2023.
//

import Foundation

struct FileMetaData {
    let id: UUID
    let url: URL
    let name: String
    let size: Int
    var saveLocation: URL
    var state: DownloadState
    var progress: Float?
}

enum DownloadState: Int, Codable {
    case notDownload
    case downloading
    case pause
    case downloaded
    case failed
}


protocol DownloadDelegate: AnyObject {
    func didComplete(with error: Error, for id: UUID)
    func downloadingProgess(_ progress: Float, for id: UUID)
    func didFinishDownloading(for id: UUID)
    func willDownloadTo(location: URL, for id: UUID)
}

protocol Downloader {
    var delegate: DownloadDelegate? { get set }
    func download(from fileMetaData: FileMetaData)
    func pause(id: UUID)
    func resume(id: UUID)
    func updateDownloadList(_ list: [FileMetaData])
}
