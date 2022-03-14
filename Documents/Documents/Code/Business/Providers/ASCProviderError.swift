//
//  ASCProviderError.swift
//  Documents
//
//  Created by Alexander Yuzhin on 12.08.2020.
//  Copyright © 2020 Ascensio System SIA. All rights reserved.
//

import FileKit
import UIKit

class ASCProviderError: LocalizedError, CustomStringConvertible {
    let msg: String

    init(msg: String) {
        self.msg = msg
    }

    init(_ error: Error) {
        if let error = error as? FileKitError {
            switch error {
            case .fileDoesNotExist:
                msg = NSLocalizedString("File does not exist", comment: "Description of file operation error")
            case .fileAlreadyExists:
                msg = NSLocalizedString("File already exists", comment: "Description of file operation error")
            case .changeDirectoryFail:
                msg = NSLocalizedString("Could not change the directory", comment: "Description of file operation error")
            case .createSymlinkFail:
                msg = NSLocalizedString("Could not create symlink from", comment: "Description of file operation error")
            case .createHardlinkFail:
                msg = NSLocalizedString("Could not create a hard link", comment: "Description of file operation error")
            case .createFileFail:
                msg = NSLocalizedString("Could not create file", comment: "Description of file operation error")
            case .createDirectoryFail:
                msg = NSLocalizedString("Could not create a directory", comment: "Description of file operation error")
            case .deleteFileFail:
                msg = NSLocalizedString("Could not delete file", comment: "Description of file operation error")
            case .readFromFileFail:
                msg = NSLocalizedString("Could not read from file", comment: "Description of file operation error")
            case .writeToFileFail:
                msg = NSLocalizedString("Could not write to file", comment: "Description of file operation error")
            case .moveFileFail:
                msg = NSLocalizedString("Could not move file", comment: "Description of file operation error")
            case .copyFileFail:
                msg = NSLocalizedString("Could not copy file", comment: "Description of file operation error")
            case .attributesChangeFail:
                msg = NSLocalizedString("Could not change file attributes", comment: "Description of file operation error")
            }
        } else {
            msg = error.localizedDescription
        }
    }

    var description: String {
        return msg
    }
}
