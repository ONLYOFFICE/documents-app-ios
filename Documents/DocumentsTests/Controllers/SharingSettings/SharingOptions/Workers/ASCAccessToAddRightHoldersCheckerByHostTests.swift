//
//  ASCAccessToAddRightHoldersCheckerByHostTests.swift
//  DocumentsTests
//
//  Created by Павел Чернышев on 24.11.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import XCTest
@testable import Documents

class ASCAccessToAddRightHoldersCheckerByHostTests: XCTestCase {
    
    
    var sut: ASCAccessToAddRightHoldersCheckerByHost!

    override func setUpWithError() throws {
        try super.setUpWithError()
    }

    override func tearDownWithError() throws {
        sut = nil
        try super.tearDownWithError()
    }

    func testWhenNilHostThenReturnsFalse() {
        sut = ASCAccessToAddRightHoldersCheckerByHost(host: nil)
        XCTAssertFalse(sut.checkAccessToAddRightHolders())
    }

    func testWhenFooDotBarHostThenReturnsTrue() {
        sut = ASCAccessToAddRightHoldersCheckerByHost(host: "foo.bar")
        XCTAssertTrue(sut.checkAccessToAddRightHolders())
    }
    
    func testWhenPersonalHoserThenReturnsFalse() {
        sut = ASCAccessToAddRightHoldersCheckerByHost(host: "personal.teamlab.info")
        XCTAssertFalse(sut.checkAccessToAddRightHolders())
    }
}
