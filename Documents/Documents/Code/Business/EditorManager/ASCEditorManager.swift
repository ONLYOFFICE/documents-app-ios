//
//  ASCEditorManager.swift
//  Documents
//
//  Created by Alexander Yuzhin on 3/15/17.
//  Copyright © 2017 Ascensio System SIA. All rights reserved.
//

import DocumentConverter
import DocumentEditor
import FileKit
import Firebase
import MediaBrowser
import PresentationEditor
import SpreadsheetEditor
import UIKit

enum ASCEditorManagerStatus: String {
    case begin = "ASCEditorManagerStatusBegin"
    case progress = "ASCEditorManagerStatusProgress"
    case end = "ASCEditorManagerStatusEnd"
    case error = "ASCEditorManagerStatusError"
    case silentError = "ASCEditorManagerStatusErrorSilent"
}

class ASCEditorManagerError: LocalizedError, CustomStringConvertible, CustomNSError {
    private let msg: String
    private let type: ASCEditorManagerErrorType

    enum ASCEditorManagerErrorType: Int {
        case error = 0
        case warning = 1
    }

    static var errorDomain: String = "com.onlyoffice.error.ASCEditorManager"

    var errorCode: Int {
        return type.rawValue
    }

    init(msg: String, type: ASCEditorManagerErrorType = .error) {
        self.msg = msg
        self.type = type
    }

    var description: String {
        return msg
    }
}

typealias ASCEditorManagerOpenHandler = (_ status: ASCEditorManagerStatus, _ progress: Float, _ error: Error?, _ cancel: inout Bool) -> Void
typealias ASCEditorManagerCloseHandler = (_ status: ASCEditorManagerStatus, _ progress: Float, _ result: ASCFile?, _ error: Error?, _ cancel: inout Bool) -> Void
typealias ASCEditorManagerFavoriteHandler = (_ file: ASCFile?, _ complation: @escaping (Bool) -> Void) -> Void
typealias ASCEditorManagerRenameHandler = (_ file: ASCFile?, _ title: String, _ complation: @escaping (Bool) -> Void) -> Void
typealias ASCEditorManagerShareHandler = (_ file: ASCFile?) -> Void
typealias ASCEditorManagerLockedHandler = () -> Void
typealias ASCEditorManagerFillFormDidSendHandler = (_ file: ASCFile?, _ fillingSessionId: String?, _ complation: @escaping (Bool) -> Void) -> Void

class ASCEditorManager: NSObject {
    public static let shared = ASCEditorManager()

    /// The ASCEditorManager Configuration
    struct Configuration {
        var onlyofficeClient: OnlyofficeApiClient?
    }

    // MARK: - Private

    private var openedFile: ASCFile?
    private var provider: ASCFileProviderProtocol?
    private var closeHandler: ASCEditorManagerCloseHandler?
    private var openHandler: ASCEditorManagerOpenHandler?
    private var favoriteHandler: ASCEditorManagerFavoriteHandler?
    private var shareHandler: ASCEditorManagerShareHandler?
    private var renameHandler: ASCEditorManagerRenameHandler?
    private var fillFormDidSendHandler: ASCEditorManagerFillFormDidSendHandler?
    private var documentInteractionController: UIDocumentInteractionController?
    var documentServiceURL: String?
    private var documentKeyForTrack: String?
    private var documentURLForTrack: String?
    private var documentToken: String?
    private var documentCommonConfig: String?
    private var documentFillingSessionId: String?
    private var editorWindow: UIWindow?
    private let trackingReadyForLocking = 10000
    private var timer: Timer?
    private var trackingFileStatus: Int = 0
    private var lockedHandler: ASCEditorManagerLockedHandler?
    private var openedlocallyFile: ASCFile?
    private var openedCopy = false
    private var openedFilePassword = ""
    private var openedFileMode: ASCDocumentOpenMode = .edit
    private var encoding: Int?
    private var delimiter: Int?
    private var resolvedFilePath: Path!
    private var configuration: Configuration?
    private var apiClient: OnlyofficeApiClient {
        configuration?.onlyofficeClient ?? OnlyofficeApiClient.shared
    }

    private var documentServiceVersion: String?

    var allowForm: Bool {
        ASCDIContainer.shared.resolve(ASCEditorManagerOptionsProtocol.self)?.allowForm ?? false
    }

    var isOpenedFile: Bool {
        return openedFile != nil
    }

    lazy var editorFontsPaths: [String] = {
        var paths = [Bundle.main.resourcePath?.appendingPathComponent("fonts") ?? ""]

        if let appFontsFolder = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first {
            paths.insert(appFontsFolder.appendingPathComponent("Fonts").path, at: 0)
        }
        return paths
    }()

    lazy var dataFontsPath: String = {
        let paths = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)

        if let documentsDirectory = paths.first {
            let path = documentsDirectory + "/asc.editors.data.cache.fonts"

            do {
                try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: false, attributes: nil)
            } catch {}

