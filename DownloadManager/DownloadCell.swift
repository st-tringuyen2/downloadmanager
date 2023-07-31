//
//  DownloadCell.swift
//  DownloadManager
//
//  Created by Tri Nguyen T. [2] on 31/07/2023.
//

import UIKit

class DownloadCell: UITableViewCell {
    @IBOutlet private var progressView: UIProgressView!
    @IBOutlet private var fileNameLabel: UILabel!
    @IBOutlet private var fileSizeLabel: UILabel!
    @IBOutlet private var startPauseButton: UIButton!
    @IBOutlet private var cancelButton: UIButton!
}
