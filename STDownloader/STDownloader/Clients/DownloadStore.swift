//
//  Store.swift
//  STDownloader
//
//  Created by Tri Nguyen T. [2] on 18/08/2023.
//

import Foundation

public struct FileSave: Codable {
    public let id: UUID
    public let name: String
    public let size: Int
    public let type: FileType
    public let url: URL
    public var saveLocation: URL
    public var progress: Float
    public var status: DownloadState
    
    public init(id: UUID, name: String, size: Int, type: FileType, url: URL, saveLocation: URL, progress: Float, status: DownloadState) {
        self.id = id
        self.name = name
        self.size = size
        self.type = type
        self.url = url
        self.saveLocation = saveLocation
        self.progress = progress
        self.status = status
    }
}

public protocol DownloadStore {
    func getDownloadList() -> [FileSave]
    func saveDownloadFile(_ file: FileSave)
    func updateProgress(_ progress: Float, for fileID: UUID)
    func updateDownloadStatus(_ status: DownloadState, for fileID: UUID)
    func updateDownloadLocation(_ location: URL, for fileID: UUID)
}