            return path
        }

        return ""
    }()

    var licensePath: String {
        Bundle.main.url(
            forResource: ASCConstants.Keys.licenseName,
            withExtension: "lic"
        )?.path ?? ""
    }

    override required init() {
        super.init()

        // Localize Presentation Viewer
        _ = NSLocalizedString("End Slide Show", comment: "Presentation Viewer")
        _ = NSLocalizedString("%i of %i", comment: "Presentation Viewer")
        _ = NSLocalizedString("Slide %i of %i", comment: "Presentation Viewer")

        // Prepare to use custom fonts
        prepareFonts()
    }

    init(config: ASCEditorManager.Configuration) {
        super.init()
        configuration = config
    }

    private func createEditorWindow() -> UIWindow? {
        cleanupEditorWindow()

        editorWindow = UIWindow(frame: UIScreen.main.bounds)
        editorWindow?.rootViewController = UIViewController()

        if let delegate = UIApplication.shared.delegate {
            editorWindow?.tintColor = delegate.window??.tintColor
        }

        editorWindow?.windowLevel = UIWindow.Level.statusBar - 10

        if let topWindow = UIWindow.keyWindow {
            editorWindow?.windowLevel = min(topWindow.windowLevel + 1, UIWindow.Level.statusBar - 10)
        }

        editorWindow?.makeKeyAndVisible()

        return editorWindow
    }

    private func cleanupEditorWindow() {
        editorWindow?.isHidden = true
        editorWindow?.rootViewController = nil
        editorWindow?.removeFromSuperview()
        editorWindow = nil
    }

    private func clientRequest<Response>(
        _ endpoint: Endpoint<Response>,
        _ parameters: [String: Any]? = nil,
        _ completion: ((_ result: Response?, _ error: NetworkingError?) -> Void)? = nil
    ) {
        NetworkingClient.clearCookies(for: apiClient.url(path: endpoint.path))
        apiClient.request(endpoint, parameters, completion)
    }

    private func fetchDocumentInfo(_ file: ASCFile, openMode: ASCDocumentOpenMode = .edit) async -> Result<OnlyofficeDocumentConfig, Error> {
        await withCheckedContinuation { continuation in
            var params: [String: Any] = [:]

            let key: String? = {
                switch openMode {
                case .edit: return "edit"
                case .view: return "view"
                case .fillform: return "fill"
                default: return nil
                }
            }()

            if let key {
                params[key] = "true"
            }

            clientRequest(OnlyofficeAPI.Endpoints.Files.openEdit(file: file), params) { response, error in
                if let error {
                    continuation.resume(returning: .failure(error))
                    return
                }

                if let config = response?.result {
                    self.documentCommonConfig = config.dictionary?.jsonString()
                    self.documentKeyForTrack = config.document?.key
                    self.documentURLForTrack = config.document?.url
                    self.documentToken = config.token
                    self.documentFillingSessionId = config.fillingSessionId
                    if !(config.document?.key?.isEmpty ?? true), !(config.document?.url?.isEmpty ?? true) {
                        continuation.resume(returning: .success(config))
                        return
                    }
                }

                continuation.resume(
                    returning: .failure(
                        ASCEditorManagerError(
                            msg: NSLocalizedString("Failed to get file information from the server.", comment: ""))))
            }
        }
    }

    private func fetchDocumentInfoLegacy(_ file: ASCFile, openMode: ASCDocumentOpenMode = .edit, complation: @escaping (Result<OnlyofficeDocumentConfig, Error>) -> Void) {
        var params: [String: Any] = [:]

        let key: String? = {
            switch openMode {
            case .edit: return "edit"
            case .view: return "view"
            case .fillform: return "fill"
            default: return nil
            }
        }()

        if let key {
            params[key] = "true"
        }

        clientRequest(OnlyofficeAPI.Endpoints.Files.openEdit(file: file), params) { response, error in
            if let error {
                complation(.failure(error))
            }

            if let config = response?.result {
                self.documentCommonConfig = config.dictionary?.jsonString()
                self.documentKeyForTrack = config.document?.key
                self.documentURLForTrack = config.document?.url
                self.documentToken = config.token
                self.documentFillingSessionId = config.fillingSessionId

                if !(config.document?.key?.isEmpty ?? true), !(config.document?.url?.isEmpty ?? true) {
                    return complation(.success(config))
                }
            }
            return complation(.failure(ASCEditorManagerError(msg: NSLocalizedString("Failed to get file information from the server.", comment: ""))))
        }
    }

    public func fetchDocumentService(_ handler: @escaping (String?, String?, Error?) -> Void) {
        let documentServerVersionRequest = DocumentServerVersionRequest(version: .true)
        clientRequest(OnlyofficeAPI.Endpoints.Settings.documentService, documentServerVersionRequest.dictionary) { response, error in

            let removePath = "/web-apps/apps/api/documents/api.js"

            if let results = response?.result as? String {
                if let url = self.apiClient.absoluteUrl(from: URL(string: results)) {
                    let baseUrl = url.absoluteString.replacingOccurrences(of: removePath, with: "")

                    self.documentServiceURL = baseUrl

                    handler(baseUrl, "", nil)
                    return
                }
            }

            if let results = response?.result as? [String: Any] {
                if let jsonData = try? JSONSerialization.data(withJSONObject: results),
                   let documentServerVersion = try? JSONDecoder().decode(DocumentServerVersionResponse.self, from: jsonData),
                   let docService = documentServerVersion.docServiceUrlApi,
                   let version = documentServerVersion.version
                {
                    self.documentServiceVersion = version

                    if let url = self.apiClient.absoluteUrl(from: URL(string: docService)) {
                        let baseUrl = url.absoluteString.replacingOccurrences(of: removePath, with: "")

                        self.documentServiceURL = baseUrl

                        handler(baseUrl, version, nil)
                    }
                } else {
                    handler(nil, nil, ASCEditorManagerError(msg: NSLocalizedString("Failed to get the address of the document server.", comment: "")))
                }
            } else {
                handler(nil, nil, error)
            }
        }
    }

    // MARK: - Local editing online files

    func editFileLocally(
        for provider: ASCFileProviderProtocol,
        _ file: ASCFile,
        openMode: ASCDocumentOpenMode,
        canEdit: Bool,
        handler: ASCEditorManagerOpenHandler? = nil,
        closeHandler: ASCEditorManagerCloseHandler? = nil,
        renameHandler: ASCEditorManagerRenameHandler? = nil,
        lockedHandler: ASCEditorManagerLockedHandler? = nil
    ) {
        var cancel = false

        self.provider = provider
        openedlocallyFile = file
        self.closeHandler = nil
        openHandler = nil
        favoriteHandler = nil
        shareHandler = nil
        self.renameHandler = nil
        self.lockedHandler = lockedHandler

        if provider is ASCOnlyofficeProvider {
            fetchDocumentInfoLegacy(file, openMode: (openMode == .view && canEdit) ? .edit : openMode) { result in
                if cancel {
                    handler?(.end, 1, nil, &cancel)
                    return
                }

                switch result {
                case let .success(config):
                    handler?(.progress, 0.1, nil, &cancel)

                    self.closeHandler = closeHandler
                    self.openHandler = handler
                    self.renameHandler = renameHandler

                    let allowEdit = config.document?.permissions?.edit ?? false
                    let allowReview = config.document?.permissions?.review ?? false
                    let allowComment = config.document?.permissions?.comment ?? false
                    let allowFillForms = config.document?.permissions?.fillForms ?? false

                    let canEdit = (allowEdit || (!allowEdit && (allowReview || allowComment || allowFillForms))) && canEdit

                    if openMode == .view && !canEdit {
                        var cancel = false
                        self.downloadAndOpenFile(for: provider, file, openMode: openMode, canEdit: canEdit, &cancel)
                    } else {
                        self.timer = Timer.scheduledTimer(
                            timeInterval: 4,
                            target: self,
                            selector: #selector(ASCEditorManager.updateLocallyEditFile(_:)),
                            userInfo: ASCUpdateLocallyEditFileInfo(file: file, config: config, openMode: openMode, canEdit: canEdit),
                            repeats: true
                        )
                        self.timer?.fire()
                    }

                case let .failure(error):
                    handler?(.error, 1, error, &cancel)
                }
            }
        } else {
            self.closeHandler = closeHandler
            self.renameHandler = renameHandler
            openHandler = handler

            downloadAndOpenFile(for: provider, file, openMode: openMode, canEdit: canEdit, &cancel)
        }
    }

    private func stopLocallyEditing(_ clearHandlers: Bool = true) {
        provider = nil

        if timer != nil {
            if let file = openedlocallyFile {
                if let key = documentKeyForTrack {
                    apiClient.request(
                        OnlyofficeAPI.Endpoints.Files.trackEdit(file: file),
                        [
                            "docKeyForTrack": key,
                            "isFinish": "true",
                        ]
                    ) { response, error in
                        if let error = error {
                            log.error(error)
                        }
                    }
                }
            }

            timer?.invalidate()
            timer = nil
            openedlocallyFile = nil

            if clearHandlers {
                closeHandler = nil
                openHandler = nil
                favoriteHandler = nil
                shareHandler = nil
                renameHandler = nil
                trackingFileStatus = 0
            }
        }
    }

    func downloadAndOpenFile(
        for provider: ASCFileProviderProtocol,
        _ file: ASCFile,
        openMode: ASCDocumentOpenMode,
        canEdit: Bool,
        _ cancel: inout Bool
    ) {
        ASCEntityManager.shared.downloadTemp(for: provider, entity: file) { [unowned self] status, progress, result, error, cancel in
            if status == .begin {
                self.openHandler?(.progress, 0.1, nil, &cancel)
            }

            if status == .end || status == .error {
                if status == .error {
                    self.openHandler?(.error, 1, error, &cancel)
                    self.stopLocallyEditing()
                } else {
                    self.openHandler?(.end, 1, nil, &cancel)

                    if let newFile = result as? ASCFile {
                        self.provider = provider
                        self.openEditorLocal(file: newFile, openMode: openMode, canEdit: canEdit, locallyEditing: true)
                    } else {
                        self.stopLocallyEditing()
                        self.openHandler?(.error, 1, nil, &cancel)
                    }
                }
            } else if status == .progress {
                self.openHandler?(.progress, progress, nil, &cancel)
            }
        }
    }

    @objc func updateLocallyEditFile(_ timer: Timer) {
        var cancel = false
        let info = timer.userInfo as? ASCUpdateLocallyEditFileInfo

        if let file = openedlocallyFile,
           let key = documentKeyForTrack
        {
            if trackingReadyForLocking == trackingFileStatus {
                clientRequest(
                    OnlyofficeAPI.Endpoints.Files.trackEdit(file: file), ["docKeyForTrack": key]
                ) { response, error in
                    if let error {
                        log.error(error)
                        self.openHandler?(.error, 1, error, &cancel)
                    }

                    if let response = response?.result {
                        if let key = response["key"] as? Bool {
                            if !key {
                                let error = response["value"] as? String ?? "No key"
                                log.warning(error)
                            }
                        }
                    }
                }
            } else {
                clientRequest(OnlyofficeAPI.Endpoints.Files.startEdit(file: file), ["editingAlone": true]) { response, error in

                    if let error {
                        if let status = response?.status,
                           let code = response?.statusCode,
                           status == 1, code == 403
                        {
                            self.openHandler?(.end, 1, nil, &cancel)
                            self.stopLocallyEditing(false)
                            self.lockedHandler?()
                            return
                        }

                        self.openHandler?(.error, 1, error, &cancel)
                        self.stopLocallyEditing(false)

                    } else {
                        if let result = response?.result {
                            self.documentKeyForTrack = result
                        }

                        if let provider = ASCFileManager.onlyofficeProvider {
                            self.trackingFileStatus = self.trackingReadyForLocking
                            self.downloadAndOpenFile(
                                for: provider,
                                file,
                                openMode: info?.openMode ?? .edit,
                                canEdit: info?.canEdit ?? true,
                                &cancel
                            )
                        }
                    }
                }
            }
        }
    }

    // MARK: - Public

    func editLocal(
        _ file: ASCFile,
        openMode: ASCDocumentOpenMode = .edit,
        canEdit: Bool = true,
        openHandler: ASCEditorManagerOpenHandler? = nil,
        closeHandler: ASCEditorManagerCloseHandler? = nil,
        renameHandler: ASCEditorManagerRenameHandler? = nil
    ) {
        var cancel = false

        self.closeHandler = nil
        self.renameHandler = nil

        openedFileMode = openMode

        openHandler?(.begin, 0, nil, &cancel)
        openHandler?(.end, 0, nil, &cancel)

        self.closeHandler = closeHandler
        self.renameHandler = renameHandler

        openEditorLocal(
            file: file,
            openMode: openMode,
            canEdit: canEdit,
            autosave: true
        )
    }

    func editCloud(
        _ file: ASCFile,
        openMode: ASCDocumentOpenMode = .edit,
        canEdit: Bool,
        openHandler: ASCEditorManagerOpenHandler? = nil,
        closeHandler: ASCEditorManagerCloseHandler? = nil,
        favoriteHandler: ASCEditorManagerFavoriteHandler? = nil,
        shareHandler: ASCEditorManagerShareHandler? = nil,
        renameHandler: ASCEditorManagerRenameHandler? = nil,
        fillFormDidSendHandler: ASCEditorManagerFillFormDidSendHandler? = nil
    ) {
        var cancel = false

        self.closeHandler = nil
        self.favoriteHandler = nil
        self.shareHandler = nil
        self.renameHandler = nil
        self.fillFormDidSendHandler = nil

        let fetchAndOpen = {
            self.fetchDocumentInfoLegacy(file, openMode: (openMode == .view && canEdit) ? .edit : openMode) { result in
                if cancel {
                    openHandler?(.end, 1, nil, &cancel)
                    return
                }

                switch result {
                case let .failure(error):
                    openHandler?(.error, 1, error, &cancel)

                case let .success(config):
                    openHandler?(.progress, 0.7, nil, &cancel)

                    self.closeHandler = closeHandler
                    self.favoriteHandler = favoriteHandler
                    self.shareHandler = shareHandler
                    self.renameHandler = renameHandler
                    self.fillFormDidSendHandler = fillFormDidSendHandler

                    self.openEditorInCollaboration(
                        file: file,
                        config: config,
                        openMode: openMode,
                        handler: openHandler
                    )
                }
            }
        }

        openHandler?(.progress, 0.3, nil, &cancel)

        if let _ = documentServiceURL {
            fetchAndOpen()
        } else {
            fetchDocumentService { url, version, error in
                if cancel {
                    DispatchQueue.main.async {
                        openHandler?(.end, 1, nil, &cancel)
                    }
                    return
                }

                if error != nil {
                    DispatchQueue.main.async {
                        openHandler?(.error, 1, error, &cancel)
                    }
                } else {
                    DispatchQueue.main.async {
                        fetchAndOpen()
                    }
                }
            }
        }
    }

    func browsePdfLocal(
        _ pdf: ASCFile,
        openMode: ASCDocumentOpenMode = .fillform,
        openHandler: ASCEditorManagerOpenHandler? = nil,
        closeHandler: ASCEditorManagerCloseHandler? = nil,
        renameHandler: ASCEditorManagerRenameHandler? = nil
    ) {
        var cancel = false
        let isDocumentOformPdf = ASCOformPdfChecker.checkLocal(url: URL(fileURLWithPath: pdf.id))

        openedFile = pdf

        openHandler?(.begin, 0, nil, &cancel)

        if pdf.device {
            if isDocumentOformPdf {
                editLocal(
                    pdf,
                    openMode: openMode,
                    closeHandler: closeHandler,
                    renameHandler: renameHandler
                )
            } else {
                ASCAnalytics.logEvent(ASCConstants.Analytics.Event.openPdf, parameters: [
                    ASCAnalytics.Event.Key.portal: apiClient.baseURL?.absoluteString ?? ASCAnalytics.Event.Value.none,
                    ASCAnalytics.Event.Key.onDevice: !pdf.id.contains(Path.userTemporary.rawValue),
                ])
                documentInteractionController = UIDocumentInteractionController(url: URL(fileURLWithPath: pdf.id))
                documentInteractionController?.uti = "com.adobe.pdf"
                documentInteractionController?.delegate = self
                documentInteractionController?.presentPreview(animated: true)
            }
        }

        openHandler?(.end, 1, nil, &cancel)
    }

    func browsePdfCloud(
        for provider: ASCFileProviderProtocol,
        _ pdf: ASCFile,
        openMode: ASCDocumentOpenMode? = .view,
        openHandler: ASCEditorManagerOpenHandler? = nil,
        closeHandler: ASCEditorManagerCloseHandler? = nil,
        renameHandler: ASCEditorManagerRenameHandler? = nil
    ) {
        var cancel = false

        openHandler?(.begin, 0, nil, &cancel)

        if let viewUrl = pdf.viewUrl {
            let destination = Path.userTemporary + Path(pdf.title)

            Task {
                var cancel = false

                var isDocumentOformPdf = false

                if pdf.isForm {
                    isDocumentOformPdf = true
                } else {
                    isDocumentOformPdf = await ASCOformPdfChecker.checkCloud(url: URL(string: viewUrl), for: provider)
                }

                if isDocumentOformPdf {
                    pdf.editable = true // Force allow edit the file

                    DispatchQueue.main.sync {
                        openHandler?(.end, 1, nil, &cancel)
                        provider.open(file: pdf, openMode: openMode ?? .view, canEdit: pdf.security.edit)
                    }
                } else {
                    provider.download(viewUrl, to: URL(fileURLWithPath: destination.rawValue), range: nil) { result, progress, error in
                        if cancel {
                            provider.cancel()
                            openHandler?(.end, 1, nil, &cancel)
                            return
                        }

                        if let error {
                            openHandler?(.error, Float(progress), error, &cancel)
                        } else if result != nil {
                            let localPdf = ASCFile()
                            localPdf.id = destination.rawValue
                            localPdf.title = pdf.title
                            localPdf.device = true

                            self.openedlocallyFile = pdf
                            self.provider = provider

                            self.browsePdfLocal(
                                localPdf,
                                openHandler: openHandler,
                                closeHandler: closeHandler,
                                renameHandler: renameHandler
                            )

                            openHandler?(.end, 1, nil, &cancel)
                        } else {
                            openHandler?(.progress, Float(progress), error, &cancel)
                        }
                    }
                }
            }
        }
    }

    func browseMedia(for fileProvider: ASCFileProviderProtocol, _ file: ASCFile, files: [AnyObject]?) {
        openedFile = file
        provider = fileProvider

        var medias: [Media] = []

        let accessToken: (_ url: URL?) -> String? = { url in
            if let onlyofficeProvider = fileProvider as? ASCOnlyofficeProvider {
                // TODO: Hotfix by Linnic. Remove after resolve of conflict between SAAS and Enterprise versions
                if onlyofficeProvider.apiClient.baseURL?.host == url?.host {
                    return onlyofficeProvider.authorization
                }
            }
            return fileProvider.authorization
        }

        let media: (_ file: ASCFile) -> Media? = { file in
            let fileExt = file.title.fileExtension().lowercased()
            let isImage = ASCConstants.FileExtensions.images.contains(fileExt)
            let isVideo = ASCConstants.FileExtensions.videos.contains(fileExt)

            if file.device {
                if isImage {
                    if let image = UIImage(contentsOfFile: file.id) {
                        return Media(image: image)
                    }
                } else if isVideo {
                    let videoUrl = URL(fileURLWithPath: file.id)
                    let placeholderUrl = URL(fileURLWithPath: Bundle.main.path(forResource: "video-defaults", ofType: "png", inDirectory: "Other") ?? "")

                    if let accessToken = accessToken(videoUrl) {
                        return Media(videoURL: videoUrl,
                                     previewImageURL: placeholderUrl,
                                     headerFields: ["Authorization": accessToken])
                    }

                    return Media(videoURL: videoUrl, previewImageURL: placeholderUrl)
                }
            } else {
                if let url = fileProvider.absoluteUrl(from: file.viewUrl) {
                    if isImage {
                        return Media(url: url)
                    } else if isVideo {
                        let placeholderUrl = URL(fileURLWithPath: Bundle.main.path(forResource: "video-defaults", ofType: "png", inDirectory: "Other") ?? "")

                        if let accessToken = accessToken(url) {
                            return Media(videoURL: url,
                                         previewImageURL: placeholderUrl,
                                         headerFields: ["Authorization": accessToken])
                        }

                        return Media(videoURL: url, previewImageURL: placeholderUrl)
                    }
                }
            }
            return nil
        }

        if let firstMedia = media(file) {
            firstMedia.caption = file.title
            medias.append(firstMedia)
        }

        // Other images
        let otherMedias: [ASCFile] = files?
            .compactMap { $0 as? ASCFile }
            .filter { folderFile -> Bool in
                let fileExtension = folderFile.title.fileExtension().lowercased()
                return
                    (ASCConstants.FileExtensions.images.contains(fileExtension) ||
                        ASCConstants.FileExtensions.videos.contains(fileExtension)) &&
                    folderFile.title != file.title

            } ?? [ASCFile]()

        for otherMedia in otherMedias {
            if let browseMedia = media(otherMedia) {
                browseMedia.caption = otherMedia.title
                medias.append(browseMedia)
            }
        }

        if let windowRootViewController = createEditorWindow()?.rootViewController {
            let imageBrowserController = ASCImageViewController(with: fileProvider)
            imageBrowserController.displayMediaNavigationArrows = true
            imageBrowserController.enableGrid = true

            let imageBrowserNavigation = UINavigationController(rootViewController: imageBrowserController)
            imageBrowserNavigation.modalTransitionStyle = .crossDissolve

            if #available(iOS 13.0, *) {
                imageBrowserNavigation.modalPresentationStyle = .fullScreen
            }

            windowRootViewController.present(imageBrowserNavigation, animated: true, completion: {
                imageBrowserController.dismissHandler = { [weak self] in
                    self?.openedFile = nil
                    self?.cleanupEditorWindow()
                }

                ASCAnalytics.logEvent(ASCConstants.Analytics.Event.openMedia, parameters: [
                    ASCAnalytics.Event.Key.portal: self.apiClient.baseURL?.absoluteString ?? ASCAnalytics.Event.Value.none,
                    ASCAnalytics.Event.Key.onDevice: file.device,
                ])

                imageBrowserController.medias = medias
            })
        }
    }

    func browseUnknownLocal(_ file: ASCFile, inView: UIView, handler: ASCEditorManagerOpenHandler? = nil) {
        var cancel = false

        openedFile = file

        handler?(.begin, 0, nil, &cancel)

        if file.device {
            ASCAnalytics.logEvent(ASCConstants.Analytics.Event.openExternal, parameters: [
                ASCAnalytics.Event.Key.portal: apiClient.baseURL?.absoluteString ?? ASCAnalytics.Event.Value.none,
                ASCAnalytics.Event.Key.onDevice: !file.id.contains(Path.userTemporary.rawValue),
            ])
            documentInteractionController = UIDocumentInteractionController(url: URL(fileURLWithPath: file.id))
            documentInteractionController?.delegate = self
            documentInteractionController?.presentOptionsMenu(from: inView.bounds, in: inView, animated: true)
        }

        handler?(.end, 1, nil, &cancel)
    }

    func browseUnknownCloud(for provider: ASCFileProviderProtocol, _ file: ASCFile, inView: UIView, handler: ASCEditorManagerOpenHandler? = nil) {
        var cancel = false

        handler?(.begin, 0, nil, &cancel)

        if let viewUrl = file.viewUrl {
            let destination = Path.userTemporary + Path(file.title)
            provider.download(viewUrl, to: URL(fileURLWithPath: destination.rawValue), range: nil) { result, progress, error in
                if cancel {
                    handler?(.end, 1, nil, &cancel)
                    return
                }

                if error != nil {
                    handler?(.error, Float(progress), error, &cancel)
                } else if result != nil {
                    let localFile = ASCFile()
                    localFile.id = destination.rawValue
                    localFile.title = file.title
                    localFile.device = true

                    self.browseUnknownLocal(localFile, inView: inView)

                    handler?(.end, 1, nil, &cancel)
                } else {
                    handler?(.progress, Float(progress), error, &cancel)
                }
            }
        }
    }

    // MARK: - Utils

    func compareCloudSdk(with localSdkString: String?) -> Bool {
        guard
            let localSdkString,
            let documentServerVersionString = documentServiceVersion
        else { return false }

        let documentServerVersion = documentServerVersionString.components(separatedBy: ".")
        let localVersion = localSdkString.components(separatedBy: ".")

        let allowCoauthoring = ASCConstants.remoteConfigValue(forKey: ASCConstants.RemoteSettingsKeys.allowCoauthoring)?.boolValue ?? true
        let checkSdkFully = ASCConstants.remoteConfigValue(forKey: ASCConstants.RemoteSettingsKeys.checkSdkFully)?.boolValue ?? true

        if !allowCoauthoring {
            return false
        }

        var maxVersionIndex = 2

        if !checkSdkFully {
            maxVersionIndex = 1
        }

        if localVersion.count > maxVersionIndex, documentServerVersion.count > maxVersionIndex {
            for i in 0 ... maxVersionIndex {
                if localVersion[i] != documentServerVersion[i] {
                    return false
                }
            }
            return true
        }

        return false
    }

    func checkSDKVersion() -> Bool {
        if ASCAppSettings.Feature.disableSdkVersionCheck { return true }
        return compareCloudSdk(with: localSDKVersion().joined(separator: "."))
    }

    private func removeAutosave(at path: Path) {
        ASCLocalFileHelper.shared.removeDirectory(path)
        UserDefaults.standard.removeObject(forKey: ASCConstants.SettingsKeys.openedDocumentModified)
        UserDefaults.standard.removeObject(forKey: ASCConstants.SettingsKeys.openedDocumentFile)
    }

    // MARK: - Dialog Utils
}

