//
//  URLSessionDownloadClient.swift
//  DownloadManager
//
//  Created by Tri Nguyen T. [2] on 01/08/2023.
//

import Foundation


public protocol FileDownloadClientDelegate: AnyObject {
    func didComplete(with error: Error, for id: UUID, at part: Int)
    func downloadingProgress(_ progress: Float, for id: UUID, at part: Int)
    func didFinishDownloading(to location: URL, for id: UUID, at part: Int)
    func restoreDownloadSession(for id: UUID, part: Int)
}

public class URLSessionDownloadClient: NSObject, FileDownloadClient {
    
    struct ResumeError: Error {}
    
    private var activeDownloadsMap = [UUID: [Int: URLSessionDownloadTask]]()
    private var resumeData = [UUID: [Int: Data]]()
    
    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.background(withIdentifier: "ST-Download-Manager-Download-Session")
        let session = URLSession(configuration: config, delegate: self, delegateQueue: .none)
        
        return session
    }()
    
    public weak var delegate: FileDownloadClientDelegate?
    
    override public init() {
        super.init()
        restoreDownloadSession()
    }
    
    private func restoreDownloadSession() {
        session.getAllTasks { [weak self] tasks in
            tasks.forEach { task in
                if let downloadTask = task as? URLSessionDownloadTask, let (id, part) = self?.createUUIDAndPart(from: downloadTask) {
                    self?.updateActiveDownloadTask(id, part, downloadTask)
                    self?.delegate?.restoreDownloadSession(for: id, part: part)
                }
            }
        }
    }
    
    private func createUUIDAndPart(from task: URLSessionTask) -> (uuid: UUID, part: Int)? {
        if let taskDescription = task.taskDescription {
            let subTaskDescription = taskDescription.split(separator: ".")
            if let id = subTaskDescription.first, let part = subTaskDescription.last,  let uuid = UUID(uuidString: String(id)),
               let part = Int(part) {
                return (uuid, part)
            }
        }
        
        return nil
    }
    
    private func updateResumeData(_ id: UUID, _ resumeData: Data, _ part: Int) {
        if var dataDict = self.resumeData[id] {
            dataDict[part] = resumeData
        } else {
            self.resumeData[id] = [part: resumeData]
        }
    }
    
    private func updateActiveDownloadTask(_ id: UUID, _ part: Int, _ downloadTask: URLSessionDownloadTask) {
        if var activeDownload = activeDownloadsMap[id] {
            activeDownload[part] = downloadTask
            activeDownloadsMap[id] = activeDownload
        } else {
            activeDownloadsMap[id] = [part: downloadTask]
        }
    }
    
    public func download(from fileMetaData: FileMetaData, for part: Int, with range: HTTPRangeRequestHeader?) {
        var request = URLRequest(url: fileMetaData.url)
        if let range = range {
            request.setValue("bytes=\(range.start)-\(range.end)", forHTTPHeaderField: "Range")
        }
        let downloadTask = session.downloadTask(with: request)
        downloadTask.taskDescription = fileMetaData.id.uuidString + "." + String(part)
        downloadTask.resume()
        updateActiveDownloadTask(fileMetaData.id, part, downloadTask)
    }
    
    public func pause(id: UUID) {
        if let activateDownload = activeDownloadsMap[id] {
            for (_, task) in activateDownload {
                task.cancel()
            }
        }
    }
    
    public func resume(id: UUID, with ranges: [HTTPRangeRequestHeader]?) {
        if let resumeData = resumeData[id] {
            for (index, data) in resumeData {
                let task = session.downloadTask(withResumeData: data)
                task.resume()
                updateActiveDownloadTask(id, index, task)
            }
        } else {
            if let ranges = ranges, !ranges.isEmpty {
                for (index, _) in ranges.enumerated() {
                    delegate?.didComplete(with: ResumeError(), for: id, at: index)
                }
            } else {
                delegate?.didComplete(with: ResumeError(), for: id, at: 0)
            }
        }
    }
}

extension URLSessionDownloadClient: URLSessionDownloadDelegate {
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let error = error as? NSError, let (uuid, part) = createUUIDAndPart(from: task) else { return }
        
        let userInfo = (error as NSError).userInfo
        if let resumeData = userInfo[NSURLSessionDownloadTaskResumeData] as? Data {
            updateResumeData(uuid, resumeData, part)
        }
        
        delegate?.didComplete(with: error, for: uuid, at: part)
    }
    
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        if let (uuid, part) = createUUIDAndPart(from: downloadTask) {
            delegate?.didFinishDownloading(to: location, for: uuid, at: part)
        }
    }
    
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let calculatedProgress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
        
        if let (uuid, part) = createUUIDAndPart(from: downloadTask) {
            delegate?.downloadingProgress(calculatedProgress, for: uuid, at: part)
        }
    }
}


public class URLSessionHTTPClient: HTTPClient {
    private var session: URLSession
    
    public init(session: URLSession = .shared) {
        self.session = session
    }
    
    public func get(from url: URL, with method: HTTPMethod, completion: @escaping (Result<(Data, HTTPURLResponse), Error>) -> Void) {
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

public enum HTTPMethod: String {
    case GET
    case HEAD
}

public protocol HTTPClient {
    func get(from url: URL, with method: HTTPMethod, completion: @escaping (Result<(Data, HTTPURLResponse), Error>) -> Void)
}
