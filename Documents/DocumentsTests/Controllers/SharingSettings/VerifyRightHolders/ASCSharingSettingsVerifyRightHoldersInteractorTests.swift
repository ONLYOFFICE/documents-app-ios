//
//  ASCSharingSettingsVerifyRightHoldersInteractorTests.swift
//  DocumentsTests
//
//  Created by Павел Чернышев on 16.07.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import XCTest
@testable import Documents

class ASCSharingSettingsVerifyRightHoldersInteractorTests: XCTestCase {
    
    
    var sut: ASCSharingSettingsVerifyRightHoldersInteractor!
    var presenter: PresenterMock!

    override func setUpWithError() throws {
        sut = ASCSharingSettingsVerifyRightHoldersInteractor(apiWorker: SharingSettingAPIWorkerMock())
        presenter = PresenterMock()
        sut.presenter = presenter
    }

    override func tearDownWithError() throws {
        presenter = nil
        sut = nil
    }

    // MARK: - Access change func tests
    func testWhenWeHaveSharedItemAndChengeAccessThenSharedItemCopyAddsToItemsForChange() {
        let userShareInfo = makeUserShareInfo(withId: "Foo", andAceess: .read)
        let model = makeModel(withId: "Foo", andAccess: .read)
        let newAccess: ASCShareAccess = .comment
        
        sut.sharedInfoItems = [userShareInfo]
        sut.makeRequest(requestType: .accessChange(.init(model: model, newAccess: newAccess)))
        
        XCTAssertTrue(sut.sharedInfoItems.count == 1)
        XCTAssertTrue(sut.itemsForSharedAccessChange.count == 1)
        XCTAssertTrue(sut.itemsForSharingAdd.count == 0)
        XCTAssertTrue(sut.itemsForSharingRemove.count == 0)
        
        XCTAssertEqual(sut.sharedInfoItems[0].access, .read)
        XCTAssertEqual(sut.itemsForSharedAccessChange[0].access, newAccess)
        XCTAssertEqual(sut.itemsForSharedAccessChange[0].user?.userId, "Foo")
        XCTAssertEqual(sut.sharedInfoItems[0].user?.userId, "Foo")
    }
    
    func testWhenWeHaveSharedItemAndTheSameItemInItemsForChangeAccessAndWhenWeChangeAccessToOriginThenItemsForChangeWillBeEmpty() {
        let originAccess: ASCShareAccess = .read
        let userShareInfo = makeUserShareInfo(withId: "Foo", andAceess: originAccess)
        let model = makeModel(withId: "Foo", andAccess: originAccess)
        let newAccess: ASCShareAccess = .comment
        
        sut.sharedInfoItems = [userShareInfo]
        sut.makeRequest(requestType: .accessChange(.init(model: model, newAccess: newAccess)))
        sut.makeRequest(requestType: .accessChange(.init(model: model, newAccess: originAccess)))
        
        XCTAssertTrue(sut.sharedInfoItems.count == 1)
        XCTAssertTrue(sut.itemsForSharedAccessChange.count == 0)
        XCTAssertTrue(sut.itemsForSharingAdd.count == 0)
        XCTAssertTrue(sut.itemsForSharingRemove.count == 0)
        
        XCTAssertEqual(sut.sharedInfoItems[0].access, originAccess)
        XCTAssertEqual(sut.sharedInfoItems[0].user?.userId, "Foo")
    }
    
