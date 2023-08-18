//
//  Downloader.swift
//  DownloadManager
//
//  Created by Tri Nguyen T. [2] on 01/08/2023.
//

import Foundation

public struct FileMetaData {
    public let id: UUID
    public let url: URL
    public let name: String
    public let size: Int
    public var type: FileType
    public var saveLocation: URL
    public var state: DownloadState
    public var progress: Float?
    
    public init(id: UUID, url: URL, name: String, size: Int, type: FileType, saveLocation: URL, state: DownloadState, progress: Float? = nil) {
        self.id = id
        self.url = url
        self.name = name
        self.size = size
        self.type = type
        self.saveLocation = saveLocation
        self.state = state
        self.progress = progress
    }
}

public enum FileType: Int, Codable {
    case file = 0
    case hls
}

public enum DownloadState: Int, Codable {
    case notDownload
    case downloading
    case pause
    case downloaded
    case failed
}


public protocol DownloadDelegate: AnyObject {
    func didComplete(with error: Error, for id: UUID)
    func downloadingProgess(_ progress: Float, for id: UUID)
    func didFinishDownloading(for id: UUID)
    func willDownloadTo(location: URL, for id: UUID)
}

public protocol Downloader {
    var delegate: DownloadDelegate? { get set }
    func download(from fileMetaData: FileMetaData)
    func pause(id: UUID)
    func resume(id: UUID)
    func updateDownloadList(_ list: [FileMetaData])
}
