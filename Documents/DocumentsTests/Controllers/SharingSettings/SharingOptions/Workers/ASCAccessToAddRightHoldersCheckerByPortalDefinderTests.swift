//
//  ASCAccessToAddRightHoldersCheckerByPortalDefinderTests.swift
//  DocumentsTests
//
//  Created by Павел Чернышев on 25.11.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

@testable import Documents
import XCTest

class ASCAccessToAddRightHoldersCheckerByPortalDefinderTests: XCTestCase {
    var sut: ASCAccessToAddRightHoldersCheckerByPortalDefinder!

    override func setUpWithError() throws {
        try super.setUpWithError()
    }

    override func tearDownWithError() throws {
        sut = nil
        try super.tearDownWithError()
    }

    func testWhenUnknownPortalThenReturnsTrue() {
        sut = ASCAccessToAddRightHoldersCheckerByPortalDefinder(portalType: .unknown)
        XCTAssertTrue(sut.checkAccessToAddRightHolders())
    }

    func testWhenPersonalPortalThenReturnsFalse() {
        sut = ASCAccessToAddRightHoldersCheckerByPortalDefinder(portalType: .personal)
        XCTAssertFalse(sut.checkAccessToAddRightHolders())
    }
}
