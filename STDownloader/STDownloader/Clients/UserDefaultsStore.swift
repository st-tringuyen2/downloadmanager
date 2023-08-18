//
//  UserDefaultsStore.swift
//  STDownloader
//
//  Created by Tri Nguyen T. [2] on 18/08/2023.
//

import Foundation

extension UserDefaults: DownloadStore {
    
    public func getDownloadList() -> [FileSave] {
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
    
    public func saveDownloadFile(_ file: FileSave) {
        var fileData = getDownloadList()
        fileData.insert(file, at: 0)
        
        save(fileData)
    }
    
    public func updateDownloadFile(_ file: FileSave) {
        var fileData = getDownloadList()
        
        if let index = fileData.firstIndex(where: { $0.id == file.id }) {
            fileData[index] = file
            save(fileData)
        }
    }
    
    public func updateProgress(_ progress: Float, for fileID: UUID) {
        if var savedFile = getFileSaved(from: fileID) {
            savedFile.progress = progress
            updateDownloadFile(savedFile)
        }
    }
    
    public func updateDownloadStatus(_ status: DownloadState, for fileID: UUID) {
        if var savedFile = getFileSaved(from: fileID) {
            savedFile.status = status
            updateDownloadFile(savedFile)
        }
    }
    
    public func updateDownloadLocation(_ location: URL, for fileID: UUID) {
        if var savedFile = getFileSaved(from: fileID) {
            savedFile.saveLocation = location
            updateDownloadFile(savedFile)
        }
    }
    
    private func getFileSaved(from id: UUID) -> FileSave? {
        getDownloadList().first(where: { $0.id == id })
    }
}
