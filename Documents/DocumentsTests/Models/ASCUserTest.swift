//
//  ASCUserTest.swift
//  DocumentsTests
//
//  Created by Lolita Chernysheva on 21.09.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

@testable import Documents
import XCTest

final class ASCUserTest: XCTestCase {
    var sut: ASCUser!

    override func setUpWithError() throws {
        sut = ASCUser()
    }

    override func tearDownWithError() throws {
        sut = nil
    }

    func testWhenIsAdminAndIsVisitorAndIsCollaboratorFalseThenUserTypeRoomAdmin() {
        sut.isAdmin = false
        sut.isVisitor = false
        sut.isCollaborator = false

        XCTAssertEqual(sut.userType, .roomAdmin)
    }

    func testWhenIsAdminThenUserTypeDocspaceAdmin() {
        sut.isAdmin = true
        sut.isVisitor = false
        sut.isCollaborator = false

        XCTAssertEqual(sut.userType, .docspaseAdmin)
    }

    func testWhenIsVisitorThenUserTypeUser() {
        sut.isVisitor = true
        sut.isAdmin = false
        sut.isCollaborator = false

        XCTAssertEqual(sut.userType, .user)
    }

    func testWhenIsCollaboratorThenUserTypePowerUser() {
        sut.isCollaborator = true
        sut.isAdmin = false
        sut.isVisitor = false

        XCTAssertEqual(sut.userType, .powerUser)
    }
}
