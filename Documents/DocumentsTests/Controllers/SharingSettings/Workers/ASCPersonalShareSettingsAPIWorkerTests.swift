//
//  ASCPersonalShareSettingsAPIWorkerTests.swift
//  DocumentsTests
//
//  Created by Павел Чернышев on 24.11.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import Foundation

import XCTest
@testable import Documents

class ASCPersonalShareSettingsAPIWorkerTests: XCTestCase {
    
    var sut: ASCPersonalShareSettingsAPIWorker!

    override func setUpWithError() throws {
        sut = ASCPersonalShareSettingsAPIWorker()
        try super.setUpWithError()
    }

    override func tearDownWithError() throws {
        sut = nil
        try super.tearDownWithError()
    }

    // MARK: - makeApiRequest func tests
    func testWhenMakeApiRequestOnFileGetsAString() {
        let file = ASCFile()
        file.id = "Foo"
        
        let request = sut.makeApiRequest(entity: file)
        
        XCTAssertNotNil(request)
        XCTAssertFalse(request?.path.contains(file.id) ?? true)
    }
    
    func testWhenMakeApiRequestOnFolderGetsAString() {
        let folder = ASCFolder()
        folder.id = "Foo"
        
        let request = sut.makeApiRequest(entity: folder)
        
        XCTAssertNotNil(request)
        XCTAssertFalse(request?.path.contains(folder.id) ?? true)
    }
    
    func testWhenMakeApiRequestOnEntityGetsAPIRequest() {
        let entity = ASCEntity()
        entity.id = "Foo"
        
        let request = sut.makeApiRequest(entity: entity)
        
        XCTAssertNotNil(request)
    }

    // MARK: - convertToParams func test
    
    func testWhenCallWithOneFileThenParamsHaveFileIdOnly() {
        let file = getFileWithId(id: "Foo")
        guard let params = sut.convertToParams(entities: [file]) else {
            XCTFail("Couldn't get params from file")
            return
        }
        
        XCTAssertEqual(params.count, 1)
        XCTAssertEqual(params["fileIds"], ["Foo"])
    }
    
    func testWhenCallWithOneFolderThenParamsHaveFolderIdOnly() {
        let folder = getFolderWithId(id: "Bar")
        guard let params = sut.convertToParams(entities: [folder]) else {
            XCTFail("Couldn't get params from file")
            return
        }
        
        XCTAssertEqual(params.count, 1)
        XCTAssertEqual(params["folderIds"], ["Bar"])
    }
    
    func testWhenCallWithTwoFilesAndThreeFoldersThenParamsHaveTwoFileIdsAndThreeFolderIds() {
        let file1 = getFileWithId(id: "Foo1")
        let file2 = getFileWithId(id: "Foo2")
        let folder1 = getFolderWithId(id: "Bar1")
        let folder2 = getFolderWithId(id: "Bar2")
        let folder3 = getFolderWithId(id: "Bar3")
        
        guard let params = sut.convertToParams(entities: [file1, folder1, folder2, file2, folder3]) else {
            XCTFail("Couldn't get params from file")
            return
        }
        
        XCTAssertEqual(params.count, 2)
        
        XCTAssertEqual(params["fileIds"], ["Foo1", "Foo2"])
        XCTAssertEqual(params["folderIds"], ["Bar1", "Bar2", "Bar3"])
    }
    
    func testWhenCallWithoutParamsConverterReturnsNil() {
        let params = sut.convertToParams(entities: [])
        XCTAssertNil(params)
    }
    
    func testWhenCallWithASCEntitryConverterReturnsNil() {
        let entity = ASCEntity()
        entity.id = "Foo"
        let params = sut.convertToParams(entities: [entity])
        XCTAssertNil(params)
    }
    
    // MARK: - help functions
    
    func getFileWithId(id: String) -> ASCFile {
        let file = ASCFile()
        file.id = id
        return file
    }
    
    func getFolderWithId(id: String) -> ASCFolder {
        let folder = ASCFolder()
        folder.id = id
        return folder
    }
}
