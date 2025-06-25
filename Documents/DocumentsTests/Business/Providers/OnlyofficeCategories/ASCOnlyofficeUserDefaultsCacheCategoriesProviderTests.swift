//
//  ASCOnlyofficeUserDefaultsCacheCategoriesProviderTests.swift
//  DocumentsTests
//
//  Created by Pavel Chernyshev on 21.05.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

@testable import Documents
import UIKit
import XCTest

class ASCOnlyofficeUserDefaultsCacheCategoriesProviderTests: XCTestCase {
    var sut: ASCOnlyofficeUserDefaultsCacheCategoriesProvider!
    var categoryFoo: ASCOnlyofficeCategory!
    var account: ASCAccount!

    let email = "foo@bar.com"
    let portal = "https://portal.com"

    override func setUp() {
        sut = ASCOnlyofficeUserDefaultsCacheCategoriesProviderMock()

        categoryFoo = ASCOnlyofficeCategory()
        categoryFoo.title = "Foo"
        categoryFoo.subtitle = "foo"
        let folder = ASCFolder()
        folder.id = "@my"
        folder.rootFolderType = .user
        folder.title = "Foo"
        categoryFoo.folder = folder

        account = ASCAccount(JSON: ["email": email, "portal": portal])
        super.setUp()
    }

    override func tearDown() {
        UserDefaults.standard.set("", forKey: sut.getKey(for: account)!)
        sut = nil
        categoryFoo = nil
        account = nil

        super.tearDown()
    }

    func testKeyIsNotEmpty() {
        guard let key = sut.getKey(for: account) else {
            XCTFail("key is nil")
            return
        }
        XCTAssertEqual(key, "\(ASCConstants.CacheKeys.onlyofficeCategoriesPrefix)_\(email)_\(portal)_tests")
    }

    func testAccountEmailAndPortalIsNotEmpty() {
        XCTAssertEqual(account?.email, email)
        XCTAssertEqual(account?.portal, portal)
    }

    func testWhenSaveCategoryGetTheSameCategory() {
        let error = sut.save(for: account, categories: [categoryFoo])

        XCTAssertNil(error)

        XCTAssertEqual(sut.getCategories(for: account!), [categoryFoo])
    }

    func testWhenSaveCategoryAndEqualingWithAnotherThanFail() {
        let error = sut.save(for: account, categories: [categoryFoo])

        XCTAssertNil(error)

        let categoryBar = ASCOnlyofficeCategory()
        categoryBar.title = "Bar"
        categoryBar.subtitle = "bar"

        XCTAssertNotEqual(sut.getCategories(for: account), [categoryBar])
    }

    func testWhenAddTwoCategoriesAngGetTheSameCategories() {
        let categoryBar = ASCOnlyofficeCategory()
        categoryBar.title = "Bar"
        categoryBar.subtitle = "bar"

        let error = sut.save(for: account, categories: [categoryFoo, categoryBar])

        XCTAssertNil(error)

        let cachedCategories = sut.getCategories(for: account)

        XCTAssertEqual(cachedCategories, [categoryFoo, categoryBar])
    }

    func testWhenSaveCategoriesAndCleacCasheThenCachedEmpty() {
        let error = sut.save(for: account, categories: [categoryFoo])

        XCTAssertNil(error)

        XCTAssertEqual(sut.getCategories(for: account!), [categoryFoo])

        sut.clearCache()

        XCTAssertEqual(sut.getCategories(for: account!), [])
    }
}

extension ASCOnlyofficeUserDefaultsCacheCategoriesProviderTests {
    class ASCOnlyofficeUserDefaultsCacheCategoriesProviderMock: ASCOnlyofficeUserDefaultsCacheCategoriesProvider {
        override func getKey(for account: ASCAccount) -> String? {
            guard let key = super.getKey(for: account) else {
                return nil
            }
            return "\(key)_tests"
        }
    }
}
