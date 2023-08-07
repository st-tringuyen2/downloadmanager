//
//  DownloadManagerViewModel.swift
//  DownloadManager
//
//  Created by Tri Nguyen T. [2] on 01/08/2023.
//

import Foundation

struct FileSave: Codable {
    let id: UUID
    let name: String
    let size: Int
    let url: URL
    let saveLocation: URL
    var progress: Float
    var status: DownloadState
}

protocol DownloadStore {
    func getDownloadList() -> [FileSave]
    func saveDownloadFile(_ file: FileSave)
    func updateProgress(_ progress: Float, to file: FileSave)
}

class DownloadManagerViewModel {
    var updateProgress: ((Float, Int) -> Void)?
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
        downloadList.insert(DownloadCellModel(id: fileMetaData.id.uuidString, fileName: fileMetaData.name, fileSize: fileSizeString, state: .downloading, progress: 0), at: 0)
        downloadStore.saveDownloadFile(FileSave(id: fileMetaData.id, name: fileMetaData.name, size: fileMetaData.size, url: fileMetaData.url, saveLocation: fileMetaData.saveLocation, progress: 0, status: .downloading))
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
            if let fileSaved = downloadStore.getDownloadList().first(where: { $0.id == id }) {
                downloadStore.updateProgress(progress, to: fileSaved)
            }
        }
    }
    
    func didFinishDownloading(to location: URL, for id: UUID) {
        print("finish download to \(location)")
    }
}
