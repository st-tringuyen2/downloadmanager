//
//  DownloadManagerComposer.swift
//  DownloadManager
//
//  Created by Tri Nguyen T. [2] on 01/08/2023.
//

import UIKit

extension UserDefaults: DownloadStore {
    
    func getDownloadList() -> [FileSave] {
        guard let fileData = object(forKey: "file-download-key") as? Data else{ return [] }

        let decoder = JSONDecoder()
        let fileSaved = try? decoder.decode([FileSave].self, from: fileData)
        
        return fileSaved ?? []
    }
    
    func saveDownloadFile(_ file: FileSave) {
        var fileData = getDownloadList()
        fileData.insert(file, at: 0)

        let encoder = JSONEncoder()
        if let fileEncoded = try? encoder.encode(fileData) {
            setValue(fileEncoded, forKey: "file-download-key")
        }
    }
    
    func updateProgress(_ progress: Float, for fileID: UUID) {
        if var savedFile = getFileSaved(from: fileID) {
            savedFile.progress = progress
            saveDownloadFile(savedFile)
        }
    }
    
    func updateDownloadStatus(_ status: DownloadState, for fileID: UUID) {
        if var savedFile = getFileSaved(from: fileID) {
            savedFile.status = status
            saveDownloadFile(savedFile)
        }
    }
    
    private func getFileSaved(from id: UUID) -> FileSave? {
        getDownloadList().first(where: { $0.id == id })
    }
}

class DownloadManagerComposer {
    
    static func makeDownloadManagerViewController(downloader: Downloader) -> DownloadManagerViewController {
        let downloadManagerViewModel = DownloadManagerViewModel(downloader: downloader, downloadStore: UserDefaults.standard)
        let downloadManagerViewController = DownloadManagerViewController(viewModel: downloadManagerViewModel)
        
        return downloadManagerViewController
    }
}
