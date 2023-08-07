//
//  DownloadCell.swift
//  DownloadManager
//
//  Created by Tri Nguyen T. [2] on 31/07/2023.
//

import UIKit

enum DownloadState: Int, Codable {
    case notDownload
    case downloading
    case pause
    case downloaded
    case failed
}

struct DownloadCellModel {
    let id: String
    let fileName: String
    let fileSize: String
    var state: DownloadState
    var progress: Float
    
    static var dumyList: [DownloadCellModel] = .init(repeating: DownloadCellModel(id: UUID().uuidString, fileName: "test", fileSize: "30 MB", state: .pause, progress: 0), count: 10)
}

class DownloadCell: UITableViewCell {
    @IBOutlet private var progressView: UIProgressView!
    @IBOutlet private var fileNameLabel: UILabel!
    @IBOutlet private var fileSizeLabel: UILabel!
    @IBOutlet private var startPauseButton: UIButton!
    @IBOutlet private var cancelButton: UIButton!
    
    func updateUI(with model: DownloadCellModel) {
        fileNameLabel.text = model.fileName
        fileSizeLabel.text = model.fileSize
        updateButtonState(with: model.state)
    }
    
    func updateProgress(_ progress: Float) {
        progressView.progress = progress
    }
    
    func updateButtonState(with state: DownloadState) {
        guard state != .downloaded else {
            startPauseButton.isHidden = true
            cancelButton.isHidden = true
            return
        }
        var image: UIImage?
        
        switch state {
        case .notDownload, .pause:
            image = UIImage(systemName: "play.circle")
        case .downloading:
            image = UIImage(systemName: "pause.circle")
        default: break
        }
        
        startPauseButton.setImage(image, for: .normal)
        cancelButton.isEnabled = state == .downloading || state == .pause
    }
}
