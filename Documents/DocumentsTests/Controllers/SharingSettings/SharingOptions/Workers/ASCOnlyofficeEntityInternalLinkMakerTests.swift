//
//  ASCOnlyofficeEntityInternalLinkMakerTests.swift
//  DocumentsTests
//
//  Created by Pavel Chernyshev on 06.07.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

@testable import Documents
import XCTest

class ASCOnlyofficeEntityInternalLinkMakerTests: XCTestCase {
    var sut: ASCOnlyofficeEntityInternalLinkMaker!

    override func setUpWithError() throws {
        sut = ASCOnlyofficeEntityInternalLinkMaker()
        ASCFileManager.onlyofficeProvider = MockFileProvider(id: "Foo")
    }

    override func tearDownWithError() throws {
        sut = nil
        ASCFileManager.onlyofficeProvider = nil
    }

    func testMakeForFolderReturnsNil() {
        let folder = ASCFolder()
        folder.id = "321"
        ASCFileManager.onlyofficeProvider?.apiClient.baseURL = URL(string: "https://test.portal.info")
        let link = sut.make(entity: folder)
        let expect = "https://test.portal.info/Products/Files/#321"
        XCTAssertEqual(link, expect)
    }

    func testMakeForFileWithId123ReturnsLinkWith123() {
        let file = ASCFile()
        file.id = "123"
        file.viewUrl = "https://test.portal.info/Products/Files/HttpHandlers/filehandler.ashx?action=download&fileid=123"
        let expect = "https://test.portal.info/Products/Files/DocEditor.aspx?fileid=123"
        let link = sut.make(entity: file)
        XCTAssertEqual(link, expect)
    }
}

private extension ASCOnlyofficeEntityInternalLinkMakerTests {
    class MockFileProvider: ASCOnlyofficeProvider {
        let innerId: String
        override var id: String? {
            innerId
        }

        init(id: String) {
            innerId = id
            super.init()
        }
    }
}
