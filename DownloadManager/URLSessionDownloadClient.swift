//
//  URLSessionDownloadClient.swift
//  DownloadManager
//
//  Created by Tri Nguyen T. [2] on 01/08/2023.
//

import Foundation

class URLSessionDownloadClient: NSObject, DownloadClient {
    private var activeDownloadsMap = [UUID: [Int: URLSessionDownloadTask]]()

    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.background(withIdentifier: "String(describing: self)")
        let session = URLSession(configuration: config, delegate: self, delegateQueue: .none)
        
        return session
    }()
    
    override init() {
        super.init()
        restoreDownloadSession()
    }
    
    private func restoreDownloadSession() {
        session.getAllTasks { tasks in
            tasks.forEach { task in
                guard task.state != .completed else { return }
                if let error = task.error as? NSError {
                    let userInfo = error.userInfo
                    if let resumeData = userInfo[NSURLSessionDownloadTaskResumeData] as? Data {
                        let downloadTask = self.session.downloadTask(withResumeData: resumeData)
                        downloadTask.resume()
                        if let (id, part) = self.createUUIDAndPart(from: downloadTask) {
                            self.updateActiveDownloadTask(id, part, downloadTask)
                        }
                    }
                } else if let downloadTask = task as? URLSessionDownloadTask, let (id, part) = self.createUUIDAndPart(from: downloadTask) {
                    self.updateActiveDownloadTask(id, part, downloadTask)
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
        if let (uuid, part) = createUUIDAndPart(from: task) {
            print(uuid, part)
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        if let (uuid, part) = createUUIDAndPart(from: downloadTask) {
            print(uuid, part)
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        if let (uuid, part) = createUUIDAndPart(from: downloadTask) {
            print(uuid, part)
        }
    }
}