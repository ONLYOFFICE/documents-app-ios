//
//  ASCEditorManager+DocumentEditorViewControllerDelegate.swift
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
        openMode: ASCDocumentOpenMode,
        documentPermissions: [String: Any]
    ) -> UIViewController? {
        let title = file.title
        let fileExt = title.fileExtension().lowercased()
        let isForm = ASCConstants.FileExtensions.forms.contains(fileExt)

        var documentPermissions = documentPermissions

        if !documentPermissions.keys.contains("fillForms") {
            documentPermissions["fillForms"] = isForm && allowForm && fileExt == ASCConstants.FileExtensions.oform
        }

        let configuration = EditorConfiguration(
            title: file.title,
            viewMode: openMode == .view || !UIDevice.allowEditor,
            newDocument: openMode == .create,
            date: file.updated ?? Date(),
            userId: UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString,
            userName: file.updatedBy?.displayName ?? (
                UIDevice.current.name.count > 0
                    ? UIDevice.current.name
                    : NSLocalizedString("Me", comment: "If current user name is not set")
            ),
//                "autosave": true,
//                "file": file.toJSONString()!,
            appFonts: editorFontsPaths,
            dataFontsPath: dataFontsPath,
            license: licensePath,
            documentPermissions: documentPermissions.jsonString() ?? ""
        )

//        configuration = localEditor(config: configuration)

        let document = EditorDocument(
            url: URL(fileURLWithPath: file.id),
            autosaveUrl: URL(fileURLWithPath: (Path.userAutosavedInformation + file.title).rawValue, isDirectory: true)
        )

        let editorViewController = DocumentEditorViewController(document: document, configuration: configuration)
        editorViewController.delegate = self

        return editorViewController
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
