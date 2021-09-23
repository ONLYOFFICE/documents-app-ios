//
//  ASCLoadedViewControllerByProviderAndFolderFinderTests.swift
//  DocumentsTests
//
//  Created by Pavel Chernyshev on 28.05.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import XCTest
import UIKit
@testable import Documents

class ASCLoadedViewControllerByProviderAndFolderFinderTests: XCTestCase {
    
    var sut: ASCLoadedDocumentViewControllerByProviderAndFolderFinder!
    var tabbar: UITabBarController!

    override func setUpWithError() throws {
        sut = ASCLoadedDocumentViewControllerByProviderAndFolderFinder()
        
        tabbar = UITabBarController()
        tabbar.addChild(ASCDeviceSplitViewController())
        tabbar.addChild(ASCOnlyofficeSplitViewController())
        tabbar.addChild(ASCCloudsSplitViewController())
        tabbar.addChild(UIViewController())
        
        UIApplication.shared.windows.first?.rootViewController = tabbar
    }

    override func tearDownWithError() throws {
        sut = nil
        tabbar = nil
    }
    
    func testDoNotSetDocumentVCAndWhenTryToFindThenNil() {
        let request = ASCLoadedVCFinderModels.DocumentsVC.Request(folderId: "Foo", providerId: "Bar")
        
        XCTAssertNil(sut.find(requestModel: request).viewController)
    }
    
    func testWhenEmptyIdThenNil() {
        let request = ASCLoadedVCFinderModels.DocumentsVC.Request(folderId: "", providerId: "")
        
        XCTAssertNil(sut.find(requestModel: request).viewController)
    }
    
    func testSetAndSetThreeDocumentsNVCThenFindThree() {
        let fistDocumentsNVC = ASCDocumentsNavigationController()
        let secondDocumentsNVC = ASCDocumentsNavigationController()
        let thirdDocumentsNVC = ASCDocumentsNavigationController()
        
        (tabbar.children[0] as! UISplitViewController).viewControllers = [UIViewController(), secondDocumentsNVC]
        let nc = UINavigationController()
        nc.viewControllers = [UIViewController(), UIViewController()]
        (tabbar.children[1] as! UISplitViewController).viewControllers = [thirdDocumentsNVC, nc]
        (tabbar.children[2] as! UISplitViewController).viewControllers = [UIViewController(), UIViewController()]
        tabbar.addChild(fistDocumentsNVC)
        
        let documentsViewControllers = sut.getAllASCDocumentsNavigationControllers()
        
        XCTAssertEqual(documentsViewControllers.count, 3)
        XCTAssertTrue(documentsViewControllers[0] === fistDocumentsNVC)
        XCTAssertTrue(documentsViewControllers[1] === secondDocumentsNVC)
        XCTAssertTrue(documentsViewControllers[2] === thirdDocumentsNVC)
    }
    
    func testWhenSetZeroDocumentsNCReturnsNul() {
        XCTAssertNil(sut.getFirstASCDocumentsNavigationController(navigationControllers: [], withProviderId: ""))
    }
    
    func testWhenSetThreeDocumentsNCFindOne() {
        let fistDocumentsNVC = ASCDocumentsNavigationController()
        fistDocumentsNVC.addChild(MockASCDocumentsViewController.get(folderId: "Foo", providerId: "FooFoo"))
        let secondDocumentsNVC = ASCDocumentsNavigationController()
        secondDocumentsNVC.addChild(MockASCDocumentsViewController.get(folderId: "Bar", providerId: "BarBar"))
        let thirdDocumentsNVC = ASCDocumentsNavigationController()
        thirdDocumentsNVC.addChild(MockASCDocumentsViewController.get(folderId: "Baz", providerId: "BazBaz"))
        
        let foundFirstNVC = sut.getFirstASCDocumentsNavigationController(navigationControllers: [fistDocumentsNVC, secondDocumentsNVC, thirdDocumentsNVC], withProviderId: "FooFoo")
        
        XCTAssertNotNil(foundFirstNVC)
        XCTAssertTrue(foundFirstNVC === fistDocumentsNVC)
        
        let foundSecondtNVC = sut.getFirstASCDocumentsNavigationController(navigationControllers: [fistDocumentsNVC, secondDocumentsNVC, thirdDocumentsNVC], withProviderId: "BarBar")

        XCTAssertNotNil(foundSecondtNVC)
        XCTAssertTrue(foundSecondtNVC === secondDocumentsNVC)

        let foundThirdNVC = sut.getFirstASCDocumentsNavigationController(navigationControllers: [fistDocumentsNVC, secondDocumentsNVC, thirdDocumentsNVC], withProviderId: "BazBaz")

        XCTAssertNotNil(foundThirdNVC)
        XCTAssertTrue(foundThirdNVC === thirdDocumentsNVC)
        
    }
    
