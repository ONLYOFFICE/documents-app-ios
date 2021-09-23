//
//  ASCSharingSettingsAccessViewControllerTests.swift
//  DocumentsTests
//
//  Created by Павел Чернышев on 04.08.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import XCTest
@testable import Documents

class ASCSharingSettingsAccessViewControllerTests: XCTestCase {
    
    var sut: ASCSharingSettingsAccessViewController!
    var accessNoteProvider: ASCSharingSettingsAccessNotesProviderProtocol!

    override func setUpWithError() throws {
        sut = ASCSharingSettingsAccessViewController()
        accessNoteProvider = ASCSharingSettingsAccessNotesProviderProtocolMock()
    }

    override func tearDownWithError() throws {
        sut = nil
    }

    func testWhenSetAccessNoteProviderForTwoAccessesThenReturnsFooterTitleForTheseAccesses() {
        let viewModel = ASCSharingSettingsAccessViewModel(currentlyAccess: .full,
                                                          accessNoteProvider: accessNoteProvider,
                                                          largeTitleDisplayMode: .always,
                                                          headerText: "")
        sut.viewModel = viewModel
        XCTAssertEqual(sut.tableView.dataSource?.tableView?(sut.tableView, titleForFooterInSection: 0), "Foo")
        
        sut.viewModel?.currentlyAccess = .deny
        XCTAssertEqual(sut.tableView.dataSource?.tableView?(sut.tableView, titleForFooterInSection: 0), "Bar")
        
        sut.viewModel?.currentlyAccess = .comment
        XCTAssertEqual(sut.tableView.dataSource?.tableView?(sut.tableView, titleForFooterInSection: 0), nil)
        
    }

}

extension ASCSharingSettingsAccessViewControllerTests {
    class ASCSharingSettingsAccessNotesProviderProtocolMock: ASCSharingSettingsAccessNotesProviderProtocol {
        func get(for access: ASCShareAccess) -> ShareAccessNote? {
            switch access {
            case .full:
                return "Foo"
            case .deny:
                return "Bar"
            default:
                return nil
            }
        }
    }
}
