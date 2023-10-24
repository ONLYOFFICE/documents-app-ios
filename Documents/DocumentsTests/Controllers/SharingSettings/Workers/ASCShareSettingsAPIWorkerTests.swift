//
//  ASCShareSettingsAPIWorkerTests.swift
//  DocumentsTests
//
//  Created by Pavel Chernyshev on 19.07.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

@testable import Documents
import XCTest

class ASCShareSettingsAPIWorkerTests: XCTestCase {
    var sut: ASCShareSettingsAPIWorker!

    override func setUpWithError() throws {
        sut = ASCShareSettingsAPIWorker()
    }

    override func tearDownWithError() throws {
        sut = nil
    }

    // MARK: - makeApiRequest func tests

    func testWhenMakeApiRequestOnFileGetsAString() {
        let file = ASCFile()
        file.id = "Foo"

        let request = sut.makeApiRequest(entity: file, for: .set)

        XCTAssertNotNil(request)
        XCTAssertTrue(request?.path.contains(file.id) ?? false)
    }

    func testWhenMakeApiRequestOnFolderGetsAString() {
        let folder = ASCFolder()
        folder.id = "Foo"

        let request = sut.makeApiRequest(entity: folder, for: .set)

        XCTAssertNotNil(request)
        XCTAssertTrue(request?.path.contains(folder.id) ?? false)
    }

    func testWhenMakeApiRequestOnEntityGetsNothing() {
        let entity = ASCEntity()
        entity.id = "Foo"

        let request = sut.makeApiRequest(entity: entity, for: .set)

        XCTAssertNil(request)
    }

    // MARK: - convertToParams(shareItems: [ASCShareInfo]) func tests

    func testConvertShareUserInfoToParams() {
        let id = "Foo"
        let access: ASCShareAccess = .read
        let shareInfo = makeUserShareInfo(withId: id, andAceess: access)

        let result = sut.convertToParams(shareItems: [shareInfo])

        XCTAssertTrue(result.count == 1)
        XCTAssertTrue(result[0].shareTo == id)
        XCTAssertTrue(result[0].access == .read)
    }

    func testConvertShareUserInfoWithShreFolderIngoToParams() {
        let userId = "Foo"
        let userAccess: ASCShareAccess = .read
        let userShareInfo = makeUserShareInfo(withId: userId, andAceess: userAccess)

        let folderId = "Boo"
        let folderAccess: ASCShareAccess = .comment
        let folderShareInfo = makeUserShareInfo(withId: folderId, andAceess: folderAccess)

        let result = sut.convertToParams(shareItems: [userShareInfo, folderShareInfo])

        XCTAssertTrue(result.count == 2)
        XCTAssertTrue(result[0].shareTo == userId)
        XCTAssertTrue(result[0].access == userAccess)
        XCTAssertTrue(result[1].shareTo == folderId)
        XCTAssertTrue(result[1].access == folderAccess)
    }

    func testConvertShareInfoWithouUserAndGroupToParamsReturnsEmpty() {
        let shareInfo = OnlyofficeShare()

        let result = sut.convertToParams(shareItems: [shareInfo])

        XCTAssertTrue(result.count == 0)
    }

    // MARK: - converToParams(items: [(rightHolderId: String, access: ASCShareAccess)]) func tests

    func testConvertItemsFooAndBarToParams() {
        let foo: (rightHolderId: String, access: ASCShareAccess) = ("Foo", ASCShareAccess.read)
        let bar: (rightHolderId: String, access: ASCShareAccess) = ("Bar", ASCShareAccess.deny)

        let result = sut.convertToParams(items: [foo, bar])

        XCTAssertTrue(result.count == 2)
        XCTAssertTrue(result[0].shareTo == foo.rightHolderId)
        XCTAssertTrue(result[0].access == foo.access)
        XCTAssertTrue(result[1].shareTo == bar.rightHolderId)
        XCTAssertTrue(result[1].access == bar.access)
    }

    // MARK: - Help functions

    func makeUserShareInfo(withId id: String, andAceess access: ASCShareAccess) -> OnlyofficeShare {
        let user = ASCUser()
        user.userId = id
        return OnlyofficeShare(access: access, user: user)
    }

    func makeGroupShareInfo(withId id: String, andAceess access: ASCShareAccess) -> OnlyofficeShare {
        let group = ASCGroup()
        group.id = id
        return OnlyofficeShare(access: access, group: group)
    }
}
