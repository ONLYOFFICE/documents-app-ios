//
//  ASCSharingOptionsViewControllerTest.swift
//  DocumentsTests
//
//  Created by Павел Чернышев on 01.07.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import XCTest
import UIKit
@testable import Documents

class ASCSharingOptionsViewControllerTest: XCTestCase {
    
    var sut: ASCSharingOptionsViewController!
    var navigationController: UINavigationController!
    var tableView: UITableView!

    override func setUpWithError() throws {
        sut = ASCSharingOptionsViewController(style: .grouped)
        tableView = sut.tableView
    }

    override func tearDownWithError() throws {
        sut = nil
    }

    func testWhenFolderEntityCountOfSectionsEqualsTwo() throws {
        sut.setup(entity: ASCFolder())
        sut.loadViewIfNeeded()
        XCTAssertEqual(sut.numberOfSections(in: tableView), 2)
    }
    
    func testWhenFileEntityCountOfSectionsEqualsThree() throws {
        sut.setup(entity: ASCFile())
        sut.loadViewIfNeeded()
        XCTAssertEqual(sut.numberOfSections(in: tableView), 3)
    }
    
    func testWhenFileEntityThenFirstAndSecondSectionTitlesFillAndThirdIsEmpty() {
        sut.setup(entity: ASCFile())
        sut.loadViewIfNeeded()
        
        XCTAssertTrue(!(sut.tableView(tableView, titleForHeaderInSection: 0)?.isEmpty ?? false))
        XCTAssertTrue(!(sut.tableView(tableView, titleForHeaderInSection: 1)?.isEmpty ?? false))
        XCTAssertTrue((sut.tableView(tableView, titleForHeaderInSection: 2)?.isEmpty ?? false))
    }
    
    func testWhenFolderEntityThenFirstSectionTitleFillAndSecondIsEmpty() {
        sut.setup(entity: ASCFolder())
        sut.loadViewIfNeeded()
        
        XCTAssertTrue(!(sut.tableView(tableView, titleForHeaderInSection: 0)?.isEmpty ?? false))
        XCTAssertTrue((sut.tableView(tableView, titleForHeaderInSection: 1)?.isEmpty ?? false))
    }

}