// MARK: - UIDocumentInteractionControllerDelegate

extension ASCEditorManager: UIDocumentInteractionControllerDelegate {
    func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController {
        return (createEditorWindow()?.rootViewController)!
    }

    func documentInteractionControllerDidEndPreview(_ controller: UIDocumentInteractionController) {
        cleanupEditorWindow()

        // Cleanup temporary file
        if let file = openedFile, file.id.range(of: Path.userTemporary.rawValue) != nil {
            ASCLocalFileHelper.shared.removeFile(Path(file.id))
        }

        openedFile = nil
    }
}

// MARK: - Methods

extension ASCEditorManager {
    private func prepareFonts() {
        DocumentLocalConverter.prepareFonts { appFontsCache in
            log.info("Prepare application fonts cache in: \(appFontsCache ?? ASCLocalization.Common.error)")
        }
    }

    /// Open local file
    /// - Parameters:
    ///   - file: The file object located on the device
    ///   - viewMode: Open in preview mode
    ///   - autosave: Autosave
    ///   - locallyEditing: Local editing of an external file
    ///   - handler: File open process handler
    func openEditorLocal(
        file: ASCFile,
        openMode: ASCDocumentOpenMode = .edit,
        canEdit: Bool = true,
        autosave: Bool = false,
        locallyEditing: Bool = false
    ) {
        let title = file.title
        let fileExt = title.fileExtension().lowercased()
        let isDocument = ([ASCConstants.FileExtensions.docx] + ASCConstants.FileExtensions.editorImportDocuments).contains(fileExt)
        let isSpreadsheet = ([ASCConstants.FileExtensions.xlsx] + ASCConstants.FileExtensions.editorImportSpreadsheets).contains(fileExt)
        let isPresentation = ([ASCConstants.FileExtensions.pptx] + ASCConstants.FileExtensions.editorImportPresentations).contains(fileExt)
        let isForm = ([ASCConstants.FileExtensions.pdf] + ASCConstants.FileExtensions.forms).contains(fileExt)

        openedFile = nil
        openedCopy = locallyEditing

        let config = OnlyofficeDocumentConfig(
            document:
            OnlyofficeDocument(
                permissions: OnlyofficeDocumentPermissions(
                    edit: canEdit && UIDevice.allowEditor,
                    fillForms: openMode == .fillform
                ),
                fileType: fileExt
            )
        )

        var editorViewController: UIViewController?

        if isDocument || isForm {
            editorViewController = createDocumentEditorViewController(for: file, config: config, openMode: openMode)
        } else if isSpreadsheet {
            editorViewController = createSpreadsheetEditorViewController(for: file, config: config, openMode: openMode)
        } else if isPresentation {
            editorViewController = createPresentationEditorViewController(for: file, config: config, openMode: openMode)
        }

        guard let editorViewController, let editorWindow = createEditorWindow() else {
            return
        }

        editorViewController.isModalInPresentation = true
        editorViewController.modalTransitionStyle = .crossDissolve
        editorViewController.modalPresentationStyle = .fullScreen

        editorWindow.overrideUserInterfaceStyle = AppThemeService.theme.overrideUserInterfaceStyle
        editorWindow.rootViewController?.present(editorViewController, animated: true, completion: {
            self.openedFile = file

            UserDefaults.standard.set(file.toJSONString(), forKey: ASCConstants.SettingsKeys.openedDocumentFile)

            ASCAnalytics.logEvent(ASCConstants.Analytics.Event.openEditor, parameters: [
                ASCAnalytics.Event.Key.portal: self.apiClient.baseURL?.absoluteString ?? ASCAnalytics.Event.Value.none,
                ASCAnalytics.Event.Key.type: isDocument
                    ? ASCAnalytics.Event.Value.document
                    : (isSpreadsheet
                        ? ASCAnalytics.Event.Value.spreadsheet
                        : (isPresentation
                            ? ASCAnalytics.Event.Value.presentation
                            : (isForm
                                ? ASCAnalytics.Event.Value.form
                                : ASCAnalytics.Event.Value.unknown
                            )
                        )
                    ),
                ASCAnalytics.Event.Key.onDevice: file.device,
                ASCAnalytics.Event.Key.locallyEditing: locallyEditing,
                ASCAnalytics.Event.Key.fileExt: fileExt,
                ASCAnalytics.Event.Key.viewMode: openMode == .view,
            ])
        })
    }

