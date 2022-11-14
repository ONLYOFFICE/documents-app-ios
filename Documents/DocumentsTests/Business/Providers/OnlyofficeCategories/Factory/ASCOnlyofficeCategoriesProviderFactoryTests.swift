//
//  ASCOnlyofficeCategoriesProviderFactoryTests.swift
//  DocumentsTests
//
//  Created by Pavel Chernyshev on 9.09.2022.
//  Copyright © 2022 Ascensio System SIA. All rights reserved.
//
@testable import Documents
import XCTest

class ASCOnlyofficeCategoriesProviderFactoryTests: XCTestCase {
    var sut: ASCOnlyofficeCategoriesProviderFactory!

    override func setUpWithError() throws {
        sut = ASCOnlyofficeCategoriesProviderFactory()
    }

    override func tearDownWithError() throws {
        sut = nil
    }

    // MARK: - Categories provider test

    func testWhenServerVersionHasDocSpaceReturnsChainContainer() {
        sut.onlyofficeApiClientGetter = {
            let client = OnlyofficeApiClient()
            client.serverVersion = OnlyofficeVersion()
            client.serverVersion?.docSpace = "1"
            return client
        }

        let provider = sut.get()

        XCTAssertTrue(provider is ASCOnlyofficeCategoriesChainContainer)
    }

    func testWhenServerСommunityVersionGraterThen11and4ReturnsChainContainer() {
        sut.onlyofficeApiClientGetter = {
            let client = OnlyofficeApiClient()
            client.serverVersion = OnlyofficeVersion()
            client.serverVersion?.community = "11.5"
            return client
        }

        let provider = sut.get()

        XCTAssertTrue(provider is ASCOnlyofficeCategoriesChainContainer)
    }

    func testWhenServerСommunityVersionLessThen11and5ReturnsBaseCategoriesProvider() {
        sut.onlyofficeApiClientGetter = {
            let client = OnlyofficeApiClient()
            client.serverVersion = OnlyofficeVersion()
            client.serverVersion?.community = "11.4"
            return client
        }

        let provider = sut.get()

        XCTAssertTrue(provider is ASCOnlyofficeAppBasedCategoriesProvider)
    }

    func testWhenServerVersionIsNilReturnsBaseCategoriesProvider() {
        sut.onlyofficeApiClientGetter = { OnlyofficeApiClient() }

        let provider = sut.get()

        XCTAssertTrue(provider is ASCOnlyofficeAppBasedCategoriesProvider)
    }

    // MARK: - Grouper tests

    func testWhenHasDocSpaceVersionReturnsDocSpaceGrouper() {
        sut.onlyofficeApiClientGetter = {
            let client = OnlyofficeApiClient()
            client.serverVersion = OnlyofficeVersion()
            client.serverVersion?.docSpace = "1"
            return client
        }

        let grouper = sut.getCategoriesGrouper()

        XCTAssertTrue(grouper is ASCOnlyofficeDocSpaceCategoriesGroper)
    }

    func testWhenServerVersionIsNilReturnsDefaultGrouper() {
        sut.onlyofficeApiClientGetter = { OnlyofficeApiClient() }

        let grouper = sut.getCategoriesGrouper()

        XCTAssertTrue(grouper is ASCOnlyofficeCategoriesDefaultGrouper)
    }
}