    func testSetOnSecondLevelDocumentsOfNavigiationControllerVCAndFindIt() {
        let navigationController = ASCDocumentsNavigationController()
        let documentsVC = MockASCDocumentsViewController.get(folderId: "Foo", providerId: "FooFoo")
        
        navigationController.addChild(MockASCDocumentsViewController.get(folderId: "Bar", providerId: "BarBar"))
        navigationController.addChild(documentsVC)
        navigationController.addChild(MockASCDocumentsViewController.get(folderId: "Baz", providerId: "BazBaz"))
        
        let foundVC = sut.getFirstASCDocumentsViewController(navigationController: navigationController, withFolderId: "Foo")
        
        XCTAssertNotNil(foundVC)
        XCTAssertTrue(documentsVC === foundVC)
    }
    
    
    func testSetDocumentVCToFirstTabFindSuccess() {
        
        let deviceNC = ASCDocumentsNavigationController()
        deviceNC.addChild(MockASCDocumentsViewController.get(folderId: "Foo1", providerId: "Foo"))
        deviceNC.addChild(MockASCDocumentsViewController.get(folderId: "Foo1/Foo1.1", providerId: "Foo"))
        deviceNC.addChild(MockASCDocumentsViewController.get(folderId: "Foo1/Foo1.1/Foo1.1.1", providerId: "Foo"))
        
        let onlyofficeNC = ASCDocumentsNavigationController()
        onlyofficeNC.addChild(MockASCDocumentsViewController.get(folderId: "Bar1", providerId: "Bar"))
        onlyofficeNC.addChild(MockASCDocumentsViewController.get(folderId: "Bar1/Bar1.1", providerId: "Bar"))
        onlyofficeNC.addChild(MockASCDocumentsViewController.get(folderId: "Bar1/Bar1.1/Bar1.1.1", providerId: "Bar"))
        
        let cloudNC = ASCDocumentsNavigationController()
        cloudNC.addChild(MockASCDocumentsViewController.get(folderId: "Baz1", providerId: "Baz"))
        cloudNC.addChild(MockASCDocumentsViewController.get(folderId: "Baz1/Baz1.1", providerId: "Baz"))
        cloudNC.addChild(MockASCDocumentsViewController.get(folderId: "Baz1/Baz1.1/Baz1.1.1", providerId: "Baz"))
        cloudNC.addChild(MockASCDocumentsViewController.get(folderId: "Baz1/Baz1.1/Baz1.1.1/Baz1.1.1.1", providerId: "Baz"))
        
        (tabbar.children[0] as! ASCDeviceSplitViewController).viewControllers = [UIViewController(), deviceNC]
        (tabbar.children[1] as! ASCOnlyofficeSplitViewController).viewControllers = [UIViewController(), onlyofficeNC]
        (tabbar.children[2] as! ASCCloudsSplitViewController).viewControllers = [UIViewController(), cloudNC]
        
        var response = sut.find(requestModel: .init(folderId: "Foo1/Foo1.1/Foo1.1.1", providerId: "Bar"))
        
        XCTAssertNil(response.viewController)
        
        response = sut.find(requestModel: .init(folderId: "Foo1/Foo1.1/Foo1.1.1", providerId: "Foo"))
        XCTAssertNotNil(response.viewController)
        XCTAssertEqual(response.viewController?.folder?.id, "Foo1/Foo1.1/Foo1.1.1")
        XCTAssertEqual(response.viewController?.provider?.id, "Foo")
        
        response = sut.find(requestModel: .init(folderId: "Bar1/Bar1.1", providerId: "Bar"))
        XCTAssertNotNil(response.viewController)
        XCTAssertEqual(response.viewController?.folder?.id, "Bar1/Bar1.1")
        XCTAssertEqual(response.viewController?.provider?.id, "Bar")
        
        response = sut.find(requestModel: .init(folderId: "Baz1/Baz1.1/Baz1.1.1/Baz1.1.1.1", providerId: "Baz"))
        XCTAssertNotNil(response.viewController)
        XCTAssertEqual(response.viewController?.folder?.id, "Baz1/Baz1.1/Baz1.1.1/Baz1.1.1.1")
        XCTAssertEqual(response.viewController?.provider?.id, "Baz")
        
        XCTAssertEqual(sut.getAllASCDocumentsNavigationControllers().count, 3)
        
    }
}

extension ASCLoadedViewControllerByProviderAndFolderFinderTests {
    class MockASCDocumentsViewController: ASCDocumentsViewController {
        var innerFolder: ASCFolder?
        var innerProvider: ASCFileProviderProtocol?
        
        override var folder: ASCFolder? {
            get { innerFolder }
            set { innerFolder = newValue }
        }
        override var provider: ASCFileProviderProtocol? {
            get { innerProvider }
            set { innerProvider = newValue }
        }
        
        static func get(folderId: String, providerId: String) -> MockASCDocumentsViewController {
            let documentsVC = MockASCDocumentsViewController()
            documentsVC.provider = MockFileProvider(id: providerId)
            documentsVC.folder = MockFolder(id: folderId)
            
            return documentsVC
        }
        
        init() {
            super.init(nibName: "", bundle: nil)
            UserDefaults.standard.addObserver(self, forKeyPath: ASCConstants.SettingsKeys.sortDocuments, options: [.new], context: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(updateFileInfo(_:)), name: ASCConstants.Notifications.updateFileInfo, object: nil)
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
    
    class MockFileProvider: ASCOnlyofficeProvider {
        let innerId: String
        override var id: String? {
            get {
                innerId
            }
        }
        
        init(id: String) {
            self.innerId = id
            super.init()
        }
    }
    
    class MockFolder: ASCFolder {
        convenience init(id: String) {
            self.init()
            self.id = id
        }
    }
}
