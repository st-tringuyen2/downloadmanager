//
//  NewDowloadViewModel.swift
//  DownloadManager
//
//  Created by Tri Nguyen T. [2] on 01/08/2023.
//

import Foundation

class URLSessionHTTPClient: HTTPClient {
    private var session: URLSession
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    func get(from url: URL, with method: HTTPMethod, completion: @escaping (Result<(Data, HTTPURLResponse), Error>) -> Void) {
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        session.dataTask(with: request) { data, response, error in
            if let data = data, let response = response as? HTTPURLResponse {
                completion(.success((data, response)))
                return
            }
            if let error = error {
                completion(.failure(error))
                return
            }
        }.resume()
    }
}

enum HTTPMethod: String {
    case GET
    case HEAD
}

protocol HTTPClient {
    func get(from url: URL, with method: HTTPMethod, completion: @escaping (Result<(Data, HTTPURLResponse), Error>) -> Void)
}

struct FileMetaData {
    let id: UUID
    let url: URL
    let name: String
    let size: Int
    var saveLocation: URL
    var state: DownloadState
    var progress: Float?
}

class NewDowloadViewModel {
    
    enum Error: Swift.Error {
        case connectivity
        case invalidData
        case unsupportedURL
        
        var localizedDescription: String {
            var description = ""
            switch self {
            case .connectivity: description = "Can not request data"
            case .invalidData: description = "Meta data is invalid"
            case .unsupportedURL: description = "System does not support download this content"
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
        let fileName = response.suggestedFilename ?? "Unknow"
        if let fileLocation = createEmptyFile(with: fileName), let downloadURL = downloadURL {
            let fileMetaData = FileMetaData(id: UUID(), url: downloadURL, name: fileLocation.lastPathComponent, size: Int(response.expectedContentLength), saveLocation: fileLocation, state: .notDownload)

            completion(.success(fileMetaData))
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
