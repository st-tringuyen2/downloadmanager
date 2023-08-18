//
//  DownloadManagerComposer.swift
//  DownloadManager
//
//  Created by Tri Nguyen T. [2] on 01/08/2023.
//

import UIKit
import Downloader

extension UserDefaults: DownloadStore {
    
    func getDownloadList() -> [FileSave] {
        guard let fileData = object(forKey: "file-download-key") as? Data else{ return [] }

        let decoder = JSONDecoder()
        let fileSaved = try? decoder.decode([FileSave].self, from: fileData)
        
        return fileSaved ?? []
    }
    
    private func save(_ files: [FileSave]) {
        let encoder = JSONEncoder()
        if let fileEncoded = try? encoder.encode(files) {
            setValue(fileEncoded, forKey: "file-download-key")
        }
    }
    
    func saveDownloadFile(_ file: FileSave) {
        var fileData = getDownloadList()
        fileData.insert(file, at: 0)
        
        save(fileData)
    }
  
    func updateDownloadFile(_ file: FileSave) {
        var fileData = getDownloadList()
        
        if let index = fileData.firstIndex(where: { $0.id == file.id }) {
            fileData[index] = file
            save(fileData)
        }
    }
    
    func updateProgress(_ progress: Float, for fileID: UUID) {
        if var savedFile = getFileSaved(from: fileID) {
            savedFile.progress = progress
            updateDownloadFile(savedFile)
        }
    }
    
    func updateDownloadStatus(_ status: DownloadState, for fileID: UUID) {
        if var savedFile = getFileSaved(from: fileID) {
            savedFile.status = status
            updateDownloadFile(savedFile)
        }
    }
    
    func updateDownloadLocation(_ location: URL, for fileID: UUID) {
        if var savedFile = getFileSaved(from: fileID) {
            savedFile.saveLocation = location
            updateDownloadFile(savedFile)
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
