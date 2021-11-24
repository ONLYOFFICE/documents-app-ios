//
//  ASCShareSettingsAPIWorkerFactoryTests.swift
//  DocumentsTests
//
//  Created by Павел Чернышев on 24.11.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import Foundation
import XCTest
@testable import Documents

class ASCShareSettingsAPIWorkerFactoryTests: XCTestCase {
    
    var sut: ASCShareSettingsAPIWorkerFactory!

    override func setUpWithError() throws {
        sut = ASCShareSettingsAPIWorkerFactory()
        try super.setUpWithError()
    }

    override func tearDownWithError() throws {
        sut = nil
        try super.tearDownWithError()
    }

    func testWhenPersonalHostReturnsPersonalWorker() {
        let worker = sut.get(by: "personal.teamlab.info")
        XCTAssertTrue(worker is ASCPersonalShareSettingsAPIWorker)
    }
    
    func testWhenEmptyHostReturnsBaseShareSettingsWorker() {
        let worker = sut.get(by: nil)
        XCTAssertTrue(worker is ASCShareSettingsAPIWorker)
    }
}