    /// Open file from Document Server in collaboration mode
    /// - Parameters:
    ///   - file: The file object
    ///   - viewMode: Force open in view mode
    ///   - handler: File open process handler
    func openEditorInCollaboration(
        file: ASCFile,
        config: OnlyofficeDocumentConfig,
        openMode: ASCDocumentOpenMode = .edit,
        handler: ASCEditorManagerOpenHandler? = nil
    ) {
        var cancel = false

        let title = file.title
        let fileExt = title.fileExtension().lowercased()
        let isDocument = ([ASCConstants.FileExtensions.docx] + ASCConstants.FileExtensions.editorImportDocuments).contains(fileExt)
        let isSpreadsheet = ([ASCConstants.FileExtensions.xlsx] + ASCConstants.FileExtensions.editorImportSpreadsheets).contains(fileExt)
        let isPresentation = ([ASCConstants.FileExtensions.pptx] + ASCConstants.FileExtensions.editorImportPresentations).contains(fileExt)
        let isForm = ([ASCConstants.FileExtensions.pdf] + ASCConstants.FileExtensions.forms).contains(fileExt)

        openedFile = nil

        var editorViewController: UIViewController?

        if isDocument || isForm {
            editorViewController = createDocumentEditorViewController(
                for: file,
                config: config,
                openMode: openMode
            )
        } else if isSpreadsheet {
            editorViewController = createSpreadsheetEditorViewController(
                for: file,
                config: config,
                openMode: openMode
            )
        } else if isPresentation {
            editorViewController = createPresentationEditorViewController(
                for: file,
                config: config,
                openMode: openMode
            )
        }

        guard let editorViewController, let editorWindow = createEditorWindow() else {
            return
        }

        editorViewController.isModalInPresentation = true
        editorViewController.modalTransitionStyle = .crossDissolve
        editorViewController.modalPresentationStyle = .fullScreen

        editorWindow.overrideUserInterfaceStyle = AppThemeService.theme.overrideUserInterfaceStyle
        editorWindow.rootViewController?.present(editorViewController, animated: true, completion: {
            self.openedFile = file
            self.provider = ASCFileManager.onlyofficeProvider

            UserDefaults.standard.set(file.toJSONString(), forKey: ASCConstants.SettingsKeys.openedDocumentFile)

            ASCAnalytics.logEvent(ASCConstants.Analytics.Event.openEditor, parameters: [
                ASCAnalytics.Event.Key.portal: self.apiClient.baseURL?.absoluteString ?? ASCAnalytics.Event.Value.none,
                ASCAnalytics.Event.Key.type: isDocument
                    ? ASCAnalytics.Event.Value.document
                    : (isSpreadsheet
                        ? ASCAnalytics.Event.Value.spreadsheet
                        : (isPresentation
                            ? ASCAnalytics.Event.Value.presentation
                            : (isForm
                                ? ASCAnalytics.Event.Value.form
                                : ASCAnalytics.Event.Value.unknown
                            )
                        )
                    ),
                ASCAnalytics.Event.Key.onDevice: false,
                ASCAnalytics.Event.Key.locallyEditing: false,
                ASCAnalytics.Event.Key.fileExt: fileExt,
                ASCAnalytics.Event.Key.viewMode: openMode == .view,
            ])

            handler?(.end, 1, nil, &cancel)
        })
    }

