//
//  ASCSharingAddRightHoldersDataStoreTests.swift
//  DocumentsTests
//
//  Created by Павел Чернышев on 13.07.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import XCTest
@testable import Documents


class ASCSharingAddRightHoldersDataStoreTests: XCTestCase {

    var sut: ASCSharingAddRightHoldersRAMDataStore!
    
    var userShareInfo: OnlyofficeShare!
    var groupShareInfo: OnlyofficeShare!
    
    override func setUpWithError() throws {
        sut = ASCSharingAddRightHoldersRAMDataStore()
        userShareInfo = makeUserShareInfo(withId: "Foo")
        groupShareInfo = makeGroupShareInfo(withId: "Bar")
    }

    override func tearDownWithError() throws {
        sut = nil
        userShareInfo = nil
        groupShareInfo = nil
    }

    // MARK: - test add function
    func testWhenAddShareInfroIntoEmptySUTWillAddToSharingIntemsToAdd() {
        sut.add(shareInfo: OnlyofficeShare())
        
        XCTAssertNil(sut.currentUser)
        XCTAssertTrue(sut.users.count == 0)
        XCTAssertTrue(sut.groups.count == 0)
        XCTAssertTrue(sut.sharedInfoItems.count == 0)
        XCTAssertTrue(sut.itemsForSharingAdd.count == 1)
        XCTAssertTrue(sut.itemsForSharingRemove.count == 0)
    }
    
    func testWhenWeCallAddFunctionWithShareInfoThatExistsInSharedInfoItemsThenNothingChanges () {

        sut.sharedInfoItems = [userShareInfo, groupShareInfo]
        
        sut.add(shareInfo: userShareInfo)
        sut.add(shareInfo: groupShareInfo)
        
        XCTAssertNil(sut.currentUser)
        XCTAssertTrue(sut.users.count == 0)
        XCTAssertTrue(sut.groups.count == 0)
        XCTAssertTrue(sut.sharedInfoItems.count == 2)
        XCTAssertTrue(sut.itemsForSharingAdd.count == 0)
        XCTAssertTrue(sut.itemsForSharingRemove.count == 0)
    }
    
    func testWhenWeCallAddFunctionWithShareInfoTwiceAndOnceWithoutThatExistsInSharedInfoItemsThenWillAddOne () {
        sut.sharedInfoItems = [userShareInfo, groupShareInfo]
        
        sut.add(shareInfo: userShareInfo)
        sut.add(shareInfo: groupShareInfo)
        sut.add(shareInfo: makeUserShareInfo(withId: "Baz"))
        
        XCTAssertNil(sut.currentUser)
        XCTAssertTrue(sut.users.count == 0)
        XCTAssertTrue(sut.groups.count == 0)
        XCTAssertTrue(sut.sharedInfoItems.count == 2)
        XCTAssertTrue(sut.itemsForSharingAdd.count == 1)
        XCTAssertEqual(sut.itemsForSharingAdd.first?.user?.userId, "Baz")
        XCTAssertTrue(sut.itemsForSharingRemove.count == 0)
    }
    
    func testWhenWeCallAddWithItemExistInSharedInfoItemsAndExistInItemsForSharingRemoveThenJustRemoveFromItemsForSharingRemove() {
        sut.sharedInfoItems = [userShareInfo]
        sut.remove(shareInfo: userShareInfo)
        
        sut.add(shareInfo: userShareInfo)
        
        XCTAssertNil(sut.currentUser)
        XCTAssertTrue(sut.users.count == 0)
        XCTAssertTrue(sut.groups.count == 0)
        XCTAssertTrue(sut.sharedInfoItems.count == 1)
        XCTAssertTrue(sut.itemsForSharingAdd.count == 0)
        XCTAssertTrue(sut.itemsForSharingRemove.count == 0)
    }
    
    // MARK: - test remove function
    func testWhenWeCallRemoveFunctionOnEmptySUTThenNothingChanges() {
        sut.remove(shareInfo: OnlyofficeShare())
        
        XCTAssertNil(sut.currentUser)
        XCTAssertTrue(sut.users.count == 0)
        XCTAssertTrue(sut.groups.count == 0)
        XCTAssertTrue(sut.sharedInfoItems.count == 0)
        XCTAssertTrue(sut.itemsForSharingAdd.count == 0)
        XCTAssertTrue(sut.itemsForSharingRemove.count == 0)
    }
    
    func testWhenWeCallRemoveFuncWithItemExistInSharedInfoItemsThenTheItemWillBeInItemsForSharingRemove() {
        sut.sharedInfoItems = [userShareInfo]
        sut.remove(shareInfo: userShareInfo)
        
        XCTAssertNil(sut.currentUser)
        XCTAssertTrue(sut.users.count == 0)
        XCTAssertTrue(sut.groups.count == 0)
        XCTAssertTrue(sut.sharedInfoItems.count == 1)
        XCTAssertTrue(sut.itemsForSharingAdd.count == 0)
        XCTAssertTrue(sut.itemsForSharingRemove.count == 1)
        XCTAssertEqual(sut.itemsForSharingRemove.first?.user?.userId, "Foo")
        XCTAssertEqual(sut.itemsForSharingRemove.first?.access, ASCShareAccess.none)
    }
    
    func testWhenWeCallRemoveFuncWithItemExistInItemsForAddThenRemoveFromThere() {

        sut.add(shareInfo: userShareInfo)
        sut.remove(shareInfo: userShareInfo)
        
        XCTAssertNil(sut.currentUser)
        XCTAssertTrue(sut.users.count == 0)
        XCTAssertTrue(sut.groups.count == 0)
        XCTAssertTrue(sut.sharedInfoItems.count == 0)
        XCTAssertTrue(sut.itemsForSharingAdd.count == 0)
        XCTAssertTrue(sut.itemsForSharingRemove.count == 0)
    }

    // MARK: - Help functions
    func makeUserShareInfo(withId id: String) -> OnlyofficeShare {
        let user = ASCUser()
        user.userId = id
        return OnlyofficeShare(access: .none, user: user)
    }
    
    func makeGroupShareInfo(withId id: String) -> OnlyofficeShare {
        let group = ASCGroup()
        group.id = id
        return OnlyofficeShare(access: .none, group: group)
    }

}

