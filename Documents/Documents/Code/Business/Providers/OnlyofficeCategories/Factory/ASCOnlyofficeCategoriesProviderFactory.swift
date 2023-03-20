//
//  ASCOnlyofficeCategoriesProviderFactory.swift
//  Documents
//
//  Created by Pavel Chernyshev on 22.04.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import Foundation

protocol ASCOnlyofficeCategoriesProviderFactoryProtocol {
    func get() -> ASCOnlyofficeCategoriesProviderProtocol
    func getCategoriesGrouper() -> ASCOnlyofficeCategoriesGrouper
}

private protocol CategoriesProviderMaker {
    func make() -> ASCOnlyofficeCategoriesProviderProtocol?
}

class ASCOnlyofficeCategoriesProviderFactory {
    var onlyofficeApiClientGetter: () -> OnlyofficeApiClient = {
        OnlyofficeApiClient.shared
    }

    // MARK: - private vars

    private lazy var categoriesProvidersMakers: [() -> ASCOnlyofficeCategoriesProviderProtocol?] = [
        makeDocSpaceCategoriesProvider,
        makeCommuntityCategoriesProvider,
    ]

    // MARK: - private funcs

    private func getFirstMakedCategoriesProvider() -> ASCOnlyofficeCategoriesProviderProtocol? {
        for maker in categoriesProvidersMakers {
            if let provider = maker() {
                return provider
            }
        }
        return nil
    }

    private func makeDocSpaceCategoriesProvider() -> ASCOnlyofficeCategoriesProviderProtocol? {
        guard onlyofficeApiClientGetter().serverVersion?.docSpace != nil else { return nil }

        return ASCOnlyofficeCategoriesProviderFilterProxy(
            categoriesProvider: ASCOnlyofficeAPICategoriesProvider(),
            filter: {
                guard let folderType = $0.folder?.rootFolderType else { return false }
                return folderType != .unknown
            }
        )
    }

    private func makeCommuntityCategoriesProvider() -> ASCOnlyofficeCategoriesProviderProtocol? {
        guard let communityServerVersion = onlyofficeApiClientGetter().serverVersion?.community,
              communityServerVersion.isVersion(greaterThanOrEqualTo: "11.5")
        else { return nil }

        return ASCOnlyofficeCategoriesProviderFilterProxy(
            categoriesProvider: ASCOnlyofficeAPICategoriesProvider(),
            filter: {
                guard let folderType = $0.folder?.rootFolderType else { return false }
                return folderType != .unknown && !$0.isDocSpaceRoom
            }
        )
    }

    private func makeDefaultCategoriesProvider() -> ASCOnlyofficeCategoriesProviderProtocol {
        ASCOnlyofficeAppBasedCategoriesProvider()
    }

    private func makeSafeProvider(provider: ASCOnlyofficeCategoriesProviderProtocol) -> ASCOnlyofficeCategoriesProviderProtocol {
        ASCOnlyofficeCategoriesChainContainerFailureToNext(base: provider,
                                                           next: makeDefaultCategoriesProvider())
    }
}

// MARK: - ASCOnlyofficeCategoriesProviderFactoryProtocol

extension ASCOnlyofficeCategoriesProviderFactory: ASCOnlyofficeCategoriesProviderFactoryProtocol {
    func get() -> ASCOnlyofficeCategoriesProviderProtocol {
        guard let firstMakedProvider = getFirstMakedCategoriesProvider() else {
            return makeDefaultCategoriesProvider()
        }
        return makeSafeProvider(provider: firstMakedProvider)
    }

    func getCategoriesGrouper() -> ASCOnlyofficeCategoriesGrouper {
        if onlyofficeApiClientGetter().serverVersion?.docSpace != nil {
            return ASCOnlyofficeDocSpaceCategoriesGroper()
        }
        return ASCOnlyofficeCategoriesDefaultGrouper()
    }
}
