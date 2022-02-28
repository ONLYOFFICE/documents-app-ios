//
//  ASCLocalFileManager.swift
//  Documents
//
//  Created by Alexander Yuzhin on 3/7/17.
//  Copyright © 2017 Ascensio System SIA. All rights reserved.
//

import DocumentConverter
import FileKit
import Foundation

enum ASCFileManagerConverterStatus: String {
    case begin = "ASCFileManagerConverterBegin"
    case progress = "ASCFileManagerConverterProgress"
    case end = "ASCFileManagerConverterEnd"
    case error = "ASCFileManagerConverterError"
    case silentError = "ASCFileManagerConverterErrorSilent"
}

typealias ASCFileManagerConverterHandler = (_ status: ASCFileManagerConverterStatus, _ progress: Float, _ error: Error?, _ outputPath: String?) -> Void

public extension Path {
    static let userTrash = Path.userApplicationSupport + "Trash"
    static let userDocumentsTrash = Path.userDocuments + ".Trash"
}

class ASCLocalFileHelper {
    public static let shared = ASCLocalFileHelper()

    private let excludeFileNames = [".DS_Store", ".Trash"]

    required init() {
        createDirectory(Path.userAutosavedInformation)
        createDirectory(Path.userDocuments)
        createDirectory(Path.userTrash)
    }

    func entityList(_ path: Path) -> [Path] {
        var entities = [Path]()

        _ = path.find { path in
            if excludeFileNames.contains(path.fileName) {
                return false
            }

            entities.append(path)
            return true
        }

        return entities
    }

    func openFile(_ file: ASCFile) {}

    func removeFile(_ path: Path) {
        do {
            if path.exists {
                try path.deleteFile()
            }
        } catch {
            log.error(error)
        }
    }

    func createDirectory(_ path: Path) {
        do {
            if !path.exists {
                try path.createDirectory()
            }
        } catch {
            log.error(error)
        }
    }

    func removeDirectory(_ path: Path) {
        removeFile(path)
    }

    @discardableResult
    func copy(from fromPath: Path, to toPath: Path) -> Error? {
        do {
            try fromPath.copyFile(to: toPath)
        } catch {
            log.error(error)
            return error
        }

        return nil
    }

    @discardableResult
    func move(from fromPath: Path, to toPath: Path) -> Error? {
        do {
            try fromPath.moveFile(to: toPath)
        } catch {
            log.error(error)
            return error
        }

        return nil
    }

    func resolve(filePath path: Path) -> Path? {
        let folderPath = path.parent
        let fileName = path.rawValue.fileName()
        let fileExtension = path.rawValue.fileExtension()

        var resolvePath = path

        // Add postfix if file exist
        if resolvePath.exists {
            for index in 2 ... 100 {
                resolvePath = folderPath + (fileName + "-\(index)." + fileExtension)

                if !resolvePath.exists {
                    return resolvePath
                }
            }
        }

        return resolvePath.exists ? nil : resolvePath
    }

    func resolve(folderPath path: Path) -> Path? {
        let parentPath = path.parent
        let title = path.fileName

        var resolvePath = path

        // Add postfix if folder exist
        if resolvePath.exists {
            for index in 2 ... 100 {
                resolvePath = parentPath + String(title + "-\(index)")

                if !resolvePath.exists {
                    return resolvePath
                }
            }
        }

        return resolvePath.exists ? nil : resolvePath
    }
}
