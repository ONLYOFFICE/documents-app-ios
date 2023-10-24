//
//  ASCSharingOptionsViewControllerTest.swift
//  DocumentsTests
//
//  Created by Pavel Chernyshev on 01.07.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

@testable import Documents
import UIKit
import XCTest

class ASCSharingOptionsViewControllerTest: XCTestCase {
    var sut: ASCSharingOptionsViewController!
    var navigationController: UINavigationController!
    var tableView: UITableView!
    let mockSourceViewController = MockSourceViewController()

    override func setUpWithError() throws {
        sut = ASCSharingOptionsViewController(sourceViewController: mockSourceViewController)
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

    func testWhenFileEntityThenFirstAndSecondSectionTitlesOnlySecondNotEmpty() {
        sut.setup(entity: ASCFile())
        sut.loadViewIfNeeded()

        XCTAssertTrue(sut.tableView(tableView, titleForHeaderInSection: 0)?.isEmpty ?? false)
        XCTAssertTrue(!(sut.tableView(tableView, titleForHeaderInSection: 1)?.isEmpty ?? false))
        XCTAssertTrue(sut.tableView(tableView, titleForHeaderInSection: 2)?.isEmpty ?? false)
    }

    func testWhenFolderEntityThenFirstSectionTitleFillAndSecondIsEmpty() {
        sut.setup(entity: ASCFolder())
        sut.loadViewIfNeeded()

        XCTAssertTrue(!(sut.tableView(tableView, titleForHeaderInSection: 0)?.isEmpty ?? false))
        XCTAssertTrue(sut.tableView(tableView, titleForHeaderInSection: 1)?.isEmpty ?? false)
    }

    func testWhenFolderEntityAndOneImportandAndTreeOterUsersThenWeHaveOneRowInFirstSectionAndThreeRowsInSecondSection() {
        let folder = ASCFolder()
        sut.setup(entity: folder)

        let interactor = InteractorMock()
        let presenter = ASCSharingOptionsPresenter(entity: folder)
        presenter.viewController = sut
        interactor.presenter = presenter
        sut.interactor = interactor

        let owner = makeUserShareInfo(withId: "Owner", andAceess: .full)
        interactor.currentUser = owner.user
        interactor.sharedInfoItems = [
            owner,
            makeUserShareInfo(withId: "Foo", andAceess: .read),
            makeUserShareInfo(withId: "Bar", andAceess: .comment),
            makeUserShareInfo(withId: "Baz", andAceess: .review),
        ]
        sut.interactor?.makeRequest(request: .loadRightHolders(.init(entity: folder)))
        sut.loadViewIfNeeded()

        let importantCell = sut.tableView(tableView, cellForRowAt: IndexPath(row: 0, section: 0)) as! ASCSharingRightHolderTableViewCell
        XCTAssertEqual(importantCell.viewModel?.id, "Owner")
        let otherFirstCell = sut.tableView(tableView, cellForRowAt: IndexPath(row: 0, section: 1)) as! ASCSharingRightHolderTableViewCell
        let otherSecondCell = sut.tableView(tableView, cellForRowAt: IndexPath(row: 1, section: 1)) as! ASCSharingRightHolderTableViewCell
        let otherThirdCell = sut.tableView(tableView, cellForRowAt: IndexPath(row: 2, section: 1)) as! ASCSharingRightHolderTableViewCell
        XCTAssertEqual(otherFirstCell.viewModel?.id, "Foo")
        XCTAssertEqual(otherSecondCell.viewModel?.id, "Bar")
        XCTAssertEqual(otherThirdCell.viewModel?.id, "Baz")
    }

    func makeUserShareInfo(withId id: String, andAceess access: ASCShareAccess) -> OnlyofficeShare {
        let user = ASCUser()
        user.userId = id
        return OnlyofficeShare(access: access, user: user)
    }
}

extension ASCSharingOptionsViewControllerTest {
    class InteractorMock: ASCSharingOptionsBusinessLogic, ASCSharingOptionsDataStore {
        var presenter: ASCSharingOptionsPresentationLogic?
        func makeRequest(request: ASCSharingOptions.Model.Request.RequestType) {
            switch request {
            case .loadRightHolders:
                presenter?.presentData(
                    response: .presentRightHolders(.success(.init(sharedInfoItems: sharedInfoItems,
                                                                  currentUser: currentUser,
                                                                  internalLink: internalLink,
                                                                  externalLink: externalLink))))
            case .changeRightHolderAccess:
                fatalError("doesn't implemented")
            case .removeRightHolderAccess:
                fatalError("doesn't implemented")
            case .clearData:
                fatalError("doesn't implemented")
            }
        }

        var entity: ASCEntity?

        var entityOwner: ASCUser?

        var currentUser: ASCUser?

        var sharedInfoItems: [OnlyofficeShare] = []

        var internalLink: String?
        var externalLink: ASCSharingOprionsExternalLink?
    }

    class MockSourceViewController: UIViewController {
        var presentWasCalled = false

        override func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
            presentWasCalled = true
        }
    }
}
