//
//  DownloadManagerViewModel.swift
//  DownloadManager
//
//  Created by Tri Nguyen T. [2] on 01/08/2023.
//

import Foundation
import STDownloader

class DownloadManagerViewModel {
    var updateProgress: ((Float, Int) -> Void)?
    var updateStatus: ((DownloadState, Int) -> Void)?
    private var downloadList = [DownloadCellModel]()
    
    private var downloader: Downloader
    private var downloadStore: DownloadStore
    
    init(downloader: Downloader, downloadStore: DownloadStore) {
        self.downloader = downloader
        self.downloadStore = downloadStore
        self.downloader.delegate = self
       initDownloadList()
    }
    
    private func initDownloadList() {
        let listDownloadSaved = downloadStore.getDownloadList()
        downloadList = listDownloadSaved.map({ fileSaved in
            let fileSize: Float = Float(fileSaved.size / 1024 / 1024)
            let fileSizeString = "\(fileSize) MB"
            return DownloadCellModel(id: fileSaved.id.uuidString, fileName: fileSaved.name, fileSize: fileSizeString, state: fileSaved.status, progress: fileSaved.progress)
        })
        
        let listFileMetaData = listDownloadSaved.map({ FileMetaData(id: $0.id, url: $0.url, name: $0.name, size: $0.size, saveLocation: $0.saveLocation, state: $0.status)})
        downloader.updateDownloadList(listFileMetaData)
    }

    var numbersOfItems: Int {
        return downloadList.count
    }
    
    func item(for index: Int) -> DownloadCellModel {
        return downloadList[index]
    }
}

extension DownloadManagerViewModel {
    func download(from fileMetaData: FileMetaData) {
        updateDownloadList(from: fileMetaData)
        downloader.download(from: fileMetaData)
    }
    
    func updateDownloadList(from fileMetaData: FileMetaData) {
        let fileSize: Float = Float(fileMetaData.size / 1024 / 1024)
        let fileSizeString = "\(fileSize) MB"
        downloadList.insert(DownloadCellModel(id: fileMetaData.id.uuidString, fileName: fileMetaData.name, fileSize: fileSizeString, state: .downloading, progress: 0), at: 0)
        downloadStore.saveDownloadFile(FileSave(id: fileMetaData.id, name: fileMetaData.name, size: fileMetaData.size, url: fileMetaData.url, saveLocation: fileMetaData.saveLocation, progress: 0, status: .downloading))
    }
    
    func pause(from id: UUID) {
        downloader.pause(id: id)
    }
  
    func resume(from id: UUID) {
        downloader.resume(id: id)
    }
}

extension DownloadManagerViewModel: DownloadDelegate {
    func getIndex(for id: String) -> Int? {
        return downloadList.firstIndex(where: { $0.id == id })
    }
    
    func willDownloadTo(location: URL, for id: UUID) {
        downloadStore.updateDownloadLocation(location, for: id)
    }
    
    func didComplete(with error: Error, for id: UUID) {
        print(error)
        guard let downloadIndex = getIndex(for: id.uuidString) else { return }
        
        guard (error as NSError).code != NSURLErrorCancelled else {
            DispatchQueue.main.async { [weak self] in
                self?.updateStatus?(.pause, downloadIndex)
            }
            downloadStore.updateDownloadStatus(.pause, for: id)
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.updateStatus?(.failed, downloadIndex)
        }
        downloadStore.updateDownloadStatus(.failed, for: id)
    }
    
    func downloadingProgess(_ progress: Float, for id: UUID) {
        if let downloadIndex = getIndex(for: id.uuidString) {
            DispatchQueue.main.async { [weak self] in
                self?.updateProgress?(progress, downloadIndex)
            }
            downloadStore.updateProgress(progress, for: id)
        }
    }
    
    func didFinishDownloading(for id: UUID) {
        print("finish download for id: \(id)")
        downloadStore.updateDownloadStatus(.downloaded, for: id)
        if let downloadIndex = getIndex(for: id.uuidString) {
            DispatchQueue.main.async { [weak self] in
                self?.updateStatus?(.downloaded, downloadIndex)
            }
        }
    }
}
