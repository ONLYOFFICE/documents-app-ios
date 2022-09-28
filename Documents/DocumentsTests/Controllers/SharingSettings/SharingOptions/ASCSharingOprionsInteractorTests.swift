//
//  ASCASCSharingOprionsInteractorTests.swift
//  DocumentsTests
//
//  Created by Павел Чернышев on 21.09.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import Alamofire
@testable import Documents
import ObjectMapper
import XCTest

class ASCSharingOprionsInteractorTests: XCTestCase {
    var sut: ASCSharingOptionsInteractor!
    var presenter: MockSharingOptionsPresentationLogic!
    var apiWorker: MockShareSettingsAPIWorker!
    var linkMaker: ASCEntityLinkMakerProtocol!
    var networkingRequestManager: NetworkingRequestingProtocol!

    override func setUpWithError() throws {
        presenter = MockSharingOptionsPresentationLogic()
        apiWorker = MockShareSettingsAPIWorker()
        linkMaker = MockLinkMaker()
        networkingRequestManager = MockNetworkRequesting()

        sut = ASCSharingOptionsInteractor(entityLinkMaker: linkMaker, entity: ASCFile(), apiWorker: apiWorker, networkingRequestManager: networkingRequestManager)
    }

    override func tearDownWithError() throws {
        presenter = nil
        apiWorker = nil
        linkMaker = nil
        networkingRequestManager = nil
    }

    func testChangingRightHolderAccessChengeDataStore() {
        let rightHolder = ASCSharingRightHolder(id: "Foo", type: .user, access: .read, isOwner: false)
        let user = ASCUser()
        user.userId = "Foo"

        sut.sharedInfoItems.append(.init(access: rightHolder.access, user: user))
        let expectation = expectation(description: "server expectation")
        sut.makeRequest(request: .changeRightHolderAccess(.init(entity: ASCFile(), rightHolder: rightHolder, access: .comment)))
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            XCTAssertEqual(self.sut.sharedInfoItems[0].access, .comment)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 4)
    }
}

extension ASCSharingOprionsInteractorTests {
    class MockSharingOptionsPresentationLogic: ASCSharingOptionsPresentationLogic {
        func presentData(response: ASCSharingOptions.Model.Response.ResponseType) {}
    }

    class MockShareSettingsAPIWorker: ASCShareSettingsAPIWorkerProtocol {
        func convertToParams(shareItems: [OnlyofficeShare]) -> [OnlyofficeShareItemRequestModel] {
            []
        }

        func convertToParams(items: [(rightHolderId: String, access: ASCShareAccess)]) -> [OnlyofficeShareItemRequestModel] {
            []
        }

        func convertToParams(entities: [ASCEntity]) -> [String: [String]]? {
            nil
        }

        func makeApiRequest(entity: ASCEntity) -> Endpoint<OnlyofficeResponseArray<OnlyofficeShare>>? {
            let file = ASCFile()
            file.id = "Foo"
            return Endpoint<OnlyofficeResponseArray<OnlyofficeShare>>(path: String(format: OnlyofficeAPI.Path.shareFile, file.id), decode: { _ in
                OnlyofficeResponseArray<OnlyofficeShare>()
            })
        }
    }

    class MockLinkMaker: ASCEntityLinkMakerProtocol {
        func make(entity: ASCEntity) -> String? {
            nil
        }
    }

    class MockNetworkRequesting: NetworkingRequestingProtocol {
        func request<Response>(_ endpoint: Endpoint<Response>, _ parameters: Parameters?, _ completion: ((Response?, NetworkingError?) -> Void)?) {
            completion?(nil, nil)
        }

        func request<Response>(_ endpoint: Endpoint<Response>, _ parameters: Parameters?, _ apply: ((MultipartFormData) -> Void)?, _ completion: ((Response?, Double, NetworkingError?) -> Void)?) {
            completion?(nil, 0, nil)
        }
    }
}
