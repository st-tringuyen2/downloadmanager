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
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        titleLabel.text = titleLabelText
    }
    
    @IBAction private func cancelButtonTapped() {
        dismiss(animated: true)
    }
    
    @IBAction private func downloadButtonTapped() {
        guard let _ = URL(string: textField.text ?? "") else { return }
        textField.endEditing(true)
        indicatorView.startAnimating()
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

