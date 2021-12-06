//
//  ASCSharingSettingsAccessProviderFactoryTests.swift
//  DocumentsTests
//
//  Created by Павел Чернышев on 07.07.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import XCTest
@testable import Documents

class ASCSharingSettingsAccessProviderFactoryTests: XCTestCase {

    var sut: ASCSharingSettingsAccessProviderFactory!
    
    override func setUpWithError() throws {
        sut = ASCSharingSettingsAccessProviderFactory()
    }

    override func tearDownWithError() throws {
        sut = nil
    }

    func testWhenFolderThenGetsDefault() throws {
        let folder = ASCFolder()
        XCTAssertTrue(sut.get(entity: folder, isAccessExternal: false) is ASCSharingSettingsAccessDefaultProvider)
    }
    
    func testWhenFileWithotExtensionThenGetsDefault() throws {
        let file = ASCFile()
        file.title = "Foo"
        XCTAssertTrue(sut.get(entity: file, isAccessExternal: false) is ASCSharingSettingsAccessDefaultProvider)
    }
    
    func testWhenFileWithotExtensionForExternalThenGetsExternalDefault() throws {
        let file = ASCFile()
        file.title = "Foo"
        XCTAssertTrue(sut.get(entity: file, isAccessExternal: true) is ASCSharingSettingsAccessExternalDefaultProvider)
    }
    
    func testWhenDocumentThenGetsDocumntProvider() {
        let file = ASCFile()
        file.title = "Foo.docx"
        XCTAssertTrue(sut.get(entity: file, isAccessExternal: false) is ASCSharingSettingsAccessDocumentProvider)
        XCTAssertTrue(sut.get(entity: file, isAccessExternal: true) is ASCSharingSettingsAccessDocumentProvider)
    }

    func testWhenTableThenGetsTableProvider() {
        let file = ASCFile()
        file.title = "Foo.xlsx"
        XCTAssertTrue(sut.get(entity: file, isAccessExternal: false) is ASCSharingSettingsAccessTableProvider)
        XCTAssertTrue(sut.get(entity: file, isAccessExternal: true) is ASCSharingSettingsAccessTableProvider)
    }
    
    func testWhenPresentationThenGetsPresentationProvider() {
        let file = ASCFile()
        file.title = "Foo.pptx"
        XCTAssertTrue(sut.get(entity: file, isAccessExternal: false) is ASCSharingSettingsAccessPresentationProvider)
        XCTAssertTrue(sut.get(entity: file, isAccessExternal: true) is ASCSharingSettingsAccessPresentationProvider)
    }
    
    func testWhenDocumentFormThenGetsNextRightReadDenyFullCommentReview() {
        let file = ASCFile()
        file.title = "Foo.docxf"
        let provider = sut.get(entity: file, isAccessExternal: false)
        let actualAccessList = provider.get()
        let expectedAccessList: [ASCShareAccess] = [.full, .review, .comment, .read, .deny]
        XCTAssertEqual(expectedAccessList, actualAccessList)
    }
    
    func testWhenDocumentFormForTheExternalLinkThenGetsNextRightReadDenyFullCommentReview() {
        let file = ASCFile()
        file.title = "Foo.docxf"
        let provider = sut.get(entity: file, isAccessExternal: true)
        let actualAccessList = provider.get()
        let expectedAccessList: [ASCShareAccess] = [.full, .review, .comment, .read, .deny]
        XCTAssertEqual(expectedAccessList, actualAccessList)
    }
    
    func testWhenDocumentFormThenGetsDocumntFormProvider() {
        let file = ASCFile()
        file.title = "Foo.docxf"
        XCTAssertTrue(sut.get(entity: file, isAccessExternal: false) is ASCSharingSettingsAccessDocumentFormProvider)
        XCTAssertTrue(sut.get(entity: file, isAccessExternal: true) is ASCSharingSettingsAccessDocumentFormProvider)
    }
    
    func testWhenOFormThenGetsNextRightReadDenyFullCommentReview() {
        let file = ASCFile()
        file.title = "Foo.oform"
        let provider = sut.get(entity: file, isAccessExternal: false)
        let actualAccessList = provider.get()
        let expectedAccessList: [ASCShareAccess] = [.full, .fillForms, .read, .deny]
        XCTAssertEqual(expectedAccessList, actualAccessList)
    }
    
    func testWhenOFormForTheExternalLinkThenGetsNextRightReadDenyFullCommentReview() {
        let file = ASCFile()
        file.title = "Foo.oform"
        let provider = sut.get(entity: file, isAccessExternal: true)
        let actualAccessList = provider.get()
        let expectedAccessList: [ASCShareAccess] = [.full, .fillForms, .read, .deny]
        XCTAssertEqual(expectedAccessList, actualAccessList)
    }
    
    func testWhenOFormThenGetsDocumntFormProvider() {
        let file = ASCFile()
        file.title = "Foo.oform"
        XCTAssertTrue(sut.get(entity: file, isAccessExternal: false) is ASCSharingSettingsAccessOFormProvider)
        XCTAssertTrue(sut.get(entity: file, isAccessExternal: true) is ASCSharingSettingsAccessOFormProvider)
    }
}