    func testWhenWeHaveSharedItemAndTheSameItemInItemsForChangeAccessAndWhenWeChangeAccessThenAccessWillChanged() {
        let originAccess: ASCShareAccess = .read
        let userShareInfo = makeUserShareInfo(withId: "Foo", andAceess: originAccess)
        let model = makeModel(withId: "Foo", andAccess: originAccess)
        let secondAceess: ASCShareAccess = .comment
        let thirdAccess: ASCShareAccess = .deny
        
        sut.sharedInfoItems = [userShareInfo]
        sut.makeRequest(requestType: .accessChange(.init(model: model, newAccess: secondAceess)))
        sut.makeRequest(requestType: .accessChange(.init(model: model, newAccess: thirdAccess)))
        
        XCTAssertTrue(sut.sharedInfoItems.count == 1)
        XCTAssertTrue(sut.itemsForSharedAccessChange.count == 1)
        XCTAssertTrue(sut.itemsForSharingAdd.count == 0)
        XCTAssertTrue(sut.itemsForSharingRemove.count == 0)
        
        XCTAssertEqual(sut.sharedInfoItems[0].access, .read)
        XCTAssertEqual(sut.itemsForSharedAccessChange[0].access, thirdAccess)
        XCTAssertEqual(sut.itemsForSharedAccessChange[0].user?.userId, "Foo")
        XCTAssertEqual(sut.sharedInfoItems[0].user?.userId, "Foo")
    }
    
    func testWhenWeDoNotHaveItemInItemsForAddAndWeChandeAccessForOtherModelThenDoesntHapen() {
        
        let originAccess: ASCShareAccess = .read
        let model = makeModel(withId: "Foo", andAccess: originAccess)
        sut.makeRequest(requestType: .accessChange(.init(model: model, newAccess: originAccess)))
        
        XCTAssertTrue(sut.sharedInfoItems.count == 0)
        XCTAssertTrue(sut.itemsForSharedAccessChange.count == 0)
        XCTAssertTrue(sut.itemsForSharingAdd.count == 0)
        XCTAssertTrue(sut.itemsForSharingRemove.count == 0)
    }
    
    func testWhenWeHaveItemInItemsForAddAndWeChangeAceessThenAccessWillChange() {
        let originAccess: ASCShareAccess = .read
        let userShareInfo = makeUserShareInfo(withId: "Foo", andAceess: originAccess)
        let model = makeModel(withId: "Foo", andAccess: originAccess)
        let newAccess: ASCShareAccess = .full
        
        sut.itemsForSharingAdd = [userShareInfo]
        sut.makeRequest(requestType: .accessChange(.init(model: model, newAccess: newAccess)))
        
        XCTAssertTrue(sut.sharedInfoItems.count == 0)
        XCTAssertTrue(sut.itemsForSharedAccessChange.count == 0)
        XCTAssertTrue(sut.itemsForSharingAdd.count == 1)
        XCTAssertTrue(sut.itemsForSharingRemove.count == 0)
        
        XCTAssertEqual(sut.itemsForSharingAdd[0].access, newAccess)
        XCTAssertEqual(sut.itemsForSharingAdd[0].user?.userId, "Foo")
    }
    
    /// we don't show any items for remove becouse they were unselected on previews screen
    func testWhenWeHaveItemInItmesForRemoveAndChnageAccessThenDoesntHappen() {
        let originAccess: ASCShareAccess = .deny
        let userShareInfo = makeUserShareInfo(withId: "Foo", andAceess: originAccess)
        let model = makeModel(withId: "Foo", andAccess: originAccess)
        let newAccess: ASCShareAccess = .comment
        
        sut.itemsForSharingRemove = [userShareInfo]
        sut.makeRequest(requestType: .accessChange(.init(model: model, newAccess: newAccess)))
        
        XCTAssertTrue(sut.sharedInfoItems.count == 0)
        XCTAssertTrue(sut.itemsForSharedAccessChange.count == 0)
        XCTAssertTrue(sut.itemsForSharingAdd.count == 0)
        XCTAssertTrue(sut.itemsForSharingRemove.count == 1)
        
        XCTAssertEqual(sut.itemsForSharingRemove[0].access, originAccess)
        XCTAssertEqual(sut.itemsForSharingRemove[0].user?.userId, "Foo")
    }
    
    
    // MARK: - Access delete func tests
    func testWhenWeHaveSharedItemAndRemoveAccessThenSharedItemCopyAddsToItemsForRemoving() {
        let userShareInfo = makeUserShareInfo(withId: "Foo", andAceess: .read)
        let model = makeModel(withId: "Foo", andAccess: .read)
        
        sut.sharedInfoItems = [userShareInfo]
        sut.makeRequest(requestType: .accessRemove(.init(model: model, indexPath: IndexPath(row: 0, section: 0))))
        
        XCTAssertTrue(sut.sharedInfoItems.count == 1)
        XCTAssertTrue(sut.itemsForSharedAccessChange.count == 0)
        XCTAssertTrue(sut.itemsForSharingAdd.count == 0)
        XCTAssertTrue(sut.itemsForSharingRemove.count == 1)
        
        XCTAssertEqual(sut.sharedInfoItems[0].access, .read)
        XCTAssertEqual(sut.itemsForSharingRemove[0].access, .none)
        XCTAssertEqual(sut.itemsForSharingRemove[0].user?.userId, "Foo")
        XCTAssertEqual(sut.sharedInfoItems[0].user?.userId, "Foo")
    }
    
