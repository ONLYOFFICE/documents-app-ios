//
//  ASCEditorManager+DocumentEditor.swift
//  Documents-develop
//
//  Created by Alexander Yuzhin on 26.04.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import DocumentEditor
import FileKit

extension DocumentEditor.EditorDocument: EditorDocumentProtocol {}

extension ASCEditorManager {
    var documentEditorExternalSettings: [AnyHashable: Any] {
        [
            "asc.de.external.appname": ASCConstants.Name.appNameShort,
            "asc.de.external.helpurl": "https://helpcenter.onlyoffice.com/%@%@mobile-applications/documents/document-editor/index.aspx",
            "asc.de.external.page.formats": [
                [
                    "description": "A6",
                    "size": "10.5 x 14.8",
                    "value": [105, 148], // 105 × 148
                ], [
                    "description": "A2",
                    "size": "42 x 59.4",
                    "value": [420, 594], // 420 × 594
                ], [
                    "description": "A1",
                    "size": "59.4 x 84.1",
                    "value": [594, 841], // 594 × 841
                ], [
                    "description": "A0",
                    "size": "84.1 x 118.9",
                    "value": [841, 1189], // 841 × 1189
                ],
            ],
        ]
    }

    func createDocumentEditorViewController(
        for file: ASCFile,
        config: OnlyofficeDocumentConfig,
        openMode: ASCDocumentOpenMode
    ) -> UIViewController? {
        let title = file.title
        let fileExt = title.fileExtension().lowercased()
        let isForm = ASCConstants.FileExtensions.forms.contains(fileExt)
        var documentPermissions = config.document?.permissions.dictionary ?? [:]

        if !documentPermissions.keys.contains("fillForms") {
            documentPermissions["fillForms"] = isForm && allowForm && fileExt == ASCConstants.FileExtensions.oform
        }

        let isCoauthoring = !(config.document?.key?.isEmpty ?? true) && !(config.document?.url?.isEmpty ?? true)
        let sdkCheck = compareCloudSdk(with: DocumentEditorViewController.sdkVersionString)

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
            documentPermissions: documentPermissions.jsonString() ?? "",
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

        let editorViewController = DocumentEditorViewController(document: document, configuration: configuration)
        editorViewController.delegate = self

        return editorViewController
    }
}

// MARK: - Methods

extension ASCEditorManager {
    func localEditor(config: EditorConfiguration) -> EditorConfiguration {
        return config
    }

    func cloudEditor(config: EditorConfiguration) -> EditorConfiguration {
        return config
    }
}

extension ASCEditorManager: DocumentEditorViewControllerDelegate {
    func documentDidOpen(_ controller: DocumentEditor.DocumentEditorViewController, result: Result<DocumentEditor.EditorDocument, Error>) {
        switch result {
        case let .success(document):
            editorDocumentDidOpen(controller, result: .success(document))
        case let .failure(error):
            editorDocumentDidOpen(controller, result: .failure(error))
        }
    }

    func documentDidClose(_ controller: DocumentEditor.DocumentEditorViewController, result: Result<DocumentEditor.EditorDocument, Error>) {
        switch result {
        case let .success(document):
            editorDocumentDidClose(controller, result: .success(document))
        case let .failure(error):
            editorDocumentDidClose(controller, result: .failure(error))
        }
    }

    func documentDidExport(_ controller: DocumentEditor.DocumentEditorViewController, document: DocumentEditor.EditorDocument, result: Result<URL?, Error>) {
        editorDocumentDidExport(controller, document: document, result: result)
    }

    func documentDidBackup(_ controller: DocumentEditor.DocumentEditorViewController, document: DocumentEditor.EditorDocument) {
        editorDocumentDidBackup(controller, document: document)
    }

    func documentEditorSettings(_ controller: DocumentEditor.DocumentEditorViewController) -> [AnyHashable: Any] {
        return editorDocumentEditorSettings(controller)
    }

    func documentFavorite(_ controller: DocumentEditor.DocumentEditorViewController, favorite: Bool, complation: @escaping ((Result<Bool, Error>) -> Void)) {
        editorDocumentFavorite(controller, favorite: favorite, complation: complation)
    }

    func documentShare(_ controller: DocumentEditor.DocumentEditorViewController, complation: @escaping ((Result<Bool, Error>) -> Void)) {
        editorDocumentShare(controller, complation: complation)
    }

    func documentRename(_ controller: DocumentEditor.DocumentEditorViewController, title: String, complation: @escaping ((Result<Bool, Error>) -> Void)) {
        editorDocumentRename(controller, title: title, complation: complation)
    }
}
