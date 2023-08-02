//
//  DownloadManagerViewModel.swift
//  DownloadManager
//
//  Created by Tri Nguyen T. [2] on 01/08/2023.
//

import Foundation

class DownloadManagerViewModel {
    var updateProgress: ((Float, Int) -> Void)?
    private var downloadList = [DownloadCellModel]()
    
    private var downloader: Downloader
    
    init(downloader: Downloader) {
        self.downloader = downloader
        self.downloader.delegate = self
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
        downloader.download(from: fileMetaData)
        updateDownloadList(from: fileMetaData)
    }
    
    func updateDownloadList(from fileMetaData: FileMetaData) {
        let fileSize: Float = Float(fileMetaData.size / 1024 / 1024)
        let fileSizeString = "\(fileSize) MB"
        downloadList.insert(DownloadCellModel(id: fileMetaData.id.uuidString, fileName: fileMetaData.name, fileSize: fileSizeString, state: .downloading), at: 0)
    }
}

extension DownloadManagerViewModel: DownloadDelegate {
    func getIndex(for id: String) -> Int? {
        return downloadList.firstIndex(where: { $0.id == id })
    }
    
    func didComplete(with error: Error, for id: UUID) {
        print(error)
    }
    
    func downloadingProgess(_ progress: Float, for id: UUID) {
        if let downloadIndex = getIndex(for: id.uuidString) {
            DispatchQueue.main.async { [weak self] in
                self?.updateProgress?(progress, downloadIndex)
            }
        }
    }
    
    func didFinishDownloading(to location: URL, for id: UUID) {
        print("finish download to \(location)")
    }
}