    func testWhenWeHaveItemInItemsForAddAndWeRemoveAceessThenAccessWillRemoveFromItemsForAdd() {
        let originAccess: ASCShareAccess = .read
        let userShareInfo = makeUserShareInfo(withId: "Foo", andAceess: originAccess)
        let model = makeModel(withId: "Foo", andAccess: originAccess)
        
        sut.itemsForSharingAdd = [userShareInfo]
        sut.makeRequest(requestType: .accessRemove(.init(model: model, indexPath: IndexPath(row: 0, section: 0))))
        
        XCTAssertTrue(sut.sharedInfoItems.count == 0)
        XCTAssertTrue(sut.itemsForSharedAccessChange.count == 0)
        XCTAssertTrue(sut.itemsForSharingAdd.count == 0)
        XCTAssertTrue(sut.itemsForSharingRemove.count == 0)
    
    }
    
    // MARK: - load share items func tests
    func testWhenWeHaveSharedItemThenWeWillShowIt() {
        let originAccess: ASCShareAccess = .read
        let userShareInfo = makeUserShareInfo(withId: "Foo", andAceess: originAccess)
        
        sut.sharedInfoItems = [userShareInfo]
        
        sut.makeRequest(requestType: .loadShareItems)
        
        XCTAssertTrue(presenter.shareItemsResponse?.items.count == 1)
    }
    
    func testWhenWeHaveItemForAddThenWeWillShowIt() {
        let originAccess: ASCShareAccess = .read
        let userShareInfo = makeUserShareInfo(withId: "Foo", andAceess: originAccess)
        
        sut.itemsForSharingAdd = [userShareInfo]
        
        sut.makeRequest(requestType: .loadShareItems)
        
        XCTAssertTrue(presenter.shareItemsResponse?.items.count == 1)
    }
    
    func testWhenWeHaveItemForRemoveThenWeWillShowNothing() {
        let originAccess: ASCShareAccess = .read
        let userShareInfo = makeUserShareInfo(withId: "Foo", andAceess: originAccess)
        
        sut.itemsForSharingRemove = [userShareInfo]
        
        sut.makeRequest(requestType: .loadShareItems)
        
        XCTAssertTrue(presenter.shareItemsResponse?.items.count == 0)
    }
    
    /// becase this var for change alredy displaying shared items
    func testWhenWeHaveItemForChangeThenWeWillShowNothing() {
        let originAccess: ASCShareAccess = .read
        let userShareInfo = makeUserShareInfo(withId: "Foo", andAceess: originAccess)
        let model = makeModel(withId: "Foo", andAccess: originAccess)
        let secondAceess: ASCShareAccess = .comment
        
        sut.sharedInfoItems = [userShareInfo]
        sut.makeRequest(requestType: .accessChange(.init(model: model, newAccess: secondAceess)))
        sut.sharedInfoItems = []
        
        sut.makeRequest(requestType: .loadShareItems)
        
        XCTAssertTrue(presenter.shareItemsResponse?.items.count == 0)
    }

    
    /// we don't show any items for remove becouse they were unselected on previews screen
    func testWhenWeHaveSharedItemAndTheSameItemForRemomeThenWeWillShowNothing() {
        let originAccess: ASCShareAccess = .read
        let userShareInfo = makeUserShareInfo(withId: "Foo", andAceess: originAccess)
        
        sut.sharedInfoItems = [userShareInfo]
        sut.itemsForSharingRemove = [userShareInfo]
        
        sut.makeRequest(requestType: .loadShareItems)
        
        XCTAssertTrue(presenter.shareItemsResponse?.items.count == 0)
    }
    
