//
//  ASCNextCloudProviderTests.swift
//  DocumentsTests
//
//  Created by Pavel Chernyshev on 04.12.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

@testable import Documents
import FilesProvider
import XCTest

class ASCNextCloudProviderTests: XCTestCase {
    var sut: ASCNextCloudProvider!

    override func setUpWithError() throws {
        sut = ASCNextCloudProvider()
        try super.setUpWithError()
    }

    override func tearDownWithError() throws {
        sut.provider = nil
        sut = nil
        try super.tearDownWithError()
    }
}

// MARK: - Test unic name func

extension ASCNextCloudProviderTests {
    func testFindUnicNameWhenBaseNameIsUnicThenReturnsBaseName() throws {
        setSUTFileProveder(withExistingPaths: [])
        sut.findUniqName(suggestedName: "Foo.docx", inFolder: makeFolder(withId: "/1")) { name in
            XCTAssertEqual(name, "Foo.docx")
        }
    }

    func testFindUnicNameWhenBaseNameExistSixTimesThenReturnsBaseNameWithSevenPostfix() throws {
        setSUTFileProveder(withExistingPaths: [
            "/1/Foo.docx",
            "/1/Foo 1.docx",
            "/1/Foo 2.docx",
            "/1/Foo 3.docx",
            "/1/Foo 4.docx",
            "/1/Foo 5.docx",
            "/1/Foo 6.docx",
        ])
        sut.findUniqName(suggestedName: "Foo.docx", inFolder: makeFolder(withId: "/1")) { name in
            XCTAssertEqual(name, "Foo 7.docx")
        }
    }

    func testFindUnicNameWhenBaseNameExistOneTimesThenReturnsBaseNameWithTwoPostfixInRootFolder() throws {
        setSUTFileProveder(withExistingPaths: [
            "/Foo.docx",
            "/Foo 1.docx",
        ])
        sut.findUniqName(suggestedName: "Foo.docx", inFolder: makeFolder(withId: "/")) { name in
            XCTAssertEqual(name, "Foo 2.docx")
        }
    }

    func testFindUnicNameWhenDirectoryBaseNameIsUnicThenReturnsBaseName() throws {
        setSUTFileProveder(withExistingPaths: [])
        sut.findUniqName(suggestedName: "Foo", inFolder: makeFolder(withId: "/")) { name in
            XCTAssertEqual(name, "Foo")
        }
    }

    func testFindUnicNameWhenDirectoryBaseNameExistThreeTimesThenReturnsDirectoryBaseNameWithTreePostfix() throws {
        setSUTFileProveder(withExistingPaths: [
            "/2/Foo",
            "/2/Foo 1",
            "/2/Foo 2",
        ])
        sut.findUniqName(suggestedName: "Foo", inFolder: makeFolder(withId: "/2")) { name in
            XCTAssertEqual(name, "Foo 3")
        }
    }

    func testFindUnicNameWhenDirectoryBaseNameExistFourTimesThenReturnsDirectoryBaseNameWithFourPostfixInRootFolder() throws {
        setSUTFileProveder(withExistingPaths: [
            "/Foo",
            "/Foo 1",
            "/Foo 2",
            "/Foo 3",
        ])
        sut.findUniqName(suggestedName: "Foo", inFolder: makeFolder(withId: "/")) { name in
            XCTAssertEqual(name, "Foo 4")
        }
    }
}

// MARK: - Helper functions

extension ASCNextCloudProviderTests {
    private func setSUTFileProveder(withExistingPaths paths: [String]) {
        let provider = FileProviderMock()!
        provider.existingPaths = paths
        sut.provider = provider
    }

    private func makeFolder(withId id: String) -> ASCFolder {
        let folder = ASCFolder()
        folder.id = id
        return folder
    }
}

// MARK: - Mock

extension ASCNextCloudProviderTests {
    class FileProviderMock: WebDAVFileProvider {
        var existingPaths: [String] = []

        init?() {
            super.init(baseURL: URL(string: "https://foo.baz")!, credential: nil, cache: nil)
        }

        @available(*, unavailable)
        required convenience init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
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
    }
}
