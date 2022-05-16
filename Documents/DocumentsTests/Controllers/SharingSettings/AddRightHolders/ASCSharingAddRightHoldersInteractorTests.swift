//
//  ASCSharingAddRightHoldersInteractorTests.swift
//  DocumentsTests
//
//  Created by Pavel Chernyshev on 18.04.2022.
//  Copyright © 2022 Ascensio System SIA. All rights reserved.
//

@testable import Documents
import XCTest

class ASCSharingAddRightHoldersInteractorTests: XCTestCase {
    var sut: ASCSharingAddRightHoldersInteractor!
    var dataStore: ASCSharingAddRightHoldersRAMDataStore! {
        didSet {
            sut.dataStore = dataStore
        }
    }

    override func setUpWithError() throws {
        try? super.setUpWithError()
        sut = ASCSharingAddRightHoldersInteractor()
        dataStore = ASCSharingAddRightHoldersRAMDataStore()
    }

    override func tearDownWithError() throws {
        dataStore = nil
        sut.dataStore = nil
        sut = nil
        try? super.tearDownWithError()
    }

    func testWhenSelectUserAndChangeAccessThenSelectedUserAccessChanged() throws {
        let user = user(id: "Foo", name: "Foo")
        dataStore.users.append(user)
        sut.makeRequest(requestType: .selectViewModel(.init(selectedViewModel: .init(id: user.userId!, name: user.userName!, rightHolderType: .user), access: .read)))
        sut.makeRequest(requestType: .changeAccessForSelected(.comment))
        XCTAssertEqual(sut.dataStore!.itemsForSharingAdd[0].access, .comment)
    }

    func testWhenSelectGroupAndChangeAccessThenSelectedGroupAccessChanged() throws {
        let group = group(id: "Foo", name: "Foo")
        dataStore.groups.append(group)
        sut.makeRequest(requestType: .selectViewModel(.init(selectedViewModel: .init(id: group.id!, name: group.name!, rightHolderType: .group), access: .comment)))
        sut.makeRequest(requestType: .changeAccessForSelected(.full))
        XCTAssertEqual(sut.dataStore!.itemsForSharingAdd[0].access, .full)
    }

    func testWhenChangeAccessForSelectedUsersWhoHaveAccessDidntChanges() {
        let userWithExistAccess = user(id: "Bar", name: "Bar")
        userWithExistAccess.accessValue = .full
        let user = user(id: "Foo", name: "Foo")
        dataStore.sharedInfoItems = [makeUserShareInfo(withId: userWithExistAccess.userId!,
                                                       access: userWithExistAccess.accessValue)]
        dataStore.users.append(userWithExistAccess)
        dataStore.users.append(user)
        sut.makeRequest(requestType: .selectViewModel(.init(selectedViewModel: .init(id: user.userId!, name: user.userName!, rightHolderType: .user), access: .read)))
        sut.makeRequest(requestType: .changeAccessForSelected(.comment))
        XCTAssertEqual(sut.dataStore!.sharedInfoItems[0].access, .full)
    }

    // MARK: - Help functions

    func makeUserShareInfo(withId id: String, access: ASCShareAccess) -> OnlyofficeShare {
        let user = ASCUser()
        user.userId = id
        return OnlyofficeShare(access: access, user: user)
    }

    func user(id: String, name: String) -> ASCUser {
        let user = ASCUser()
        user.userId = id
        user.userName = name
        return user
    }

    func group(id: String, name: String) -> ASCGroup {
        let group = ASCGroup()
        group.id = id
        group.name = name
        return group
    }
}
