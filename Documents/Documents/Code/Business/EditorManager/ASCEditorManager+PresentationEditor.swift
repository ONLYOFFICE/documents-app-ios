//
//  ASCEditorManager+PresentationEditor.swift
//  Documents
//
//  Created by Alexander Yuzhin on 13.06.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import FileKit
import PresentationEditor

extension PresentationEditor.EditorDocument: EditorDocumentProtocol {}
extension PresentationEditor.DocumentConverterError: DocumentConverterErrorProtocol {
    var identifier: String { localizedDescription }
}

extension ASCEditorManager {
    var presentationEditorExternalSettings: [AnyHashable: Any] {
        ASCDIContainer.shared.resolve(type: ASCPresentationEditorConfigurationProtocol.self)?.editorExternalSettings ?? [:]
    }

    func createPresentationEditorViewController(
        for file: ASCFile,
        config: OnlyofficeDocumentConfig,
        openMode: ASCDocumentOpenMode
    ) -> UIViewController? {
        let isCoauthoring = !(config.document?.key?.isEmpty ?? true) && !(config.document?.url?.isEmpty ?? true)
        let sdkCheck = compareCloudSdk(with: PresentationEditorViewController.sdkVersionString)

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
            openMode: EditorOpenMode(rawValue: openMode.rawValue),
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

            configuration = cloudEditor(config: configuration, file: file, provider: ASCFileManager.onlyofficeProvider)
        } else {
            configuration = localEditor(config: configuration, file: file, provider: nil)
        }

        let document = EditorDocument(
            url: isCoauthoring ? URL(string: config.document?.url ?? file.id)! : URL(fileURLWithPath: file.id),
            autosaveUrl: URL(fileURLWithPath: (Path.userAutosavedInformation + file.title).rawValue, isDirectory: true)
        )

        let editorViewController = PresentationEditorViewController(document: document, configuration: configuration)
        editorViewController.delegate = self

        return editorViewController
    }
}

extension ASCEditorManager {
    func localEditor(
        config: EditorConfiguration,
        file: ASCFile?,
        provider: ASCFileProviderProtocol?
    ) -> EditorConfiguration {
        ASCDIContainer.shared.resolve(type: ASCPresentationEditorConfigurationProtocol.self)?
            .localEditor(config: config, file: file, provider: provider) ?? EditorConfiguration()
    }

    func cloudEditor(
        config: EditorConfiguration,
        file: ASCFile?,
        provider: ASCFileProviderProtocol?
    ) -> EditorConfiguration {
        ASCDIContainer.shared.resolve(type: ASCPresentationEditorConfigurationProtocol.self)?
            .cloudEditor(config: config, file: file, provider: provider) ?? EditorConfiguration()
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

    func presentationFetchAvatars(_ controller: PresentationEditor.PresentationEditorViewController, usersId: [String], completion: @escaping ([String: UIImage]) -> Void) {
        Task {
            await MainActor.run {
                editorFetchAvatars(for: usersId, completion: completion)
            }
        }
    }

    @MainActor
    func presentationFetchSharedUsers() async -> [[String: Any]] {
        await fetchSharedUsers()
    }

    func presentationEditorNotify(notificationInfo: [String: Any]) {
        sendEditorNotify(notificationInfo: notificationInfo)
    }
}
