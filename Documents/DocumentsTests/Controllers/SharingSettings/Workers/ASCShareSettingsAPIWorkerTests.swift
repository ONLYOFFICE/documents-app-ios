//
//  ASCShareSettingsAPIWorker.swift
//  DocumentsTests
//
//  Created by Павел Чернышев on 19.07.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import XCTest
@testable import Documents

class ASCShareSettingsAPIWorkerTests: XCTestCase {
    
    var sut: ASCShareSettingsAPIWorker!

    override func setUpWithError() throws {
        sut = ASCShareSettingsAPIWorker()
    }

    override func tearDownWithError() throws {
        sut = nil
    }

    // MARK: - makeApiRequest func tests
    func testWhenMakeApiRequestOnFileGetsAString() {
        let file = ASCFile()
        file.id = "Foo"
        
        let request = sut.makeApiRequest(entity: file)
        
        XCTAssertNotNil(request)
        XCTAssertTrue(request?.contains(file.id) ?? false)
    }
    
    func testWhenMakeApiRequestOnFolderGetsAString() {
        let folder = ASCFolder()
        folder.id = "Foo"
        
        let request = sut.makeApiRequest(entity: folder)
        
        XCTAssertNotNil(request)
        XCTAssertTrue(request?.contains(folder.id) ?? false)
    }
    
    func testWhenMakeApiRequestOnEntityGetsNothing() {
        let entity = ASCEntity()
        entity.id = "Foo"
        
        let request = sut.makeApiRequest(entity: entity)
        
        XCTAssertNil(request)
    }

    // MARK: - convertToParams(shareItems: [ASCShareInfo]) func tests
    func testConvertShareUserInfoToParams() {
        let id = "Foo"
        let access: ASCShareAccess = .read
        let shareInfo = makeUserShareInfo(withId: id, andAceess: access)
        
        let expected: [String: Any] = [
            "share[0].ShareTo": id,
            "share[0].Access": access.rawValue
        ]
        
        let result = sut.convertToParams(shareItems: [shareInfo])
        
        XCTAssertNotNil(result["share[0].ShareTo"])
        XCTAssertTrue(result["share[0].ShareTo"] as? String? == expected["share[0].ShareTo"] as? String)
        XCTAssertNotNil(result["share[0].Access"])
        XCTAssertTrue(result["share[0].Access"] as? Int? == expected["share[0].Access"] as? Int)
    }
    
    
    func testConvertShareUserInfoWithShreFolderIngoToParams() {
        let userId = "Foo"
        let userAccess: ASCShareAccess = .read
        let userShareInfo = makeUserShareInfo(withId: userId, andAceess: userAccess)
        
        let folderId = "Boo"
        let folderAccess: ASCShareAccess = .comment
        let folderShareInfo = makeUserShareInfo(withId: folderId, andAceess: folderAccess)
        
        let expected: [String: Any] = [
            "share[0].ShareTo": userId,
            "share[0].Access": userAccess.rawValue,
            "share[1].ShareTo": folderId,
            "share[1].Access": folderAccess.rawValue
        ]
        
        let result = sut.convertToParams(shareItems: [userShareInfo, folderShareInfo])
        
        XCTAssertNotNil(result["share[0].ShareTo"])
        XCTAssertNotNil(result["share[0].Access"])
        
        XCTAssertTrue(result["share[0].ShareTo"] as? String? == expected["share[0].ShareTo"] as? String)
        XCTAssertTrue(result["share[0].Access"] as? Int? == expected["share[0].Access"] as? Int)
        
        XCTAssertNotNil(result["share[1].ShareTo"])
        XCTAssertNotNil(result["share[1].Access"])
        
        XCTAssertTrue(result["share[1].ShareTo"] as? String? == expected["share[1].ShareTo"] as? String)
        XCTAssertTrue(result["share[1].Access"] as? Int? == expected["share[1].Access"] as? Int)
    }
    
    func testConvertShareInfoWithouUserAndGroupToParamsReturnsEmpty() {
        let shareInfo = ASCShareInfo()
        
        let result = sut.convertToParams(shareItems: [shareInfo])
        
        XCTAssertTrue(result.count == 0)
    }
    
    // MARK: - converToParams(items: [(rightHolderId: String, access: ASCShareAccess)]) func tests
    func testConvertItemsFooAndBarToParams() {

        let foo: (rightHolderId: String, access: ASCShareAccess) = ("Foo", ASCShareAccess.read)
        let bar: (rightHolderId: String, access: ASCShareAccess) = ("Bar", ASCShareAccess.deny)
        
        let expected: [String: Any] = [
            "share[0].ShareTo": foo.rightHolderId,
            "share[0].Access": foo.access.rawValue,
            "share[1].ShareTo": bar.rightHolderId,
            "share[1].Access": bar.access.rawValue
        ]
        
        let result = sut.convertToParams(items: [foo, bar])
        
        XCTAssertNotNil(result["share[0].ShareTo"])
        XCTAssertNotNil(result["share[0].Access"])
        
        XCTAssertTrue(result["share[0].ShareTo"] as? String? == expected["share[0].ShareTo"] as? String)
        XCTAssertTrue(result["share[0].Access"] as? Int? == expected["share[0].Access"] as? Int)
        
        XCTAssertNotNil(result["share[1].ShareTo"])
        XCTAssertNotNil(result["share[1].Access"])
        
        XCTAssertTrue(result["share[1].ShareTo"] as? String? == expected["share[1].ShareTo"] as? String)
        XCTAssertTrue(result["share[1].Access"] as? Int? == expected["share[1].Access"] as? Int)
    }
    
    // MARK: - Help functions
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
