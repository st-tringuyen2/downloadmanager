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
    
    var downloadList = [DownloadCellModel]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
    }
    
    private func configureUI() {
        title = "Download Manager"
        let nib = UINib(nibName: String(describing: DownloadCell.self), bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: String(describing: DownloadCell.self))
    }
    
    @IBAction private func onAddDownloadButtonTapped() {
        let newDownloadVC = NewDownloadViewController()
        newDownloadVC.titleLabelText = "New Download"
        present(newDownloadVC, animated: true)
    }
}

extension DownloadManagerViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return downloadList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: DownloadCell.self)) as! DownloadCell
        let model = downloadList[indexPath.row]
        cell.updateUI(with: model)
        
        return cell
    }
}
