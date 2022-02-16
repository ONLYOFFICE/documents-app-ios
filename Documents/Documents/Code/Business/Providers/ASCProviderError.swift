//
//  ASCProviderError.swift
//  Documents
//
//  Created by Alexander Yuzhin on 12.08.2020.
//  Copyright © 2020 Ascensio System SIA. All rights reserved.
//

import UIKit
import FileKit

class ASCProviderError: LocalizedError, CustomStringConvertible {
    let msg: String

    init(msg: String) {
        self.msg = msg
    }
    
    init(_ error: Error) {
        if let error = error as? FileKitError {
            switch error {
            case .fileDoesNotExist(_):
                self.msg = NSLocalizedString("File does not exist", comment: "Description of file operation error")
            case .fileAlreadyExists(_):
                self.msg = NSLocalizedString("File already exists", comment: "Description of file operation error")
            case .changeDirectoryFail(_, _, _):
                self.msg = NSLocalizedString("Could not change the directory", comment: "Description of file operation error")
            case .createSymlinkFail(_, _, _):
                self.msg = NSLocalizedString("Could not create symlink from", comment: "Description of file operation error")
            case .createHardlinkFail(_, _, _):
                self.msg = NSLocalizedString("Could not create a hard link", comment: "Description of file operation error")
            case .createFileFail(_):
                self.msg = NSLocalizedString("Could not create file", comment: "Description of file operation error")
            case .createDirectoryFail(_, _):
                self.msg = NSLocalizedString("Could not create a directory", comment: "Description of file operation error")
            case .deleteFileFail(_, _):
                self.msg = NSLocalizedString("Could not delete file", comment: "Description of file operation error")
            case .readFromFileFail(_, _):
                self.msg = NSLocalizedString("Could not read from file", comment: "Description of file operation error")
            case .writeToFileFail(_, _):
                self.msg = NSLocalizedString("Could not write to file", comment: "Description of file operation error")
            case .moveFileFail(_, _, _):
                self.msg = NSLocalizedString("Could not move file", comment: "Description of file operation error")
            case .copyFileFail(_, _, _):
                self.msg = NSLocalizedString("Could not copy file", comment: "Description of file operation error")
            case .attributesChangeFail(_, _):
                self.msg = NSLocalizedString("Could not change file attributes", comment: "Description of file operation error")
            }
        } else {
            self.msg = error.localizedDescription
        }
    }

    var description: String {
        return msg
    }
}
