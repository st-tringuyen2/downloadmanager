//
//  AVAssetDownloadURLSessionClient.swift
//  DownloadManager
//
//  Created by Tri Nguyen T. [2] on 08/08/2023.
//

import AVFoundation
import UserNotifications

protocol HLSDownloadClientDelegate: AnyObject {
    func willDownload(to location: URL, for id: UUID)
    func didComplete(with error: Error, for id: UUID)
    func downloadingProgress(_ progress: Float, for id: UUID)
    func didFinishDownloading(for id: UUID)
}

class AVAssetDownloadURLSessionClient: NSObject, HLSDownloadClient {
    
    private var activeDownloadsMap = [UUID: AVAggregateAssetDownloadTask]()
    
    private lazy var downloadSession: AVAssetDownloadURLSession = {
        let config = URLSessionConfiguration.background(withIdentifier: "ST-Download-Manager-HLS-Download-id")
        let session = AVAssetDownloadURLSession(configuration: config, assetDownloadDelegate: self, delegateQueue: nil)
        
        return session
    }()
    
    weak var delegate: HLSDownloadClientDelegate?
    
    func download(from fileMetaData: FileMetaData) {
        let asset = AVURLAsset(url: fileMetaData.url)
        let preferredMediaSelection = asset.preferredMediaSelection
        
        guard let downloadTask = downloadSession.aggregateAssetDownloadTask(with: asset, mediaSelections: [preferredMediaSelection], assetTitle: fileMetaData.name, assetArtworkData: nil) else { return }
        downloadTask.taskDescription = fileMetaData.id.uuidString
        downloadTask.resume()
        activeDownloadsMap[fileMetaData.id] = downloadTask
    }
    
    func pause(id: UUID) {
        let task = activeDownloadsMap.first(where: { $0.key == id })?.value
        task?.suspend()
    }
    
    func resume(id: UUID) {
        let task = activeDownloadsMap.first(where: { $0.key == id })?.value
        task?.resume()
    }
    
    func resume(fileMetaData: FileMetaData) {
        if let task = activeDownloadsMap.first(where: { $0.key == fileMetaData.id })?.value, task.state == .suspended {
            task.resume()
        } else {
            let asset = AVURLAsset(url: fileMetaData.saveLocation)
            let preferredMediaSelection = asset.preferredMediaSelection
            
            guard let downloadTask = downloadSession.aggregateAssetDownloadTask(with: asset, mediaSelections: [preferredMediaSelection], assetTitle: fileMetaData.name, assetArtworkData: nil) else { return }
            downloadTask.taskDescription = fileMetaData.id.uuidString
            downloadTask.resume()
            activeDownloadsMap[fileMetaData.id] = downloadTask
        }
    }
}

extension AVAssetDownloadURLSessionClient: AVAssetDownloadDelegate {
    func urlSession(_ session: URLSession, aggregateAssetDownloadTask: AVAggregateAssetDownloadTask, willDownloadTo location: URL) {
        print("Will download to: \(location)")
        if let id = getUUID(from: aggregateAssetDownloadTask) {
            delegate?.willDownload(to: location, for: id)
        }
    }
    
    func urlSession(_ session: URLSession, aggregateAssetDownloadTask: AVAggregateAssetDownloadTask, didLoad timeRange: CMTimeRange, totalTimeRangesLoaded loadedTimeRanges: [NSValue], timeRangeExpectedToLoad: CMTimeRange, for mediaSelection: AVMediaSelection) {
        var percentComplete = 0.0
        for value in loadedTimeRanges {
            let loadedTimeRange: CMTimeRange = value.timeRangeValue
            percentComplete +=
            loadedTimeRange.duration.seconds / timeRangeExpectedToLoad.duration.seconds
        }
      
        if let id = getUUID(from: aggregateAssetDownloadTask) {
            delegate?.downloadingProgress(Float(percentComplete), for: id)
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        print("Download did complete with error: \(String(describing: error))")
        guard let assetDownloadTask = task as? AVAggregateAssetDownloadTask, let id = getUUID(from: assetDownloadTask) else { return }
        
        activeDownloadsMap[id] = assetDownloadTask
        if let error = error {
            delegate?.didComplete(with: error, for: id)
        } else {
            delegate?.didFinishDownloading(for: id)
        }
    }
    
    func urlSession(_ session: URLSession, assetDownloadTask: AVAssetDownloadTask, didFinishDownloadingTo location: URL) {
        print("Did finish download to \(location)")
    }
}

extension AVAssetDownloadURLSessionClient {
    func getUUID(from task: AVAggregateAssetDownloadTask) -> UUID? {
        return activeDownloadsMap.first(where: { $0.value === task })?.key
    }
}