    /// Version of local converter
    /// - Returns: Array of numbers of version
    func localSDKVersion() -> [String] {
        if let sdkVersion = DocumentEditorViewController.sdkVersionString {
            return sdkVersion.components(separatedBy: ".")
        }
        return []
    }

    func checkUnsuccessfullyOpenedFile(parent: UIViewController) {
        if let openedDocumentFile = UserDefaults.standard.string(forKey: ASCConstants.SettingsKeys.openedDocumentFile),
           let file = ASCFile(JSONString: openedDocumentFile)
        {
            if !UserDefaults.standard.bool(forKey: ASCConstants.SettingsKeys.openedDocumentModified) {
                removeAutosave(at: Path.userAutosavedInformation + file.title)
                return
            }

            // Force reset open recover version
            UserDefaults.standard.removeObject(forKey: ASCConstants.SettingsKeys.openedDocumentModified)

            // Display recovering dialog with delay timer
            var forceCancel = false
            let progressAlert = ASCProgressAlert(
                title: NSLocalizedString("Restoring", comment: "Caption of the processing") + "...",
                message: nil,
                handler: { cancel in
                    forceCancel = cancel
                }
            )

            progressAlert.show()

            let fullTime = 3.0
            let interval = 0.01

            var deadTime = 0.0
            var timer: Timer!

            timer = Timer.scheduledTimer(timeInterval: interval, target: BlockOperation(block: { [weak self] in
                if forceCancel {
                    timer.invalidate()

                    self?.removeAutosave(at: Path.userAutosavedInformation + file.title)
                } else {
                    deadTime += interval
                    progressAlert.progress = Float(deadTime / fullTime)

                    if deadTime >= fullTime {
                        timer.invalidate()

                        progressAlert.hide(completion: {
                            self?.openedFileMode = .edit

                            self?.openEditorLocal(
                                file: file,
                                openMode: .edit,
                                canEdit: true,
                                autosave: true
                            )
                        })
                    }
                }
            }), selector: #selector(Operation.main), userInfo: nil, repeats: true)
        }
    }
}

extension ASCEditorManager {
    func editorDocumentDidOpen(_ controller: EditorViewControllerProtocol, result: Result<EditorDocumentProtocol, Error>) {
        log.info("\(String(describing: controller)) :documentDidOpen")

        switch result {
        case .success:
            if let file = openedFile,
               !file.device,
               provider?.allowEdit(entity: file) ?? false
            {
                clientRequest(OnlyofficeAPI.Endpoints.Files.startEdit(file: file), ["editingAlone": false]) { response, error in
                    if let error = error {
                        log.error(error)
                    }
                }
            }
        case let .failure(error):
            log.error("Failure to open document: \(error)")
            cleanupEditorWindow()
            removeAutosave(at: Path.userAutosavedInformation + (openedFile?.title ?? ""))

            openedFile = nil
        }
    }

