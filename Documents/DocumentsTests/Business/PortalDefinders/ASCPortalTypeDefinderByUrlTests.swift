//
//  ASCPortalTypeDefinderByUrlTests.swift
//  DocumentsTests
//
//  Created by Павел Чернышев on 25.11.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

@testable import Documents
import XCTest

class ASCPortalTypeDefinderByUrlTests: XCTestCase {
    var sut: ASCPortalTypeDefinderByUrl!

    override func setUpWithError() throws {
        sut = ASCPortalTypeDefinderByUrl()
        try super.setUpWithError()
    }

    override func tearDownWithError() throws {
        sut = nil
        try super.tearDownWithError()
    }

    func testWhenDoNotHavePersonalPortalReturnsUnknown() {
        sut.url = URL(string: "https://foo.com/bar/baz")
        XCTAssertEqual(sut.definePortalType(), .unknown)
    }

    func testWhenPersonalOfficeReturnsPersonal() {
        sut.url = URL(string: "https://personal.onlyoffice.com/bar/baz")
        XCTAssertEqual(sut.definePortalType(), .personal)
    }

    func testWhenPersonalTestReturnsPersonal() {
        sut.url = URL(string: "http://personal.teamlab.info/bar/baz")
        XCTAssertEqual(sut.definePortalType(), .personal)
    }
}
