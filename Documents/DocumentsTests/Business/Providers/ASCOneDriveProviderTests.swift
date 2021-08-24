//
//  ASCOneDriveProviderTests.swift
//  DocumentsTests
//
//  Created by Павел Чернышев on 24.08.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import XCTest
import UIKit
import FilesProvider
import FileKit
@testable import Documents

class ASCOneDriveProviderTests: XCTestCase {
    
    var sut: ASCOneDriveProvider!

    override func setUpWithError() throws {
        sut = ASCOneDriveProvider()
    }

    override func tearDownWithError() throws {
       sut = nil
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    // MARK: - findUnicName func tests
    func testFindUnicNameWhenBaseNameIsUnicThenReturnsBaseName() throws {
        let folder = ASCFolder()
        folder.id = "1"
        sut.provider = ASCOneDriveFileProviderMock()
        sut.findUnicName(baseName: "Foo.docx", inFolder: folder) { name in
            XCTAssertEqual(name, "Foo.docx")
        }
    }

    func testFindUnicNameWhenBaseNameExistSixTimesThenReturnsBaseNameWithSevenPostfix() throws {
        let folder = ASCFolder()
        folder.id = "1"
        let mockProvider = ASCOneDriveFileProviderMock()
        mockProvider.pathsOfItemsIds["1"] = "/1"
        mockProvider.existingPaths = [
            "/1/Foo.docx",
            "/1/Foo 1.docx",
            "/1/Foo 2.docx",
            "/1/Foo 3.docx",
            "/1/Foo 4.docx",
            "/1/Foo 5.docx",
            "/1/Foo 6.docx",
        ]
        sut.provider = mockProvider
        sut.findUnicName(baseName: "Foo.docx", inFolder: folder) { name in
            XCTAssertEqual(name, "Foo 7.docx")
        }
    }
    
    func testFindUnicNameWhenBaseNameExistOneTimesThenReturnsBaseNameWithTwoPostfixInRootFolder() throws {
        let folder = ASCFolder()
        folder.id = ""
        let mockProvider = ASCOneDriveFileProviderMock()
        mockProvider.existingPaths = [
            "/Foo.docx",
            "/Foo 1.docx",
        ]
        sut.provider = mockProvider
        sut.findUnicName(baseName: "Foo.docx", inFolder: folder) { name in
            XCTAssertEqual(name, "Foo 2.docx")
        }
    }
    
    func testFindUnicNameWhenDirectoryBaseNameIsUnicThenReturnsBaseName() throws {
        let folder = ASCFolder()
        folder.id = ""
        sut.provider = ASCOneDriveFileProviderMock()
        sut.findUnicName(baseName: "Foo", inFolder: folder) { name in
            XCTAssertEqual(name, "Foo")
        }
    }
    
    func testFindUnicNameWhenDirectoryBaseNameExistTwoTimesThenReturnsDirectoryBaseNameWithTreePostfix() throws {
        let folder = ASCFolder()
        folder.id = "2"
        let mockProvider = ASCOneDriveFileProviderMock()
        mockProvider.pathsOfItemsIds["2"] = "/2"
        mockProvider.existingPaths = [
            "/2/Foo",
            "/2/Foo 1",
            "/2/Foo 2"
        ]
        sut.provider = mockProvider
        sut.findUnicName(baseName: "Foo", inFolder: folder) { name in
            XCTAssertEqual(name, "Foo 3")
        }
    }
    
    func testFindUnicNameWhenDirectoryBaseNameExistThreeTimesThenReturnsDirectoryBaseNameWithFourPostfixInRootFolder() throws {
        let folder = ASCFolder()
        folder.id = ""
        let mockProvider = ASCOneDriveFileProviderMock()
        mockProvider.existingPaths = [
            "/Foo",
            "/Foo 1",
            "/Foo 2",
            "/Foo 3",
        ]
        sut.provider = mockProvider
        sut.findUnicName(baseName: "Foo", inFolder: folder) { name in
            XCTAssertEqual(name, "Foo 4")
        }
    }
}

extension ASCOneDriveProviderTests {
    class ASCOneDriveFileProviderMock: ASCOneDriveFileProvider {
        typealias Path = String
        typealias Id = String

        var existingPaths: [String] = []
        var pathsOfItemsIds: [Id: Path] = [:]
        
        override func pathOfItem(withId itemId: String, completionHandler: @escaping (String?, Error?) -> Void) {
            if let path = pathsOfItemsIds[itemId] {
                completionHandler(path, nil)
            } else {
                completionHandler(nil, ErrorMock.pathNotFound)
            }
        }
        
        override func attributesOfItem(path: String, completionHandler: @escaping (FileObject?, Error?) -> Void) {
            
            if existingPaths.contains(path) {
                let pathExtEmpty = path.pathExtension.isEmpty
                let fileResourceTypeKey: URLFileResourceType = pathExtEmpty ? .directory : .regular
                let fileObject = FileObject(allValues: [.fileResourceTypeKey: fileResourceTypeKey])
                completionHandler(fileObject, nil)
            } else {
                completionHandler(nil, nil)
            }
        }
        
        init() {
            super.init(credential: nil)
        }
        
        required convenience init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
    
    enum ErrorMock: Error {
        case pathNotFound
    }
}
