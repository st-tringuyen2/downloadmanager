//
//  NewDownloadViewController.swift
//  DownloadManager
//
//  Created by Tri Nguyen T. [2] on 31/07/2023.
//

import UIKit

class NewDownloadViewController: UIViewController {
    private struct UnExpectedRepresentError: Error {}
    
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var textField: UITextField!
    @IBOutlet private var cancelButton: UIButton!
    @IBOutlet private var startDownloadButton: UIButton!
    @IBOutlet private var indicatorView: UIActivityIndicatorView!
    
    public var titleLabelText: String?
    
    private let fileManager: FileManager
    private lazy var downloasdDirectory: URL = {
        let url = fileManager.urls(for: .downloadsDirectory, in: .userDomainMask)
        
        return url.first!
    }()
    
    private lazy var appDownloadFolder: URL = {
        let url = downloasdDirectory.appendingPathComponent("ST Download Manager")
        
        return url
    }()

    
    private var saveLocation: URL?
    
    private var viewModel: NewDowloadViewModel
    
    init(viewModel: NewDowloadViewModel, fileManager: FileManager = .default) {
        self.viewModel = viewModel
        self.fileManager = fileManager
        super.init(nibName: nil, bundle: nil)
        createDownloadFolder()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        titleLabel.text = titleLabelText
    }
    
    private func mapMetaData(from result: Result<String, Error>) {
        DispatchQueue.main.async { [weak self] in
            self?.indicatorView.stopAnimating()
            switch result {
            case let .success(fileName):
                self?.createEmptyFile(with: fileName)
            case let .failure(error):
                print("Get metadata fail with error \(error)")
            }
        }
    }
    
    @IBAction private func downloadButtonTapped() {
        guard let url = URL(string: textField.text ?? "") else { return }
        textField.endEditing(true)
        indicatorView.startAnimating()
        viewModel.getMetaData(from: url) { [weak self] result in
            self?.mapMetaData(from: result)
        }
    }
    
    @IBAction private func cancelButtonTapped() {
        dismiss(animated: true)
    }
}

extension NewDownloadViewController {
    private func createDownloadFolder() {
        if !fileManager.fileExists(atPath: appDownloadFolder.path) {
            try? fileManager.createDirectory(at: appDownloadFolder, withIntermediateDirectories: true)
        }
    }
    
    private func createEmptyFile(with fileName: String) {
        var finalName = fileName
        var count = 0
        while fileManager.fileExists(atPath: appDownloadFolder.appendingPathComponent(finalName).path) {
            count += 1
            finalName = fileName
            if let index = fileName.lastIndex(of: ".") {
                finalName.insert(contentsOf: "(\(count))", at: index)
            }
        }
        let filePath = appDownloadFolder.appendingPathComponent(finalName).path
        if fileManager.createFile(atPath: filePath, contents: nil) == true {
            dismiss(animated: true)
        } else {
            print("Create empty file error")
        }
    }
}

extension NewDownloadViewController: UITextFieldDelegate {
    public func textFieldDidChangeSelection(_ textField: UITextField) {
        guard URL(string: textField.text ?? "") != nil else {
            startDownloadButton.isEnabled = false
            return
        }
        startDownloadButton.isEnabled = true
    }
}

