//
//  ASCEditorManager+SpreadsheetEditorViewControllerDelegate.swift
//  Documents
//
//  Created by Alexander Yuzhin on 13.06.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import FileKit
import SpreadsheetEditor

extension SpreadsheetEditor.EditorDocument: EditorDocumentProtocol {}

extension ASCEditorManager {
    var spreadsheetEditorExternalSettings: [AnyHashable: Any] {
        let shortCm = NSLocalizedString("cm", comment: "Cut from centimeters")
        return [
            "asc.se.external.appname": ASCConstants.Name.appNameShort,
            "asc.se.external.helpurl": "https://helpcenter.onlyoffice.com/%@%@mobile-applications/documents/spreadsheet-editor/index.aspx",
            "asc.se.external.page.formats": [
                [
                    "width": 105,
                    "height": 148,
                    "display": String(format: NSLocalizedString("A6 (10,5%@ x 14,8%@)", comment: "Format info"), shortCm, shortCm),
                ], [
                    "width": 420,
                    "height": 594,
                    "display": String(format: NSLocalizedString("A2 (42%@ x 59,4%@)", comment: "Format info"), shortCm, shortCm),
                ], [
                    "width": 594,
                    "height": 841,
                    "display": String(format: NSLocalizedString("A1 (59,4%@ x 84,1%@)", comment: "Format info"), shortCm, shortCm),
                ], [
                    "width": 841,
                    "height": 1189,
                    "display": String(format: NSLocalizedString("A0 (84,1%@ x 119,9%@)", comment: "Format info"), shortCm, shortCm),
                ],
            ],
        ]
    }

    func createSpreadsheetEditorViewController(
        for file: ASCFile,
        config: OnlyofficeDocumentConfig,
        openMode: ASCDocumentOpenMode
    ) -> UIViewController? {
        let title = file.title
        let isCoauthoring = !(config.document?.key?.isEmpty ?? true) && !(config.document?.url?.isEmpty ?? true)
        let sdkCheck = compareCloudSdk(with: SpreadsheetEditorViewController.sdkVersionString)

        var editorUser = EditorUserConfiguration(
            id: UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString,
            displayName: file.updatedBy?.displayName ?? (
                UIDevice.current.name.count > 0
                    ? UIDevice.current.name
                    : NSLocalizedString("Me", comment: "If current user name is not set")
            )
        )

        if isCoauthoring, let onlyofficeUser = ASCFileManager.onlyofficeProvider?.user {
            editorUser = EditorUserConfiguration(
                id: onlyofficeUser.userId,
                firstName: onlyofficeUser.firstName,
                lastName: onlyofficeUser.lastName,
                displayName: onlyofficeUser.userName ?? file.createdBy?.displayName
            )
        }

        var configuration = EditorConfiguration(
            title: file.title,
            viewMode: openMode == .view || !UIDevice.allowEditor || (isCoauthoring && !sdkCheck),
            newDocument: openMode == .create,
            coauthoring: isCoauthoring,
            docKey: config.document?.key,
            docURL: config.document?.url,
            docService: documentServiceURL ?? "",
            documentToken: config.token,
            sdkCheck: sdkCheck,
            date: file.updated ?? Date(),
            user: editorUser,
            appFonts: editorFontsPaths,
            dataFontsPath: dataFontsPath,
            license: licensePath,
            documentPermissions: config.document?.permissions?.dictionary?.jsonString() ?? "",
            documentCommonConfig: config.dictionary?.jsonString() ?? ""
        )

        if isCoauthoring {
            let protalType = ASCPortalTypeDefinderByCurrentConnection().definePortalType()

            configuration.supportShare = file.access == .readWrite || file.access == .none

            /// Enabling the Favorite function only on portals version 11 and higher
            /// and not DocSpace
            if let communityServerVersion = OnlyofficeApiClient.shared.serverVersion?.community,
               communityServerVersion.isVersion(greaterThanOrEqualTo: "11.0"),
               let user = ASCFileManager.onlyofficeProvider?.user,
               protalType != .docSpace
            {
                configuration.favorite = file.isFavorite && !user.isVisitor
                configuration.denyDownload = file.denyDownload
            }

            /// Turn off share from editors for the DocSpace
            if protalType == .docSpace {
                configuration.supportShare = false
            }

            configuration = cloudEditor(config: configuration)
        } else {
            configuration = localEditor(config: configuration)
        }

        let document = EditorDocument(
            url: isCoauthoring ? URL(string: config.document?.url ?? file.id)! : URL(fileURLWithPath: file.id),
            autosaveUrl: URL(fileURLWithPath: (Path.userAutosavedInformation + file.title).rawValue, isDirectory: true)
        )

        let editorViewController = SpreadsheetEditorViewController(document: document, configuration: configuration)
        editorViewController.delegate = self

        return editorViewController
    }
}

extension ASCEditorManager {
    func localEditor(config: EditorConfiguration) -> EditorConfiguration {
        return config
    }

    func cloudEditor(config: EditorConfiguration) -> EditorConfiguration {
        return config
    }
}

extension ASCEditorManager: SpreadsheetEditorViewControllerDelegate {
    func spreadsheetDidOpen(_ controller: SpreadsheetEditor.SpreadsheetEditorViewController, result: Result<SpreadsheetEditor.EditorDocument, Error>) {
        switch result {
        case let .success(document):
            editorDocumentDidOpen(controller, result: .success(document))
        case let .failure(error):
            editorDocumentDidOpen(controller, result: .failure(error))
        }
    }

    func spreadsheetDidClose(_ controller: SpreadsheetEditor.SpreadsheetEditorViewController, result: Result<SpreadsheetEditor.EditorDocument, Error>) {
        switch result {
        case let .success(document):
            editorDocumentDidClose(controller, result: .success(document))
        case let .failure(error):
            editorDocumentDidClose(controller, result: .failure(error))
        }
    }

    func spreadsheetDidExport(_ controller: SpreadsheetEditor.SpreadsheetEditorViewController, document: SpreadsheetEditor.EditorDocument, result: Result<URL?, Error>) {
        editorDocumentDidExport(controller, document: document, result: result)
    }

    func spreadsheetDidBackup(_ controller: SpreadsheetEditor.SpreadsheetEditorViewController, document: SpreadsheetEditor.EditorDocument) {
        editorDocumentDidBackup(controller, document: document)
    }

    func spreadsheetEditorSettings(_ controller: SpreadsheetEditor.SpreadsheetEditorViewController) -> [AnyHashable: Any] {
        return editorDocumentEditorSettings(controller)
    }

    func spreadsheetFavorite(_ controller: SpreadsheetEditor.SpreadsheetEditorViewController, favorite: Bool, complation: @escaping ((Result<Bool, Error>) -> Void)) {
        editorDocumentFavorite(controller, favorite: favorite, complation: complation)
    }

    func spreadsheetShare(_ controller: SpreadsheetEditor.SpreadsheetEditorViewController, complation: @escaping ((Result<Bool, Error>) -> Void)) {
        editorDocumentShare(controller, complation: complation)
    }

    func spreadsheetRename(_ controller: SpreadsheetEditor.SpreadsheetEditorViewController, title: String, complation: @escaping ((Result<Bool, Error>) -> Void)) {
        editorDocumentRename(controller, title: title, complation: complation)
    }

    func spreadsheetChartData(_ controller: SpreadsheetEditor.SpreadsheetEditorViewController, data: Data?) {
        //
    }
}
