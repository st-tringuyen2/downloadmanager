//
//  DownloadCell.swift
//  DownloadManager
//
//  Created by Tri Nguyen T. [2] on 31/07/2023.
//

import UIKit
import STDownloader

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
    
    var onCancelDownload: (() -> Void)?
    var onPauseResumeDownload: (() -> Void)?
    
    @IBAction private func onCancelTapped() {
        onCancelDownload?()
    }
    
    @IBAction private func onPauseResumeTapped() {
        onPauseResumeDownload?()
    }
    
    func updateUI(with model: DownloadCellModel) {
        fileNameLabel.text = model.fileName
        fileSizeLabel.text = model.fileSize
        updateButtonState(with: model.state)
        updateDownloadState(model.state)
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
    
    func updateDownloadState(_ state: DownloadState) {
        if state == .downloaded {
            startPauseButton.isHidden = true
            cancelButton.isHidden = true
            progressView.isHidden = true
        } else if state == .failed {
            startPauseButton.setImage(UIImage(systemName: "gobackward"), for: .normal)
        }
    }
}
