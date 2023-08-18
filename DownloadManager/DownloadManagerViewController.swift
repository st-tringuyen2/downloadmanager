//
//  DownloadManagerViewController.swift
//  DownloadManager
//
//  Created by Tri Nguyen T. [2] on 31/07/2023.
//

import UIKit
import STDownloader

class DownloadManagerViewController: UIViewController {
    @IBOutlet private var tableView: UITableView!
    @IBOutlet private var addDownloadButton: UIButton!
    
    private var viewModel: DownloadManagerViewModel
    
    init(viewModel: DownloadManagerViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        handleEventFromViewModel()
    }
    
    private func configureUI() {
        title = "Download Manager"
        let nib = UINib(nibName: String(describing: DownloadCell.self), bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: String(describing: DownloadCell.self))
    }
    
    @IBAction private func onAddDownloadButtonTapped() {
        let viewModel = NewDowloadViewModel(httpClient: URLSessionHTTPClient())
        let newDownloadVC = NewDownloadViewController(viewModel: viewModel)
        newDownloadVC.titleLabelText = "New Download"
        newDownloadVC.onStartDownload = { [weak self] fileDownload in
            var fileMetaData = fileDownload
            fileMetaData.state = .downloading
            self?.startDownload(from: fileMetaData)
            self?.tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
        }
        present(newDownloadVC, animated: true)
    }
}

extension DownloadManagerViewController {
    private func startDownload(from fileMetaData: FileMetaData) {
        viewModel.download(from: fileMetaData)
    }
    
    private func handleEventFromViewModel() {
        viewModel.updateProgress = { [weak self] progress, index in
            let indexPath = IndexPath(row: index, section: 0)
            if let cell = self?.tableView.cellForRow(at: indexPath) as? DownloadCell {
                cell.updateProgress(progress)
            }
        }
        
        viewModel.updateStatus = { [weak self] status, index in
            let indexPath = IndexPath(row: index, section: 0)
            if let cell = self?.tableView.cellForRow(at: indexPath) as? DownloadCell {
                cell.updateDownloadState(status)
            }
        }
    }
}

extension DownloadManagerViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numbersOfItems
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: DownloadCell.self)) as! DownloadCell
        let model = viewModel.item(for: indexPath.row)
        cell.updateUI(with: model)
        cell.onCancelDownload = { [weak self] in
            
        }
        
        cell.onPauseResumeDownload = { [weak self] in
            self?.viewModel.pause(from: UUID(uuidString: model.id)!)
        }
        
        return cell
    }
}
