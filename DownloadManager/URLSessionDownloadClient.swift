//
//  URLSessionDownloadClient.swift
//  DownloadManager
//
//  Created by Tri Nguyen T. [2] on 01/08/2023.
//

import Foundation

protocol DownloadClientDelegate: AnyObject {
    func didComplete(with error: Error, for id: UUID, at part: Int)
    func downloadingProgress(_ progress: Float, for id: UUID, at part: Int)
    func didFinishDownloading(to location: URL, for id: UUID, at part: Int)
    func restoreDownloadSession(for id: UUID, part: Int)
}

class URLSessionDownloadClient: NSObject, DownloadClient {
    private var activeDownloadsMap = [UUID: [Int: URLSessionDownloadTask]]()
    private var resumeData = [UUID: [Int: Data]]()

    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.background(withIdentifier: "ST-Download-Manager-Download-Session")
        let session = URLSession(configuration: config, delegate: self, delegateQueue: .none)
        
        return session
    }()
    
    weak var delegate: DownloadClientDelegate?
    
    override init() {
        super.init()
        restoreDownloadSession()
    }
    
    private func restoreDownloadSession() {
        session.getAllTasks { [weak self] tasks in
            tasks.forEach { task in
                guard task.state != .completed else { return }
                if let error = task.error as? NSError {
                    let userInfo = error.userInfo
                    if let downloadTask = task as? URLSessionDownloadTask, let resumeData = userInfo[NSURLSessionDownloadTaskResumeData] as? Data {
                        if let (id, part) = self?.createUUIDAndPart(from: downloadTask) {
                            self?.updateActiveDownloadTask(id, part, downloadTask)
                            self?.updateResumeData(id, resumeData, part)
                            self?.delegate?.restoreDownloadSession(for: id, part: part)
                        }
                    }
                } else if let downloadTask = task as? URLSessionDownloadTask, let (id, part) = self?.createUUIDAndPart(from: downloadTask) {
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
    
    func download(from fileMetaData: FileMetaData, for part: Int, with range: HTTPRangeRequestHeader?) {
        var request = URLRequest(url: fileMetaData.url)
        if let range = range {
            request.setValue("bytes=\(range.start)-\(range.end)", forHTTPHeaderField: "Range")
        }
        let downloadTask = session.downloadTask(with: request)
        downloadTask.taskDescription = fileMetaData.id.uuidString + "." + String(part)
        downloadTask.resume()
        updateActiveDownloadTask(fileMetaData.id, part, downloadTask)
    }
}

extension URLSessionDownloadClient: URLSessionDownloadDelegate {
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let (uuid, part) = createUUIDAndPart(from: task), let error = error {
            delegate?.didComplete(with: error, for: uuid, at: part)
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        if let (uuid, part) = createUUIDAndPart(from: downloadTask) {
            delegate?.didFinishDownloading(to: location, for: uuid, at: part)
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let calculatedProgress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
        
        if let (uuid, part) = createUUIDAndPart(from: downloadTask) {
            delegate?.downloadingProgress(calculatedProgress, for: uuid, at: part)
        }
    }
}
