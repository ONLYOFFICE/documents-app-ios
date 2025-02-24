//
//  ASCSharingSettingsAccessProviderFactory.swift
//  Documents
//
//  Created by Pavel Chernyshev on 07.07.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import Foundation

class ASCSharingSettingsAccessProviderFactory {
    typealias FileExtension = String
    typealias ProviderContainer = () -> ASCSharingSettingsAccessProvider
    
    private let isDocspaceProvider: () -> Bool
    private var isDocspace: Bool { isDocspaceProvider() }

    private lazy var providerContainersByExtension: [FileExtension: ProviderContainer] = [
        ASCConstants.FileExtensions.docx: docsAccessListProvider(),
        ASCConstants.FileExtensions.docxf: docsfAccessListProvider(),
        ASCConstants.FileExtensions.xlsx: xlsxAccessListProvider(),
        ASCConstants.FileExtensions.pptx: pptxAccessListProvider(),
        ASCConstants.FileExtensions.oform: oformAccessListProvider(),
        ASCConstants.FileExtensions.pdf: pdfAccessListProvider(),
    ]
    
    init(
        isDocspaceProvider: @escaping () -> Bool = {
            OnlyofficeApiClient.shared.serverVersion?.docSpace != nil
        }
    ) {
        self.isDocspaceProvider = isDocspaceProvider
    }

    func get(
        entity: ASCEntity,
        isAccessExternal: Bool,
        rightHoldersTableType: RightHoldersTableType? = nil
    ) -> ASCSharingSettingsAccessProvider {
        if let file = entity as? ASCFile,
           let porviderContainer = providerContainersByExtension[file.title.fileExtension()]
        {
            return porviderContainer()
        }

        guard let folder = entity as? ASCFolder, let roomType = folder.roomType else {
            return isAccessExternal
                ? ASCSharingSettingsAccessExternalDefaultProvider()
                : ASCSharingSettingsAccessDefaultProvider()
        }

        if isAccessExternal {
            return ASCSharingSettingsExternalLinkAccessRoomsProvider(
                roomType: roomType,
                rightHoldersTableType: rightHoldersTableType
            )
        } else {
            return ASCSharingSettingsAccessRoomsProvider(
                roomType: roomType,
                rightHoldersTableType: rightHoldersTableType
            )
        }
    }
}

private extension ASCSharingSettingsAccessProviderFactory {
    
    func docsAccessListProvider() -> ProviderContainer {
        isDocspace
        ? { ASCDocSpaceAccessDocumentProvider() }
        : { ASCSharingSettingsAccessDocumentProvider() }
    }
    
    func docsfAccessListProvider() -> ProviderContainer {
        isDocspace
        ? { ASCDocSpaceAccessDocumentFormProvider() }
        : { ASCSharingSettingsAccessDocumentFormProvider() }
    }
    
    func xlsxAccessListProvider() -> ProviderContainer {
        isDocspace
        ? { ASCDocSpaceAccessTableProvider() }
        : { ASCSharingSettingsAccessTableProvider() }
    }
    
    func pptxAccessListProvider() -> ProviderContainer {
        isDocspace
        ? { ASCDocSpaceAccessPresentationProvider() }
        : { ASCSharingSettingsAccessPresentationProvider() }
    }
    
    func oformAccessListProvider() -> ProviderContainer {
        isDocspace
        ? { ASCDocSpaceAccessOFormProvider() }
        : { ASCSharingSettingsAccessOFormProvider() }
    }
    
    func pdfAccessListProvider() -> ProviderContainer {
        isDocspace
        ? { ASCDocSpaceAccessOFormProvider() }
        : { ASCSharingSettingsAccessOFormProvider() }
    }
}
