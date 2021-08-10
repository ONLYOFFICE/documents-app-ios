//
//  ASCLoadedViewControllerFinderProtocolTests.swift
//  DocumentsTests
//
//  Created by Pavel Chernyshevon 28.05.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import XCTest
import UIKit
@testable import Documents

class ASCLoadedViewControllerFinderProtocolTests: XCTestCase {
    
    var sut: ASCLoadedViewControllerFinderProtocol!

    override func setUpWithError() throws {
        sut = MockASCLoadedViewControllerFinderProtocol()
    }

    override func tearDownWithError() throws {
        sut = nil
    }

    func testSetRootVCWhenGetRootVCWeGetTheSameRootVC() {
        let vc = ASCRootController()
        
        UIApplication.shared.windows.first?.rootViewController = vc
    
        let gettedRootVC = sut.getRootViewController()
        
        XCTAssertNotNil(gettedRootVC)
        XCTAssertTrue(gettedRootVC === vc)
    }

    class MockASCLoadedViewControllerFinderProtocol: ASCLoadedViewControllerFinderProtocol {
        func find(requestModel: ASCLoadedVCFinderModels.DocumentsVC.Request) -> ASCLoadedVCFinderModels.DocumentsVC.Response {
            ASCLoadedVCFinderModels.DocumentsVC.Response(viewController: nil)
        }
    }
}