    func testWhenWeHaveOneShareItemAndOneItemForAddThenShowBoth() {
        let userShareInfo = makeUserShareInfo(withId: "Foo", andAceess: .read)
        let groupShareInfo = makeGroupShareInfo(withId: "Bar", andAceess: .read)
        
        sut.sharedInfoItems = [userShareInfo]
        sut.itemsForSharingAdd = [groupShareInfo]
        
        sut.makeRequest(requestType: .loadShareItems)
        
        XCTAssertTrue(presenter.shareItemsResponse?.items.count == 2)
    }
    
    func testWhenWeHaveOneShareItemAndOneItemForAddAndHaveItemForRemoveThenShowOne() {
        let userShareInfo = makeUserShareInfo(withId: "Foo", andAceess: .read)
        let groupShareInfo = makeGroupShareInfo(withId: "Bar", andAceess: .read)
        
        sut.sharedInfoItems = [userShareInfo]
        sut.itemsForSharingAdd = [groupShareInfo]
        sut.itemsForSharingRemove = [userShareInfo]
        
        sut.makeRequest(requestType: .loadShareItems)
        
        XCTAssertTrue(presenter.shareItemsResponse?.items.count == 1)
        XCTAssertEqual(presenter.shareItemsResponse?.items[0].group?.id, "Bar")
    }
    
    // MARK: - Help functions
    func makeModel(withId id: String, andAccess access: ASCShareAccess) -> ASCSharingRightHolderViewModel {
        ASCSharingRightHolderViewModel(id: id, name: "", access: .init(entityAccess: access, accessEditable: true))
    }
    
    func makeUserShareInfo(withId id: String, andAceess access: ASCShareAccess) -> ASCShareInfo {
        let user = ASCUser()
        user.userId = id
        return ASCShareInfo(access: access, user: user)
    }
    
    func makeGroupShareInfo(withId id: String, andAceess access: ASCShareAccess) -> ASCShareInfo {
        let group = ASCGroup()
        group.id = id
        return ASCShareInfo(access: access, group: group)
    }
}

extension ASCSharingSettingsVerifyRightHoldersInteractorTests {
    class PresenterMock: ASCSharingSettingsVerifyRightHoldersPresentationLogic {
        typealias Response = ASCSharingSettingsVerifyRightHolders.Model.Response
        
        var shareItemsResponse: Response.ShareItemsResponse?
        var accessProvider: ASCSharingSettingsAccessProvider?
        var applyinShareSettingsRespons: Response.ApplyingShareSettingsResponse?
        var accessChangeResponse: Response.AccessChangeResponse?
        var accessRemoveResponse: Response.AccessRemoveResponse?
        
        func presentData(responseType: ASCSharingSettingsVerifyRightHolders.Model.Response.ResponseType) {
            switch responseType {
            case .presentShareItems(response: let response):
                shareItemsResponse = response
            case .presentAccessProvider(response: let response):
                accessProvider = response
            case .presentApplyingShareSettings(response: let response):
                applyinShareSettingsRespons = response
            case .presentAccessChange(response: let response):
                accessChangeResponse = response
            case .presentAccessRemove(response: let response):
                accessRemoveResponse = response
            }
        }
    }
    
    class SharingSettingAPIWorkerMock: ASCShareSettingsAPIWorkerProtocol {
        func convertToParams(shareItems: [ASCShareInfo]) -> [String : Any] { [:] }
        
        func convertToParams(items: [(rightHolderId: String, access: ASCShareAccess)]) -> [String : Any] { [:] }
        
        func makeApiRequest(entity: ASCEntity) -> String? { nil }
    }
}
