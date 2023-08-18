//
//  NewDowloadViewModel.swift
//  DownloadManager
//
//  Created by Tri Nguyen T. [2] on 01/08/2023.
//

import Foundation
import STDownloader

class NewDowloadViewModel {
    
    enum Error: Swift.Error {
        case connectivity
        case invalidData
        case unsupportedURL
        case failedToCreateFile
        
        var localizedDescription: String {
            var description = ""
            switch self {
            case .connectivity: description = "Can not request data"
            case .invalidData: description = "Meta data is invalid"
            case .unsupportedURL: description = "System does not support download this content"
            case .failedToCreateFile: description = "System does not support to create file"
            }
            
            return description
        }
    }
    
    private lazy var downloasdDirectory: URL = {
        let url = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        
        return url.first!
    }()
    
    private lazy var appDownloadFolder: URL = {
        let url = downloasdDirectory.appendingPathComponent("ST Download Manager")
        
        return url
    }()

    private var downloadURL: URL?
    
    private var httpClient: HTTPClient
    private let fileManager: FileManager
    
    init(httpClient: HTTPClient, fileManager: FileManager = .default) {
        self.httpClient = httpClient
        self.fileManager = fileManager
        createDownloadFolder()
    }
    
    func getMetaData(from url: URL, completion: @escaping (Result<FileMetaData, Error>) -> Void) {
        downloadURL = url
        httpClient.get(from: url, with: .HEAD) { [weak self] result in
            switch result {
            case let .success((_, response)):
                self?.validateMetaData(from: response, completion: completion)
            case .failure:
                completion(.failure(.connectivity))
            }
        }
    }
    
    private func validateMetaData(from response: HTTPURLResponse, completion: @escaping (Result<FileMetaData, Error>) -> Void) {
        guard response.statusCode == 200 else { return completion(.failure(Error.invalidData)) }
        if response.mimeType?.contains("html") == true {
            completion(.failure(.unsupportedURL))
            return
        }
        
        var type: FileType
        // Type HLS reference:  https://developer.apple.com/documentation/http-live-streaming/deploying-a-basic-http-live-streaming-hls-stream#Configure-a-web-server
        if response.mimeType?.contains("mpegurl") == true
            || response.suggestedFilename?.contains("m3u8") == true
        {
            type = .hls
        } else {
            type = .file
        }
        let fileName = response.suggestedFilename ?? "Unknow"
        if let fileLocation = createEmptyFile(with: fileName), let downloadURL = downloadURL {
            let fileMetaData = FileMetaData(id: UUID(), url: downloadURL, name: fileLocation.lastPathComponent, size: Int(response.expectedContentLength), type: type, saveLocation: fileLocation, state: .notDownload)

            completion(.success(fileMetaData))
        } else {
            completion(.failure(.failedToCreateFile))
        }
    }
}

extension NewDowloadViewModel {
    private func createDownloadFolder() {
        if !fileManager.fileExists(atPath: appDownloadFolder.path) {
            try? fileManager.createDirectory(at: appDownloadFolder, withIntermediateDirectories: true)
        }
    }
    
    private func createEmptyFile(with fileName: String) -> URL? {
        var finalName = fileName
        var count = 0
        while fileManager.fileExists(atPath: appDownloadFolder.appendingPathComponent(finalName).path) {
            count += 1
            finalName = fileName
            if let index = fileName.lastIndex(of: ".") {
                finalName.insert(contentsOf: "(\(count))", at: index)
            }
        }
        let fileLocation = appDownloadFolder.appendingPathComponent(finalName)
        
        if fileManager.createFile(atPath: fileLocation.path, contents: nil) {
            return fileLocation
        } else {
            return nil
        }
    }
}
