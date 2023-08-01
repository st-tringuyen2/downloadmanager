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
    private var httpClient: HTTPClient
    
    private var downloadURL: URL?
    private var saveLocation: URL?
    private var fileName: String?
    private var fileSize: Double?
    
    init(httpClient: HTTPClient) {
        self.httpClient = httpClient
    }
    
    func getMetaData(from url: URL, completion: @escaping (Result<String, Error>) -> Void) {
        downloadURL = url
        httpClient.get(from: url, with: .HEAD) { result in
            switch result {
            case let .success((_, response)):
                completion(.success(response.suggestedFilename ?? "Unknow"))
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }
}
