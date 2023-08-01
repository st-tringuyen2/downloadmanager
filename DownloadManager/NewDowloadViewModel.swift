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

class NewDowloadViewModel {
    
    enum Error: Swift.Error {
        case invalidData
        
        var localizedDescription: String {
            var description = ""
            switch self {
            case .invalidData: description = "Meta data is invalid"
            }
            
            return description
        }
    }
    
    private lazy var downloasdDirectory: URL = {
        let url = fileManager.urls(for: .downloadsDirectory, in: .userDomainMask)
        
        return url.first!
    }()
    
    private lazy var appDownloadFolder: URL = {
        let url = downloasdDirectory.appendingPathComponent("ST Download Manager")
        
        return url
    }()

    private var downloadURL: URL?
    private var saveLocation: URL?
    private var fileName: String?
    private var fileSize: Double?
    
    private var httpClient: HTTPClient
    private let fileManager: FileManager
    
    init(httpClient: HTTPClient, fileManager: FileManager = .default) {
        self.httpClient = httpClient
        self.fileManager = fileManager
        createDownloadFolder()
    }
    
    func getMetaData(from url: URL, completion: @escaping (Result<String, Error>) -> Void) {
        downloadURL = url
        httpClient.get(from: url, with: .HEAD) { [weak self] result in
            switch result {
            case let .success((_, response)):
                self?.validateMetaData(from: response, completion: completion)
            case .failure:
                completion(.failure(.invalidData))
            }
        }
    }
    
    private func validateMetaData(from response: HTTPURLResponse, completion: @escaping (Result<String, Error>) -> Void) {
        guard response.statusCode == 200 else { return completion(.failure(Error.invalidData)) }
        let fileName = response.suggestedFilename ?? "Unknow"
        if createEmptyFile(with: fileName) {
            completion(.success(fileName) )
        }
    }
}

extension NewDowloadViewModel {
    private func createDownloadFolder() {
        if !fileManager.fileExists(atPath: appDownloadFolder.path) {
            try? fileManager.createDirectory(at: appDownloadFolder, withIntermediateDirectories: true)
        }
    }
    
    private func createEmptyFile(with fileName: String) -> Bool {
        var finalName = fileName
        var count = 0
        while fileManager.fileExists(atPath: appDownloadFolder.appendingPathComponent(finalName).path) {
            count += 1
            finalName = fileName
            if let index = fileName.lastIndex(of: ".") {
                finalName.insert(contentsOf: "(\(count))", at: index)
            }
        }
        let filePath = appDownloadFolder.appendingPathComponent(finalName).path
        
        return fileManager.createFile(atPath: filePath, contents: nil)
    }
}
