//
//  ASCOneDriveProviderTests.swift
//  DocumentsTests
//
//  Created by Pavel Chernyshev on 24.08.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

@testable import Documents
import FileKit
import FilesProvider
import UIKit
import XCTest

class ASCOneDriveProviderTests: XCTestCase {
    var sut: ASCOneDriveProvider!

    override func setUpWithError() throws {
        sut = ASCOneDriveProvider()
    }

    override func tearDownWithError() throws {
        sut = nil
    }

    // MARK: - findUniqName func tests

    func testFindUnicNameWhenBaseNameIsUnicThenReturnsBaseName() throws {
        let folder = ASCFolder()
        folder.id = "1"
        sut.provider = ASCOneDriveFileProviderMock()
        sut.findUniqName(suggestedName: "Foo.docx", inFolder: folder) { name in
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
        sut.findUniqName(suggestedName: "Foo.docx", inFolder: folder) { name in
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
        sut.findUniqName(suggestedName: "Foo.docx", inFolder: folder) { name in
            XCTAssertEqual(name, "Foo 2.docx")
        }
    }

    func testFindUnicNameWhenDirectoryBaseNameIsUnicThenReturnsBaseName() throws {
        let folder = ASCFolder()
        folder.id = ""
        sut.provider = ASCOneDriveFileProviderMock()
        sut.findUniqName(suggestedName: "Foo", inFolder: folder) { name in
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
            "/2/Foo 2",
        ]
        sut.provider = mockProvider
        sut.findUniqName(suggestedName: "Foo", inFolder: folder) { name in
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
        sut.findUniqName(suggestedName: "Foo", inFolder: folder) { name in
            XCTAssertEqual(name, "Foo 4")
        }
    }

    // MARK: - rename func tests

//    func testWhenRenameFileInEmptyDirThenRenamed() {
//        let entity = ASCFile()
//        entity.title = "Foo.docx"
//        entity.id = ""
//        sut.provider = ASCOneDriveFileProviderMock()
//        let expect = expectation(description: "renaming file")
//        sut.rename(entity, to: "Bar") { sut, entity, success, error in
//            XCTAssertNil(error)
//            XCTAssertTrue(success)
//
//            guard let entity = entity as? ASCFile else {
//                XCTFail("Couldn't cust entity to file")
//                return
//            }
//            XCTAssertEqual(entity.title, "Bar.docx")
//            expect.fulfill()
//        }
//        waitForExpectations(timeout: 1)
//    }

    func testWhenRenameFileInFolderWithExistNameThanFailure() {
        let entity = ASCFile()
        entity.title = "Foo.docx"
        entity.id = "1"
        let mockProvider = ASCOneDriveFileProviderMock()
        mockProvider.pathsOfItemsIds["1"] = "/1/Foo.docx"
        mockProvider.existingPaths = [
            "/1/Bar.docx",
        ]
        sut.provider = mockProvider
        let expect = expectation(description: "renaming file")
        sut.rename(entity, to: "Bar") { sut, entity, success, error in
            XCTAssertNotNil(error)
            XCTAssertFalse(success)

            guard let entity = entity as? ASCFile else {
                XCTFail("Couldn't cust entity to file")
                return
            }
            XCTAssertEqual(entity.title, "Foo.docx")
            expect.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    func testWhenRenameFileInRootFolderWithExistNameThanFailure() {
        let entity = ASCFile()
        entity.title = "Foo.docx"
        entity.id = "1"

        let mockProvider = ASCOneDriveFileProviderMock()
        mockProvider.pathsOfItemsIds["1"] = "/Foo.docx"
        mockProvider.existingPaths = [
            "/Bar.docx",
        ]
        sut.provider = mockProvider
        let expect = expectation(description: "renaming file")
        sut.rename(entity, to: "Bar") { sut, entity, success, error in
            XCTAssertNotNil(error)
            XCTAssertFalse(success)

            guard let entity = entity as? ASCFile else {
                XCTFail("Couldn't cust entity to file")
                return
            }
            XCTAssertEqual(entity.title, "Foo.docx")
            expect.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    func testWhenRenameFolderInEmptyDirThenRenamed() {
        let entity = ASCFolder()
        entity.title = "Foo"
        entity.id = ""
        sut.provider = ASCOneDriveFileProviderMock()

        let expect = expectation(description: "renaming folder")
        sut.rename(entity, to: "Bar") { sut, entity, success, error in
            XCTAssertNil(error)
            XCTAssertTrue(success)

            guard let entity = entity as? ASCFolder else {
                XCTFail("Couldn't cust entity to folder")
                return
            }
            XCTAssertEqual(entity.title, "Bar")
            expect.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    func testWhenRenameFolderInFolderWithExistNameThanFailure() {
        let entity = ASCFolder()
        entity.title = "Foo"
        entity.id = "1"
        let mockProvider = ASCOneDriveFileProviderMock()
        mockProvider.pathsOfItemsIds["1"] = "/1/Foo"
        mockProvider.existingPaths = [
            "/1/Bar",
        ]
        sut.provider = mockProvider
        let expect = expectation(description: "renaming folder")
        sut.rename(entity, to: "Bar") { sut, entity, success, error in
            XCTAssertNotNil(error)
            XCTAssertFalse(success)

            guard let entity = entity as? ASCFolder else {
                XCTFail("Couldn't cust entity to folder")
                return
            }
            XCTAssertEqual(entity.title, "Foo")
            expect.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    func testWhenRenameFolderInRootFolderWithExistNameThanFailure() {
        let entity = ASCFolder()
        entity.title = "Foo"
        entity.id = ""
        let mockProvider = ASCOneDriveFileProviderMock()
        mockProvider.existingPaths = [
            "/Bar",
        ]
        sut.provider = mockProvider
        let expect = expectation(description: "renaming folder")
        sut.rename(entity, to: "Bar") { sut, entity, success, error in
            XCTAssertNotNil(error)
            XCTAssertFalse(success)

            guard let entity = entity as? ASCFolder else {
                XCTFail("Couldn't cust entity to folder")
                return
            }
            XCTAssertEqual(entity.title, "Foo")
            expect.fulfill()
        }
        waitForExpectations(timeout: 1)
    }
}

// MARK: - Extensions

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

        override func moveItem(path: String, to toPath: String, overwrite: Bool, completionHandler: SimpleCompletionHandler) -> Progress? {
            completionHandler?(nil)
            return nil
        }

        override func moveItem(path: String, to toPath: String, overwrite: Bool, requestData: [String: Any], completionHandler: SimpleCompletionHandler) -> Progress? {
            completionHandler?(nil)
            return nil
        }

        init() {
            super.init(credential: nil)
        }

        @available(*, unavailable)
        required convenience init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }

    enum ErrorMock: Error {
        case pathNotFound
    }
}
