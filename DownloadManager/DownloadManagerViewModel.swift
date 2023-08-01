//
//  DownloadManagerViewModel.swift
//  DownloadManager
//
//  Created by Tri Nguyen T. [2] on 01/08/2023.
//

import Foundation

class DownloadManagerViewModel {
    private var downloadList = [DownloadCellModel]()

    var numbersOfItems: Int {
        return downloadList.count
    }
    
    func item(for index: Int) -> DownloadCellModel {
        return downloadList[index]
    }
}
