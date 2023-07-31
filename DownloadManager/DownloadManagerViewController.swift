//
//  DownloadManagerViewController.swift
//  DownloadManager
//
//  Created by Tri Nguyen T. [2] on 31/07/2023.
//

import UIKit

class DownloadManagerViewController: UIViewController {
    @IBOutlet private var tableView: UITableView!
    @IBOutlet private var addDownloadButton: UIButton!
    
    @IBAction private func onAddDownloadButtonTapped() {
        
    }
}

extension DownloadManagerViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 10
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return UITableViewCell()

    }
}