    func editorDocumentDidClose(_ controller: EditorViewControllerProtocol, result: Result<EditorDocumentProtocol, Error>) {
        log.info("\(String(describing: controller)) :documentDidClose")

        var outputFileExtension = ASCConstants.FileExtensions.docx

        if controller is SpreadsheetEditorViewController {
            outputFileExtension = ASCConstants.FileExtensions.xlsx
        } else if controller is PresentationEditorViewController {
            outputFileExtension = ASCConstants.FileExtensions.pptx
        }

        cleanupEditorWindow()

        let editorImportFormats = ASCConstants.FileExtensions.editorImportDocuments + ASCConstants.FileExtensions.editorImportSpreadsheets + ASCConstants.FileExtensions.editorImportPresentations

        let cleanup: () -> Void = { [weak self] in
            guard let self, let openedFile, openedCopy else { return }

            do {
                if FileManager.default.fileExists(atPath: openedFile.id) {
                    try FileManager.default.removeItem(atPath: openedFile.id)
                }
            } catch {
                log.error(error)
            }
        }

        if let file = openedFile {
            var cancel = false

            if case let .failure(error) = result {
                log.debug(error)

                stopLocallyEditing()
                removeAutosave(at: Path.userAutosavedInformation + file.title)

                if let error = error as? (any DocumentConverterErrorProtocol), error.isEqual(DocumentEditor.DocumentConverterError.cancel) {
                    closeHandler?(.end, 1, nil, nil, &cancel)
                } else {
                    closeHandler?(.error, 1, nil, error, &cancel)
                }

                cleanup()
                openedFile = nil

                return
            }

            if file.device {
                if openedlocallyFile == nil, openedCopy {
                    let copyFile = Path.userDocuments + Path(file.id).fileName
                    guard let dstPath = ASCLocalFileHelper.shared.resolve(filePath: copyFile) else {
                        closeHandler?(.error, 1, nil, nil, &cancel)
                        return
                    }

                    file.id = dstPath.rawValue
                } else {
                    let fileExtension = file.title.fileExtension().lowercased()

                    // if not docx
                    if editorImportFormats.contains(fileExtension) {
                        let fileTo = Path(Path(file.id).url.deletingPathExtension().path + ".\(outputFileExtension)")
                        resolvedFilePath = fileTo
                    }
                }

                let filePath = Path(file.id)

                if let openedlocallyFile, let provider {
                    // File is not original
                    let fileExtension = file.title.fileExtension().lowercased()
                    if editorImportFormats.contains(fileExtension) {
                        file.title = file.title.fileName() + ".\(outputFileExtension)"
                        file.id = resolvedFilePath.rawValue

                        // Move autosave
                        do {
                            try FileManager.default.moveItem(
                                atPath: (Path.userAutosavedInformation + "\(file.title.fileName()).\(fileExtension)").rawValue,
                                toPath: (Path.userAutosavedInformation + file.title).rawValue
                            )
                        } catch {
                            debugPrint(error)
                        }
                    }

                    ASCEntityManager.shared.uploadEdit(
                        for: provider,
                        file: file,
                        originalFile: openedlocallyFile,
                        handler: { [unowned self] status, progress, result, error, cancel in
                            if status == .begin {
                                self.closeHandler?(.begin, 0, file, nil, &cancel)
                            } else if status == .progress {
                                self.closeHandler?(.progress, progress, file, nil, &cancel)
                            } else if status == .end || status == .error {
                                let dateFormatter = DateFormatter()
                                dateFormatter.dateFormat = "yyyyMMddHHmmss"

                                let nowString = dateFormatter.string(from: Date())
                                let backupFileName = "\(file.title.fileName())-Backup-\(nowString).\(file.title.fileExtension())"

                                if status == .end {
                                    if let resultFile = result as? ASCFile {
                                        self.closeHandler?(.end, 1, resultFile, nil, &cancel)
                                    } else {
                                        self.closeHandler?(.end, 1, file, nil, &cancel)
                                    }
                                } else {
                                    log.error("Couldn't save changes at server. Error: \(String(describing: error))")
                                    let errorMsg = String(format: NSLocalizedString("Couldn't save changes at server. Your modified document is saved in local storage as %@", comment: ""), backupFileName)
                                    self.closeHandler?(.error, 1, file, ASCProviderError(msg: errorMsg), &cancel)
                                }
                                self.stopLocallyEditing()

                                // Store backup
                                if status == .error {
                                    // Backup on Device file
                                    let backupPath = Path.userDocuments + Path(backupFileName)

                                    ASCLocalFileHelper.shared.copy(from: resolvedFilePath, to: backupPath)
                                }

                                let lastTempFile = Path.userTemporary + file.title
                                let autosaveFile = Path.userAutosavedInformation + file.title

                                // Remove autosave
                                ASCLocalFileHelper.shared.removeDirectory(lastTempFile)

                                // Remove original
                                removeAutosave(at: autosaveFile)

                                cleanup()
                                openedFile = nil
                            }
                        }
                    )

                } else {
                    let owner = ASCUser()
                    owner.displayName = UIDevice.displayName

                    let file = ASCFile()
                    file.id = filePath.rawValue
                    file.rootFolderType = .deviceDocuments
                    file.title = filePath.fileName
                    file.created = filePath.creationDate
                    file.updated = filePath.modificationDate
                    file.createdBy = owner
                    file.updatedBy = owner
                    file.device = true
                    file.displayContentLength = String.fileSizeToString(with: filePath.fileSize ?? 0)
                    file.pureContentLength = Int(filePath.fileSize ?? 0)

                    let fileExtension = file.title.fileExtension().lowercased()
                    if editorImportFormats.contains(fileExtension) {
                        file.id = resolvedFilePath.rawValue
                        file.title = file.title.fileName() + ".\(outputFileExtension)"

                        let newFilePath = Path(file.id)
                        file.created = newFilePath.creationDate
                        file.updated = newFilePath.modificationDate
                        file.displayContentLength = String.fileSizeToString(with: newFilePath.fileSize ?? 0)
                        file.pureContentLength = Int(newFilePath.fileSize ?? 0)
                    }

                    closeHandler?(.end, 1, file, nil, &cancel)

                    // Remove autosave
                    ASCLocalFileHelper.shared.removeDirectory(Path.userTemporary + file.title)

                    // Remove original
                    removeAutosave(at: Path.userAutosavedInformation + file.title)

                    cleanup()
                    openedFile = nil
                }

            } else {
                if let closeHandler = closeHandler {
                    closeHandler(.begin, 0, file, nil, &cancel)
                    removeAutosave(at: Path.userAutosavedInformation + file.title)

                    clientRequest(OnlyofficeAPI.Endpoints.Files.info(file: file)) { [weak self] response, error in
                        if let newFile = response?.result {
                            closeHandler(.end, 1, newFile, nil, &cancel)
                        } else {
                            closeHandler(.error, 1, file, error, &cancel)
                        }

                        cleanup()
                        self?.openedFile = nil
                    }
                } else {
                    cleanup()
                    openedFile = nil
                }
            }

//            cleanup()
//            openedFile = nil
        }
    }

