//
//  ASCEditorManager+PresentationEditorViewControllerDelegate.swift
//  Documents
//
//  Created by Alexander Yuzhin on 13.06.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import FileKit
import PresentationEditor

extension PresentationEditor.EditorDocument: EditorDocumentProtocol {}

extension ASCEditorManager {
    var presentationEditorExternalSettings: [AnyHashable: Any] {
        [
            "asc.pe.external.appname": ASCConstants.Name.appNameShort,
            "asc.pe.external.helpurl": "https://helpcenter.onlyoffice.com/%@%@mobile-applications/documents/presentation-editor/index.aspx",
        ]
    }

    func createPresentationEditorViewController(
        for file: ASCFile,
        openMode: ASCDocumentOpenMode,
        documentPermissions: [String: Any]
    ) -> UIViewController? {
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

        let editorViewController = PresentationEditorViewController(document: document, configuration: configuration)
        editorViewController.delegate = self

        return editorViewController
    }
}

extension ASCEditorManager: PresentationEditorViewControllerDelegate {
    func presentationDidOpen(_ controller: PresentationEditor.PresentationEditorViewController, result: Result<PresentationEditor.EditorDocument, Error>) {
        switch result {
        case let .success(document):
            editorDocumentDidOpen(controller, result: .success(document))
        case let .failure(error):
            editorDocumentDidOpen(controller, result: .failure(error))
        }
    }

    func presentationDidClose(_ controller: PresentationEditor.PresentationEditorViewController, result: Result<PresentationEditor.EditorDocument, Error>) {
        switch result {
        case let .success(document):
            editorDocumentDidClose(controller, result: .success(document))
        case let .failure(error):
            editorDocumentDidClose(controller, result: .failure(error))
        }
    }

    func presentationDidExport(_ controller: PresentationEditor.PresentationEditorViewController, document: PresentationEditor.EditorDocument, result: Result<URL?, Error>) {
        editorDocumentDidExport(controller, document: document, result: result)
    }

    func presentationDidBackup(_ controller: PresentationEditor.PresentationEditorViewController, document: PresentationEditor.EditorDocument) {
        editorDocumentDidBackup(controller, document: document)
    }

    func presentationEditorSettings(_ controller: PresentationEditorViewController) -> [AnyHashable: Any] {
        return editorDocumentEditorSettings(controller)
    }

    func presentationFavorite(_ controller: PresentationEditor.PresentationEditorViewController, favorite: Bool, complation: @escaping ((Result<Bool, Error>) -> Void)) {
        editorDocumentFavorite(controller, favorite: favorite, complation: complation)
    }

    func presentationShare(_ controller: PresentationEditor.PresentationEditorViewController, complation: @escaping ((Result<Bool, Error>) -> Void)) {
        editorDocumentShare(controller, complation: complation)
    }

    func presentationRename(_ controller: PresentationEditor.PresentationEditorViewController, title: String, complation: @escaping ((Result<Bool, Error>) -> Void)) {
        editorDocumentRename(controller, title: title, complation: complation)
    }
}
