//
//  ASCASCSharingSettingsVerifyRightHoldersTests.swift
//  DocumentsTests
//
//  Created by Павел Чернышев on 13.07.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import XCTest
@testable import Documents

class ASCSharingSettingsVerifyRightHoldersTests: XCTestCase {
    
    typealias VerifySection = ASCSharingSettingsVerifyRightHoldersViewController.Section
    
    var sut: ASCSharingSettingsVerifyRightHoldersViewController!
    var tableView: UITableView!

    override func setUpWithError() throws {
        sut = ASCSharingSettingsVerifyRightHoldersViewController()
        tableView = MockTableView.mockTableView(withDataSource: sut, andWithDelegate: sut)
        sut.tableView = tableView
        sut.loadViewIfNeeded()
        sut.load()
    }

    override func tearDownWithError() throws {
        sut = nil
        tableView = nil
    }

    func testWhenSelectNotificationRowThenNumberOfRowsInNotifySectionIncreaseBy1() {
        
        XCTAssertEqual(sut.tableView.numberOfRows(inSection: VerifySection.notify.rawValue), 1)
        
        let rowIndexPath = IndexPath(row: VerifySection.Notify.switcher.rawValue,
                                     section: VerifySection.notify.rawValue)
        
        guard let switchCell = sut.tableView(tableView, cellForRowAt: rowIndexPath) as? ASCSwitchTableViewCell
        else {
            XCTFail("Couldn't cast cell to ASCSwitchTableViewCell")
            return
        }
        switchCell.uiSwitch.isOn = true
        switchCell.switchChanged(uiSwitch: switchCell.uiSwitch)
        XCTAssertEqual(sut.tableView.numberOfRows(inSection: 0), 2)
        
        switchCell.uiSwitch.isOn = false
        switchCell.switchChanged(uiSwitch: switchCell.uiSwitch)
        XCTAssertEqual(sut.tableView.numberOfRows(inSection: 0), 1)
    }
    
    func testCellForFirstNotificationRowIsASCSwitchTableViewCell() {
        let rowIndexPath = IndexPath(row: VerifySection.Notify.switcher.rawValue,
                                     section: VerifySection.notify.rawValue)
        
        let switchCell = sut.tableView(tableView, cellForRowAt: rowIndexPath) as? ASCSwitchTableViewCell

        XCTAssertNotNil(switchCell)
    }
    
    
    func testCellForSecondNotificationRowIsASCTextViewTableViewCell() {
        let switchRowIndexPath = IndexPath(row: VerifySection.Notify.switcher.rawValue,
                                     section: VerifySection.notify.rawValue)
        guard let switchCell = sut.tableView(tableView, cellForRowAt: switchRowIndexPath) as? ASCSwitchTableViewCell
        else {
            XCTFail("Couldn't cast cell to ASCSwitchTableViewCell")
            return
        }
        
        switchCell.uiSwitch.isOn = true
        switchCell.switchChanged(uiSwitch: switchCell.uiSwitch)
        
        let rowIndexPath = IndexPath(row: VerifySection.Notify.message.rawValue,
                                     section: VerifySection.notify.rawValue)
        let textCell = sut.tableView(tableView, cellForRowAt: rowIndexPath) as? ASCTextViewTableViewCell
        
        XCTAssertNotNil(textCell)
    }
    
    func testCellForUsersSectionIsASCSharingRightHolderTableViewCell() {
        let user = ASCSharingRightHolderViewModel(id: "", avatarUrl: nil, name: "Foo", department: "manager", isOwner: true, access: .init(documetAccess: .full, accessEditable: false))
        sut.usersModels = [user]
        
        let rowIndexPath = IndexPath(row: 0, section: VerifySection.users.rawValue)
        
        let userCell = sut.tableView(tableView, cellForRowAt: rowIndexPath) as? ASCSharingRightHolderTableViewCell
        
        XCTAssertNotNil(userCell)
    }
    
    func testCellForGroupsSectionIsASCSharingRightHolderTableViewCell() {
        sut.usersModels = []
        let group = ASCSharingRightHolderViewModel(id: "", avatarUrl: nil, name: "Bar", access: .init(documetAccess: .read, accessEditable: true))
        sut.groupsModels = [group]
        
        let rowIndexPath = IndexPath(row: 0, section: 2)
    
        let groupCell = sut.tableView(tableView, cellForRowAt: rowIndexPath) as? ASCSharingRightHolderTableViewCell
        
        XCTAssertNotNil(groupCell)
    }
}

extension ASCSharingSettingsVerifyRightHoldersTests {
    class MockTableView: UITableView {
        
        static func mockTableView(withDataSource dataSource: UITableViewDataSource, andWithDelegate delegate: UITableViewDelegate) -> MockTableView {
            let mockTableView = MockTableView(frame: CGRect(x: 0, y: 0, width: 100, height: 100), style: .grouped)
            mockTableView.dataSource = dataSource
            mockTableView.delegate = delegate
            return mockTableView
        }
    }

}