    func editorDocumentDidExport(_ controller: EditorViewControllerProtocol, document: EditorDocumentProtocol, result: Result<URL?, Error>) {
        log.info("\(String(describing: controller)): documentDidExport")
    }

    func editorDocumentDidBackup(_ controller: EditorViewControllerProtocol, document: EditorDocumentProtocol) {
        log.info("\(String(describing: controller)): documentBackup")

        var isDocumentModifity = false

        if let controller = controller as? DocumentEditorViewController {
            isDocumentModifity = controller.isDocumentModifity
        } else if let controller = controller as? PresentationEditorViewController {
            isDocumentModifity = controller.isDocumentModifity
        } else if let controller = controller as? SpreadsheetEditorViewController {
            isDocumentModifity = controller.isDocumentModifity
        }

        if isDocumentModifity {
            UserDefaults.standard.set(true, forKey: ASCConstants.SettingsKeys.openedDocumentModified)
        }
    }

    func editorDocumentEditorSettings(_ controller: EditorViewControllerProtocol) -> [AnyHashable: Any] {
        setenv("APPLICATION_NAME", ASCConstants.Name.appNameShort, 1)
        setenv("COMPANY_NAME", ASCConstants.Name.copyright, 1)

        if controller is DocumentEditorViewController {
            return documentEditorExternalSettings
        } else if controller is PresentationEditorViewController {
            return presentationEditorExternalSettings
        } else if controller is SpreadsheetEditorViewController {
            return spreadsheetEditorExternalSettings
        }

        return [:]
    }

