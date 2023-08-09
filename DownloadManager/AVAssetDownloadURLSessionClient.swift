//
//  AVAssetDownloadURLSessionClient.swift
//  DownloadManager
//
//  Created by Tri Nguyen T. [2] on 08/08/2023.
//

import AVFoundation

class AVAssetDownloadURLSessionClient: NSObject, HLSDownloadClient {
    private var activeDownloadsMap = [UUID: AVAggregateAssetDownloadTask]()
    
    private lazy var downloadSession: AVAssetDownloadURLSession = {
        let config = URLSessionConfiguration.background(withIdentifier: "ST-Download-Manager-HLS-Download")
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
        print("Downloading progress: \(percentComplete)")
        if let id = getUUID(from: aggregateAssetDownloadTask) {
            delegate?.downloadingProgress(Float(percentComplete), for: id)
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        print("Download did complete with error: \(String(describing: error))")
        if let assetDownloadTask = task as? AVAggregateAssetDownloadTask, let id = getUUID(from: assetDownloadTask), let error = error {
            delegate?.didComplete(with: error, for: id)
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
