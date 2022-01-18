//
//  ASCOnlyofficeFileInternalLinkMakerTests.swift
//  DocumentsTests
//
//  Created by Павел Чернышев on 06.07.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import XCTest
@testable import Documents

class ASCOnlyofficeFileInternalLinkMakerTests: XCTestCase {
    
    var sut: ASCOnlyofficeFileInternalLinkMaker!

    override func setUpWithError() throws {
        sut = ASCOnlyofficeFileInternalLinkMaker()
    }

    override func tearDownWithError() throws {
        sut = nil
    }

    func testMakeForFolderReturnsNil() {
        let folder = ASCFolder()
        let link = sut.make(entity: folder)
        XCTAssertNil(link)
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