    func editorDocumentFavorite(_ controller: EditorViewControllerProtocol, favorite: Bool, complation: @escaping ((Result<Bool, Error>) -> Void)) {
        if let file = openedFile, let favoriteHandler {
            favoriteHandler(file) { favorite in
                self.openedFile?.isFavorite = favorite
                complation(.success(favorite))
            }
        }
    }

    func editorDocumentShare(_ controller: EditorViewControllerProtocol, complation: @escaping ((Result<Bool, Error>) -> Void)) {
        if let file = openedFile {
            shareHandler?(file)
            complation(.success(true))
        }
    }

    func editorDocumentRename(_ controller: EditorViewControllerProtocol, title: String, complation: @escaping ((Result<Bool, Error>) -> Void)) {
        if
            let file = openedCopy ? openedlocallyFile : openedFile,
            let renameHandler
        {
            let fileExtension = file.title.fileExtension()

            renameHandler(file, title) { success in
                if success {
                    for file in [self.openedlocallyFile, self.openedFile].compactMap(\.self) {
                        file.title = title

                        if !fileExtension.isEmpty {
                            file.title = "\(title).\(fileExtension)"
                        }
                    }

                    // Rename work copy
                    if let openedFile = self.openedFile, openedFile.device {
                        let url = URL(fileURLWithPath: openedFile.id)
                        let directory = url.deletingLastPathComponent()
                        let newUrl = directory.appendingPathComponent(openedFile.title)
                        openedFile.id = newUrl.path
                        openedFile.viewUrl = newUrl.path
                    }
                }
                complation(.success(true))
            }
        } else {
            complation(.failure(
                ASCEditorManagerError(
                    msg: NSLocalizedString("Couldn't rename the file", comment: "")
                )
            ))
        }
    }

    func editorFillFormDidSend(_ controller: EditorViewControllerProtocol, complation: @escaping ((Result<Bool, any Error>) -> Void)) {
        if
            let file = openedFile ?? openedlocallyFile,
            let fillFormDidSendHandler
        {
            fillFormDidSendHandler(file, documentFillingSessionId) { success in
                complation(.success(true))
            }
        } else {
            complation(.failure(
                ASCEditorManagerError(
                    msg: NSLocalizedString("Failed to submit the form", comment: "")
                )
            ))
        }
    }
}
