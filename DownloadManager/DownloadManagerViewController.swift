//
//  DownloadManagerViewController.swift
//  DownloadManager
//
//  Created by Tri Nguyen T. [2] on 31/07/2023.
//

import UIKit

public struct HTTPRangeRequestHeader: Hashable {
    let start: Int
    let end: Int
}

protocol Downloader {
    func download(from fileMetaData: FileMetaData)
}

class FileDownloader: Downloader {
    private var numbersOfDownloadPart: Int {
        return 8
    }
    
    private var downloadList = [FileMetaData]()
    private var downloadPartLocations = [UUID: [URL]]()
    private var rangeRequests = [UUID: [HTTPRangeRequestHeader]]()
    
    func download(from fileMetaData: FileMetaData) {
        createRange(from: fileMetaData)
    }
    
    private func createRange(from fileMetaData: FileMetaData) {
        let sizeOfPart = fileMetaData.size / numbersOfDownloadPart
        
        guard sizeOfPart > 0 else { return }
        
        var startRange = 0
        var endRange = 0
        var ranges = [HTTPRangeRequestHeader]()
        var partLocations = [URL]()
        
        for i in 0..<numbersOfDownloadPart {
            let saveLocation = fileMetaData.saveLocation.appendingPathComponent(".part\(i)")
            partLocations.append(saveLocation)
            endRange += (sizeOfPart - 1)
            let range = HTTPRangeRequestHeader(start: startRange, end: i == numbersOfDownloadPart - 1 ? fileMetaData.size : endRange - 1)
            ranges.append(range)
            startRange = endRange
        }
        downloadPartLocations[fileMetaData.id] = partLocations
        rangeRequests[fileMetaData.id] = ranges
    }
}

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
        newDownloadVC.onStartDownload = { [weak self] fileMetaData in
            self?.startDownload(from: fileMetaData)
        }
        present(newDownloadVC, animated: true)
    }
}

extension DownloadManagerViewController {
    private func startDownload(from fileMetaData: FileMetaData) {
        viewModel.download(from: fileMetaData)
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
        
        return cell
    }
}
