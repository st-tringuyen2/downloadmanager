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
    
    private var viewModel: NewDowloadViewModel
    
    init(viewModel: NewDowloadViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
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
                print(fileName)
                self?.dismiss(animated: true)
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

extension NewDownloadViewController: UITextFieldDelegate {
    public func textFieldDidChangeSelection(_ textField: UITextField) {
        guard URL(string: textField.text ?? "") != nil else {
            startDownloadButton.isEnabled = false
            return
        }
        startDownloadButton.isEnabled = true
    }
}
