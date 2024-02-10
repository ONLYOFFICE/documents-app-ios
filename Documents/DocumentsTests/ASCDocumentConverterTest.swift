//
//  ASCDocumentConverterTest.swift
//  DocumentsTests
//
//  Created by Alexander Yuzhin on 02/03/2018.
//  Copyright © 2018 Ascensio System SIA. All rights reserved.
//

import DocumentConverter
import FileKit
import XCTest

class ASCDocumentConverterTest: XCTestCase {
    private let converterKey = "{95874338-e6dc-4965-9791-b7802f22aa67}"
    private let openedFilePassword = "555"

    lazy var appFonts: [String] = {
        var paths = [Bundle.main.resourcePath?.appendingPathComponent("fonts") ?? ""]

        if let appFontsFolder = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first {
            paths.insert(appFontsFolder.appendingPathComponent("Fonts").path, at: 0)
        }
        return paths
    }()

    lazy var dataFontsPath: String = {
        let paths = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)
        if let documentsDirectory = paths.first {
            let path = documentsDirectory + "/asc.editors.data.cache.fonts"
            do {
                try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: false, attributes: nil)
            } catch {}
            return path
        }
        return ""
    }()

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func removeFile(_ path: Path) {
        do {
            if path.exists {
                try path.deleteFile()
            }
        } catch {
            print(error)
        }
    }

    func createDirectory(_ path: Path) {
        do {
            if !path.exists {
                try path.createDirectory()
            }
        } catch {
            print(error)
        }
    }

    func removeDirectory(_ path: Path) {
        removeFile(path)
    }

    private func convertDocument(_ path: Path) -> (Bool, String) {
        let isDocument = path.pathExtension == "docx"
        let isSpreadsheet = path.pathExtension == "xlsx"
        let isPresentation = path.pathExtension == "pptx"

        var conversionDirectionTo = ConversionDirection.CD_DOCX2DOCT_BIN
        var conversionDirectionBack = ConversionDirection.CD_DOCT_BIN2DOCX
        var directionInfoTo = "DOCX -> DOCT"
        var directionInfoBack = "DOCT -> DOCX"

        if isDocument {
            conversionDirectionTo = ConversionDirection.CD_DOCX2DOCT_BIN
            conversionDirectionBack = ConversionDirection.CD_DOCT_BIN2DOCX
            directionInfoTo = "DOCX -> DOCT"
            directionInfoBack = "DOCT -> DOCX"
        } else if isSpreadsheet {
            conversionDirectionTo = ConversionDirection.CD_XSLX2XSLT_BIN
            conversionDirectionBack = ConversionDirection.CD_XSLT_BIN2XSLX
            directionInfoTo = "XLSX -> XLST"
            directionInfoBack = "XLST -> XLSX"
        } else if isPresentation {
            conversionDirectionTo = ConversionDirection.CD_PPTX2PPTT_BIN
            conversionDirectionBack = ConversionDirection.CD_PPTT_BIN2PPTX
            directionInfoTo = "PPTX -> PPTT"
            directionInfoBack = "PPTT -> PPTX"
        } else {
            return (false, "❌ Complete FAILURE: Unsupported file: \(path.rawValue)")
        }

        let converter = DocumentLocalConverter()
        let outputPath = Path.userAutosavedInformation + path.fileName + "/"
        let tempPath = Path.userTemporary + UUID().uuidString
        let fontPath = "/System/Library/Fonts"

        do {
            try outputPath.createDirectory(withIntermediateDirectories: true)
            try tempPath.createDirectory(withIntermediateDirectories: true)
        } catch {
            return (false, "❌ Complete FAILURE: Couldn't directory structure for: \(path.rawValue)")
        }

        var resultError: Error?

        converter.fontsPaths = appFonts
        converter.dataFontsPath = dataFontsPath
        converter.options = [
            "Key": converterKey,
            "FileData": NSNull(),
            "FileFrom": path.rawValue,
            "FileTo": (outputPath + "Editor.bin").rawValue,
            "ConversionDirection": NSNumber(value: conversionDirectionTo.rawValue),
            "FontDir": fontPath,
            "TempDir": tempPath.rawValue,
            "Async": false,
            "Password": openedFilePassword,
        ]

        converter.start { status, progress, error in
            if status == kDocumentLocalConverterBegin {
                print("♻️ Start \(directionInfoTo) of \(path.fileName)")
                resultError = error
            } else if status == kDocumentLocalConverterProgress {
                print("♻️ Processing \(directionInfoTo) \(progress * 100)% of \(path.fileName)")
                resultError = error
            } else if status == kDocumentLocalConverterEnd {
                print("♻️ End \(directionInfoTo) of \(path.fileName)")
                resultError = error
            } else if status == kDocumentLocalConverterError {
                guard let error = error as NSError? else { return }

                resultError = error

                if Int32(error.code) == kErrorPassword {
                    print("⚠️ Password is invalid for \(path.fileName)")
                }
            }
        }

        if let error = resultError {
            return (false, "❌ Complete FAILURE: Error: \(error) for: \(path.rawValue)")
        }

        converter.fontsPaths = appFonts
        converter.dataFontsPath = dataFontsPath
        converter.options = [
            "Key": converterKey,
            "FileData": NSNull(),
            "FileFrom": (outputPath + "Editor.bin").rawValue,
            "FileTo": (outputPath + path.fileName).rawValue,
            "ConversionDirection": NSNumber(value: conversionDirectionBack.rawValue),
            "FontDir": fontPath,
            "TempDir": tempPath.rawValue,
            "Async": false,
        ]

        converter.start { [unowned self] status, progress, error in
            if status == kDocumentLocalConverterBegin {
                print("♻️ Start \(directionInfoBack) of \(path.fileName)")
                resultError = error
            } else if status == kDocumentLocalConverterProgress {
                print("♻️ Processing \(directionInfoBack) \(progress * 100)% of \(path.fileName)")
                resultError = error
            } else if status == kDocumentLocalConverterEnd {
                print("♻️ End \(directionInfoBack) of \(path.fileName)")
                resultError = error
                self.removeDirectory(tempPath)
            } else if status == kDocumentLocalConverterError {
                guard let error = error as NSError? else { return }

                resultError = error

                if Int32(error.code) == kErrorPassword {
                    print("⚠️ Password is invalid for \(path.fileName)")
                }
                self.removeDirectory(tempPath)
            }
        }

        return (true, "✅ Complete OK for: \(path.fileName)")
    }

    func testLocalDocuments() {
        if let testResourceUrl = Bundle(for: type(of: self)).resourceURL,
           let testResourcePath = Path(url: testResourceUrl)
        {
            let testDocumentsPath = testResourcePath + "documents"

            for path in testDocumentsPath {
                if path.pathExtension == "docx" ||
                    path.pathExtension == "xlsx" ||
                    path.pathExtension == "pptx"
                {
                    print("📦 BEGIN CONVERTING of file: \(path.fileName)")
                    let result = convertDocument(path)
                    print("📦 END CONVERTING \(result.1)")

                    XCTAssert(result.0, result.1)
                }
            }
        }
    }

//    func testPerformanceExample() {
//        // This is an example of a performance test case.
//        self.measure {
//            // Put the code you want to measure the time of here.
//        }
//    }
}
