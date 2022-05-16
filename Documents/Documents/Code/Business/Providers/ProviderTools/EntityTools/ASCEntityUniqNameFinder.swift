//
//  EntityUniqNameFinder.swift
//  Documents
//
//  Created by Pavel Chernyshev on 04.12.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import Foundation

class ASCEntityUniqNameFinder: ASCUniqNameFinder {
    let entityExistChecker: ASCEntityExistenceChecker

    init(entityExistChecker: ASCEntityExistenceChecker) {
        self.entityExistChecker = entityExistChecker
    }

    func find(bySuggestedName suggestedName: String, atPath path: String, completion: @escaping (UniqName) -> Void) {
        var checkingName = suggestedName
        var isCurrentNameUniq = false
        let folderPath = path

        var triesCount = 0
        repeat {
            let semaphore = DispatchSemaphore(value: 0)
            let filePath = folderPath.appendingPathComponent(checkingName)
            entityExistChecker.isExist(entityFullName: filePath) { isExist in
                if !isExist {
                    isCurrentNameUniq = true
                } else {
                    triesCount += 1

                    let fullItemName = suggestedName
                    let itemExtension = fullItemName.pathExtension
                    if !itemExtension.isEmpty {
                        let itemName = fullItemName.deletingPathExtension
                        checkingName = "\(itemName) \(triesCount).\(itemExtension)"
                    } else {
                        checkingName = "\(suggestedName) \(triesCount)"
                    }
                }
                semaphore.signal()
            }
            semaphore.wait()
        } while !isCurrentNameUniq
        completion(checkingName)
    }
}
