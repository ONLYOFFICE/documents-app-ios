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
typealias ASCEditorManagerShareHandler = (_ file: ASCFile?) -> Void
typealias ASCEditorManagerLockedHandler = () -> Void

class ASCEditorManager: NSObject, DEEditorDelegate, SEEditorDelegate, PEEditorDelegate, UITextFieldDelegate, UIDocumentInteractionControllerDelegate {
    public static let shared = ASCEditorManager()

    // MARK: - Private

    private var openedFile: ASCFile?
    private var provider: ASCFileProviderProtocol?
    private var closeHandler: ASCEditorManagerCloseHandler?
    private var openHandler: ASCEditorManagerOpenHandler?
    private var favoriteHandler: ASCEditorManagerFavoriteHandler?
    private var shareHandler: ASCEditorManagerShareHandler?
    private var documentInteractionController: UIDocumentInteractionController?
    private var documentServiceURL: String?
    private var documentKeyForTrack: String?
    private var documentURLForTrack: String?
    private var documentToken: String?
    private var documentPermissions: String?
    private var documentCommonConfig: String?
    private var editorWindow: UIWindow?
    private let converterKey = ASCConstants.Keys.converterKey
    private let trackingReadyForLocking = 10000
    private var timer: Timer?
    private var trackingFileStatus: Int = 0
    private var lockedHandler: ASCEditorManagerLockedHandler?
    private var openedlocallyFile: ASCFile?
    private var openedCopy = false
    private var openedFilePassword = ""
    private var openedFileInViewMode = false
    private let alert = ASCConverterOptionsAlert()
    private var encoding: Int?
    private var delimiter: Int?
    private var resolvedFilePath: Path!

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

    override required init() {
        super.init()

        // Localize Presentation Viewer
        _ = NSLocalizedString("End Slide Show", comment: "Presentation Viewer")
        _ = NSLocalizedString("%i of %i", comment: "Presentation Viewer")
        _ = NSLocalizedString("Slide %i of %i", comment: "Presentation Viewer")

        // Prepare to use custom fonts
        DocumentLocalConverter.prepareFonts { appFontsCache in
            log.info("Prepare application fonts cache in: \(appFontsCache ?? ASCLocalization.Common.error)")
            if UIDevice.allowEditor {
                SEEditorContext.sharedInstance().fontsPaths = ASCEditorManager.shared.editorFontsPaths
                SEEditorContext.sharedInstance().dataFontsPath = ASCEditorManager.shared.dataFontsPath
                SEEditorContext.sharedInstance().load()
            }
        }
    }

    private func createEditorWindow() -> UIWindow? {
        cleanupEditorWindow()

        editorWindow = UIWindow(frame: UIScreen.main.bounds)
        editorWindow?.rootViewController = UIViewController()

        if let delegate = UIApplication.shared.delegate {
            editorWindow?.tintColor = delegate.window??.tintColor
        }

        if let topWindow = UIApplication.shared.keyWindow {
            editorWindow?.windowLevel = min(topWindow.windowLevel + 1, UIWindow.Level.statusBar - 10)
        }

        editorWindow?.makeKeyAndVisible()

        return editorWindow
    }

    private func cleanupEditorWindow() {
        editorWindow?.isHidden = true
        editorWindow?.removeFromSuperview()

        editorWindow = nil
    }

    func openEditorLocal(file: ASCFile, viewMode: Bool = false, autosave: Bool = false, locallyEditing: Bool = false, handler: ASCEditorManagerOpenHandler? = nil) {
        let title = file.title
        let fileExt = title.fileExtension().lowercased()
        let isDocument = (["docx"] + ASCConstants.FileExtensions.editorImportDocuments).contains(fileExt)
        let isSpreadsheet = (["xlsx"] + ASCConstants.FileExtensions.editorImportSpreadsheets).contains(fileExt)
        let isPresentation = (["pptx"] + ASCConstants.FileExtensions.editorImportPresentations).contains(fileExt)
        let isForm = ASCConstants.FileExtensions.forms.contains(fileExt)

        var cancel = false
        var editorNavigationController: UIViewController?

        if isDocument || isForm {
            editorNavigationController = DEEditorNavigationController()
        } else if isSpreadsheet {
            editorNavigationController = SEEditorNavigationController()
        } else if isPresentation {
            editorNavigationController = PEEditorNavigationController()
        }

        guard let documentEditorNavigation = editorNavigationController as? DEEditorNavigationController ?? editorNavigationController as? SEEditorNavigationController ?? editorNavigationController as? PEEditorNavigationController else {
            handler?(.error, 1, ASCEditorManagerError(msg: NSLocalizedString("Could not open editor.", comment: "")), &cancel)
            return
        }

        openedFile = nil
        openedCopy = locallyEditing

        let password = UserDefaults.standard.object(forKey: ASCConstants.SettingsKeys.passwordOpenedDocument) as? String ?? ""
        var documentPermissions: String?

        // FillForms mode
        if isForm, fileExt == "oform" {
            documentPermissions = [
                "fillForms": true,
                "onDevice": true,
            ].jsonString()
        }

        var documentInfo = [
            "title": file.title,
            "viewMode": viewMode,
            "date": file.updated ?? Date(),
            "docUserId": UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString,
            "docUserName": file.updatedBy?.displayName ?? (UIDevice.current.name.count > 0
                ? UIDevice.current.name
                : NSLocalizedString("Me", comment: "If current user name is not set")),
            "autosave": true,
            "file": file.toJSONString()!,
            "locallyEditing": locallyEditing,
            "appFonts": editorFontsPaths,
            "dataFontsPath": dataFontsPath,
        ] as [String: Any]

        if let documentPermissions = documentPermissions {
            documentInfo += [
                "documentPermissions": documentPermissions,
            ]
        }

        if viewMode == false {
            UserDefaults.standard.set(documentInfo, forKey: ASCConstants.SettingsKeys.openedDocument)
        }

        if #available(iOS 13.0, *) {
            documentEditorNavigation.modalPresentationStyle = .fullScreen
        }

        documentEditorNavigation.modalTransitionStyle = .crossDissolve
        documentEditorNavigation.editorViewLoaded = { [weak navigationView = documentEditorNavigation] in
            navigationView?.editorController.documentInfo = documentInfo
        }

        let workDirectory = Path.userAutosavedInformation + file.title + "/"
        let loader = ASCDocumentLoader(path: workDirectory.rawValue)
        let document = ASCDocument()
        document.password = password
        document.backupPath = (Path.userAutosavedInformation + file.title + "/").rawValue

        document.loader = loader
        document.loader.options = ["autosave": autosave]
        document.load { [unowned self] status, progress, error in
            if let loadError = error as NSError? {
                log.error(loadError)
                handler?(.error, 1, error, &cancel)
            } else {
                if status == kASCDocumentSerializerBegin {
                    handler?(.begin, 1, error, &cancel)
                } else if status == kASCDocumentSerializerProgress {
                    handler?(.progress, progress, error, &cancel)
                } else if status == kASCDocumentSerializerEnd {
                    self.createEditorWindow()?.rootViewController?.present(documentEditorNavigation, animated: true, completion: {
                        DispatchQueue.main.async {
                            documentEditorNavigation.editorController.delegate = self
                            documentEditorNavigation.editorController.open(document)
                            self.openedFile = file
                            ASCAnalytics.logEvent(ASCConstants.Analytics.Event.openEditor, parameters: [
                                ASCAnalytics.Event.Key.portal: OnlyofficeApiClient.shared.baseURL?.absoluteString ?? ASCAnalytics.Event.Value.none,
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
                                ASCAnalytics.Event.Key.viewMode: viewMode,
                            ])
                            handler?(.end, 1, error, &cancel)
                        }
                    })
                }
            }
        }
    }

    func openEditorInCollaboration(file: ASCFile, viewMode: Bool = false, handler: ASCEditorManagerOpenHandler? = nil) {
        let title = file.title
        let fileExt = title.fileExtension().lowercased()
        let isDocument = (["docx"] + ASCConstants.FileExtensions.editorImportDocuments).contains(fileExt)
        let isSpreadsheet = (["xlsx"] + ASCConstants.FileExtensions.editorImportSpreadsheets).contains(fileExt)
        let isPresentation = (["pptx"] + ASCConstants.FileExtensions.editorImportPresentations).contains(fileExt)
        let isForm = ASCConstants.FileExtensions.forms.contains(fileExt)

        var cancel = false
        var editorNavigationController: UIViewController?

        if isDocument || isForm {
            editorNavigationController = DEEditorNavigationController()
        } else if isSpreadsheet {
            editorNavigationController = SEEditorNavigationController()
        } else if isPresentation {
            editorNavigationController = PEEditorNavigationController()
        }

        guard let documentEditorNavigation = editorNavigationController as? DEEditorNavigationController ?? editorNavigationController as? SEEditorNavigationController ?? editorNavigationController as? PEEditorNavigationController else {
            handler?(.error, 1, ASCEditorManagerError(msg: NSLocalizedString("Could not open editor.", comment: "")), &cancel)
            return
        }

        openedFile = nil

        guard
            let user = ASCFileManager.onlyofficeProvider?.user,
            let userId = user.userId,
            let userName = file.createdBy?.displayName ?? user.userName,
            let firstName = user.firstName,
            let lastName = user.lastName
        else {
            handler?(.error, 1, ASCEditorManagerError(msg: NSLocalizedString("Could not open editor.", comment: "")), &cancel)
            return
        }

        let sdkCheck = checkSDKVersion()

        var documentInfo: [String: Any] = [
            "title": file.title,
            "date": file.created!,
            "author": file.createdBy?.displayName ?? "",
            "viewMode": viewMode || !sdkCheck,
            "coauthoring": true,
            "docUserId": userId,
            "docUserName": userName,
            "docUserFirstName": firstName,
            "docUserLastName": lastName,
            "docKey": documentKeyForTrack ?? "",
            "docURL": documentURLForTrack ?? "",
            "docService": documentServiceURL ?? "",
            "documentToken": documentToken ?? "",
            "documentPermissions": documentPermissions ?? "",
            "documentCommonConfig": documentCommonConfig ?? "",
            "file": file.toJSONString()!,
            "sdkCheck": sdkCheck,
            "appFonts": editorFontsPaths,
            "dataFontsPath": dataFontsPath,
            "supportShare": true,
        ]

        // Enabling the Favorite function only on portals version 11 and higher
        if let communityServerVersion = OnlyofficeApiClient.shared.serverVersion,
           communityServerVersion.isVersion(greaterThanOrEqualTo: "11.0")
        {
            documentInfo["favorite"] = file.isFavorite
        }

        if !(viewMode || !sdkCheck) {
            UserDefaults.standard.set(documentInfo, forKey: ASCConstants.SettingsKeys.openedDocument)
        }

        if #available(iOS 13.0, *) {
            documentEditorNavigation.modalPresentationStyle = .fullScreen
        }

        documentEditorNavigation.modalTransitionStyle = .crossDissolve
        documentEditorNavigation.editorViewLoaded = { [weak navigationView = documentEditorNavigation] in
            navigationView?.editorController.documentInfo = documentInfo
        }

        let workDirectory = Path.userAutosavedInformation + file.title + "/"
        let mediaDirectory = workDirectory + "media"

        ASCLocalFileHelper.shared.removeDirectory(workDirectory)
        ASCLocalFileHelper.shared.createDirectory(workDirectory)
        ASCLocalFileHelper.shared.createDirectory(mediaDirectory)

        if workDirectory.exists, mediaDirectory.exists {
            let document = ASCDocument()
            document.loader = ASCDocumentLoader(path: workDirectory.rawValue)
            document.load { _, _, _ in }

            createEditorWindow()?.rootViewController?.present(documentEditorNavigation, animated: true, completion: {
                documentEditorNavigation.editorController.delegate = self
                documentEditorNavigation.editorController.open(document)
                self.openedFile = file
                self.provider = ASCFileManager.onlyofficeProvider

                ASCAnalytics.logEvent(ASCConstants.Analytics.Event.openEditor, parameters: [
                    ASCAnalytics.Event.Key.portal: OnlyofficeApiClient.shared.baseURL?.absoluteString ?? ASCAnalytics.Event.Value.none,
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
                    ASCAnalytics.Event.Key.viewMode: viewMode,
                ])
                handler?(.end, 1, nil, &cancel)
            })
        }
    }

    private func fetchDocumentInfo(_ file: ASCFile, viewMode: Bool = false, handler: @escaping (Bool, Error?) -> Void) {
        OnlyofficeApiClient.request(OnlyofficeAPI.Endpoints.Files.openEdit(file: file)) { response, error in
            if let config = response?.result {
                self.documentCommonConfig = config.jsonString()

                if let document = config["document"] as? [String: Any] {
                    self.documentKeyForTrack = document["key"] as? String
                    self.documentURLForTrack = document["url"] as? String
                    self.documentToken = config["token"] as? String ?? ""

                    if let permissions = document["permissions"] as? [String: Any] {
                        self.documentPermissions = permissions.jsonString() ?? ""

                        let allowEdit = (permissions["edit"] as? Bool) ?? false
                        let allowReview = (permissions["review"] as? Bool) ?? false
                        let allowComment = (permissions["comment"] as? Bool) ?? false
                        let allowFillForms = (permissions["fillForms"] as? Bool) ?? false

                        let canEdit = (allowEdit || (!allowEdit && (allowReview || allowComment || allowFillForms))) && !viewMode

                        if let _ = self.documentKeyForTrack, let _ = self.documentURLForTrack {
                            handler(canEdit, nil)
                            return
                        }
                    }
                }
                handler(false, ASCEditorManagerError(msg: NSLocalizedString("Failed to get file information from the server.", comment: "")))
            } else {
                handler(false, error)
            }
        }
    }

    public func fetchDocumentService(_ handler: @escaping (String?, String?, Error?) -> Void) {
        OnlyofficeApiClient.request(OnlyofficeAPI.Endpoints.Settings.documentService, ["version": "true"]) { response, error in

            let removePath = "/web-apps/apps/api/documents/api.js"

            if let results = response?.result as? String {
                if let url = OnlyofficeApiClient.absoluteUrl(from: URL(string: results)) {
                    let baseUrl = url.absoluteString.replacingOccurrences(of: removePath, with: "")

                    UserDefaults.standard.set(baseUrl, forKey: ASCConstants.SettingsKeys.collaborationService)
                    self.documentServiceURL = baseUrl

                    handler(baseUrl, "", nil)
                    return
                }
            }

            if let results = response?.result as? [String: Any] {
                if let docService = results["docServiceUrlApi"] as? String,
                   let version = results["version"] as? String
                {
                    UserDefaults.standard.set(version, forKey: ASCConstants.SettingsKeys.sdkVersion)

                    if let url = OnlyofficeApiClient.absoluteUrl(from: URL(string: docService)) {
                        let baseUrl = url.absoluteString.replacingOccurrences(of: removePath, with: "")

                        UserDefaults.standard.set(baseUrl, forKey: ASCConstants.SettingsKeys.collaborationService)
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

    private func convertToEdit(file: ASCFile, processing: ASCFileManagerConverterHandler? = nil) {
        let title = file.title
        let fileExtension = title.fileExtension().lowercased()

        if !ASCConstants.FileExtensions.allowEdit.contains(fileExtension) {
            processing?(.error, 1, ASCEditorManagerError(msg: NSLocalizedString("Unsupported format.", comment: "")), nil)
            return
        }

        let converter = DocumentLocalConverter()

        converter.fontsPaths = editorFontsPaths
        converter.dataFontsPath = dataFontsPath

        let outputPath = Path.userAutosavedInformation + title + "/"
        let tempPath = Path.userTemporary + UUID().uuidString

        do {
            try outputPath.createDirectory(withIntermediateDirectories: true)
            try tempPath.createDirectory(withIntermediateDirectories: true)
        } catch {
            processing?(.error, 1, ASCEditorManagerError(msg: NSLocalizedString("Couldn't open file", comment: "")), nil)
            ASCLocalFileHelper.shared.removeDirectory(tempPath)
            return
        }

        var conversionDirection = ConversionDirection.CD_ERROR

        switch fileExtension {
        case "docx", "doc", "rtf", "mht", "html", "htm", "epub", "fb2", "docxf", "oform":
            conversionDirection = ConversionDirection.CD_DOCX2DOCT_BIN
        case "xlsx", "xls":
            conversionDirection = ConversionDirection.CD_XSLX2XSLT_BIN
        case "pptx", "ppt":
            conversionDirection = ConversionDirection.CD_PPTX2PPTT_BIN
        case "csv":
            conversionDirection = ConversionDirection.CD_CSV2XLST_BIN
        case "txt":
            conversionDirection = ConversionDirection.CD_TXT2DOCT_BIN
        case "odt":
            conversionDirection = ConversionDirection.CD_ODT2DOCT_BIN
        case "ods":
            conversionDirection = ConversionDirection.CD_ODS2XSLT_BIN
        case "odp":
            conversionDirection = ConversionDirection.CD_ODP2PPTT_BIN
        default:
            conversionDirection = ConversionDirection.CD_ERROR
        }

        if conversionDirection == ConversionDirection.CD_ERROR {
            return
        }

        let options: [AnyHashable: Any] = [
            "Key": converterKey,
            "FileData": NSNull(),
            "FileFrom": file.id,
            "FileTo": (outputPath + "Editor.bin").rawValue,
            "ConversionDirection": NSNumber(value: conversionDirection.rawValue),
            "FontDir": dataFontsPath,
            "TempDir": tempPath.rawValue,
            "Async": false,
            "Password": openedFilePassword,
            "encoding": encoding ?? 0,
            "delimiter": delimiter ?? 0,
        ]

        UserDefaults.standard.set(openedFilePassword, forKey: ASCConstants.SettingsKeys.passwordOpenedDocument)

        if ["csv", "txt"].contains(fileExtension), encoding == nil, delimiter == nil {
            processing?(.silentError, 0, nil, "")

            alert.isOnlyCodePages = fileExtension == "txt"

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.33) {
                self.showConverterOptionsAlertAndEdit(file: file)
            }
        } else {
            converter.options = options

            openedFilePassword = ""
            encoding = nil
            delimiter = nil
        }

        DispatchQueue.global().async {
            converter.start { [weak self] status, progress, error in
                DispatchQueue.main.async {
                    if status == kDocumentLocalConverterBegin {
                        processing?(.begin, 0, error, outputPath.rawValue)
                    } else if status == kDocumentLocalConverterProgress {
                        processing?(.progress, progress, error, outputPath.rawValue)
                    } else if status == kDocumentLocalConverterEnd {
                        processing?(.end, 1, error, outputPath.rawValue)
                        ASCLocalFileHelper.shared.removeDirectory(tempPath)
                    } else if status == kDocumentLocalConverterError {
                        guard let strongSelf = self, let error = error as NSError? else { return }

                        if Int32(error.code) == kErrorPassword || Int32(error.code) == kErrorDRM {
                            processing?(.silentError, 1, error, outputPath.rawValue)
                            ASCLocalFileHelper.shared.removeDirectory(tempPath)

                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.33) {
                                strongSelf.showInputPasswordAlertAndEdit(file: file)
                            }
                        } else {
                            processing?(.error, 1, error, outputPath.rawValue)
                            ASCLocalFileHelper.shared.removeDirectory(tempPath)
                        }
                    }
                }
            }
        }
    }

    private func convertToSave(file: ASCFile, password: String = "", processing: ASCFileManagerConverterHandler? = nil) {
        let title = file.title
        let fileExtension = title.fileExtension().lowercased()

        if !ASCConstants.FileExtensions.allowEdit.contains(fileExtension) {
            processing?(.error, 1, ASCEditorManagerError(msg: NSLocalizedString("Unsupported format.", comment: "")), nil)
            return
        }

        let converter = DocumentLocalConverter()

        converter.fontsPaths = editorFontsPaths
        converter.dataFontsPath = dataFontsPath

        let inputPath = Path.userAutosavedInformation + title + "/"
        let tempPath = Path.userTemporary + UUID().uuidString

        do {
            try tempPath.createDirectory(withIntermediateDirectories: true)
        } catch {
            log.error("Save local file couldn't directory structure")
        }

        var fileTo = file.id

        var conversionDirection = ConversionDirection.CD_ERROR

        switch fileExtension {
        case "docx", "docxf", "oform":
            conversionDirection = ConversionDirection.CD_DOCT_BIN2DOCX
        case "xlsx":
            conversionDirection = ConversionDirection.CD_XSLT_BIN2XSLX
        case "pptx":
            conversionDirection = ConversionDirection.CD_PPTT_BIN2PPTX
        case "csv":
            conversionDirection = ConversionDirection.CD_XSLT_BIN2XSLX
            fileTo = resolvedFilePath.rawValue
        case "txt":
            conversionDirection = ConversionDirection.CD_DOCT_BIN2DOCX
            fileTo = resolvedFilePath.rawValue
        case "odt":
            conversionDirection = ConversionDirection.CD_DOCT_BIN2DOCX
            fileTo = resolvedFilePath.rawValue
        case "ods":
            conversionDirection = ConversionDirection.CD_XSLT_BIN2XSLX
            fileTo = resolvedFilePath.rawValue
        case "odp":
            conversionDirection = ConversionDirection.CD_PPTT_BIN2PPTX
            fileTo = resolvedFilePath.rawValue
        case "doc", "rtf", "mht", "html", "htm", "epub", "fb2":
            conversionDirection = ConversionDirection.CD_DOCT_BIN2DOCX
            fileTo = resolvedFilePath.rawValue
        case "xls":
            conversionDirection = ConversionDirection.CD_XSLT_BIN2XSLX
            fileTo = resolvedFilePath.rawValue
        case "ppt":
            conversionDirection = ConversionDirection.CD_PPTT_BIN2PPTX
            fileTo = resolvedFilePath.rawValue
        default:
            conversionDirection = ConversionDirection.CD_ERROR
        }

        converter.options = [
            "Key": converterKey,
            "FileData": NSNull(),
            "FileFrom": (inputPath + "Editor.bin").rawValue,
            "FileTo": fileTo,
            "ConversionDirection": NSNumber(value: conversionDirection.rawValue),
            "FontDir": dataFontsPath,
            "TempDir": tempPath.rawValue,
            "Async": false,
            "Password": password,
            "themesFolder": PEEditorViewController.themesFolder() ?? "",
        ]

        if !password.isEmpty {
            UserDefaults.standard.removeObject(forKey: ASCConstants.SettingsKeys.passwordOpenedDocument)
        }

        DispatchQueue.global().async {
            converter.start { status, progress, error in
                DispatchQueue.main.async {
                    if status == kDocumentLocalConverterBegin {
                        processing?(.begin, 0, error, file.id)
                    } else if status == kDocumentLocalConverterProgress {
                        processing?(.progress, progress, error, file.id)
                    } else if status == kDocumentLocalConverterEnd {
                        processing?(.end, 1, error, file.id)
                        ASCLocalFileHelper.shared.removeDirectory(tempPath)
                    } else if status == kDocumentLocalConverterError {
                        processing?(.error, 1, error, file.id)
                        ASCLocalFileHelper.shared.removeDirectory(tempPath)
                    }
                }
            }
        }
    }

    private func convertToExport(input path: String, output file: ASCFile, processing: ASCFileManagerConverterHandler? = nil) {
        let title = file.title
        let fileExt = title.fileExtension().lowercased()

        if !ASCConstants.FileExtensions.editorExportFormats.contains(fileExt) {
            processing?(.error, 1, ASCEditorManagerError(msg: NSLocalizedString("Unsupported format.", comment: "")), nil)
            return
        }

        let converter = DocumentLocalConverter()

        converter.fontsPaths = editorFontsPaths
        converter.dataFontsPath = dataFontsPath

        let inputPath = Path(path)
        let tempPath = Path.userTemporary + UUID().uuidString

        do {
            try tempPath.createDirectory(withIntermediateDirectories: true)
        } catch {
            log.error("Save local file couldn't directory structure")
        }

        var conversionDirection = ConversionDirection.CD_ERROR

        switch fileExt {
        case "docx", "docxf", "oform":
            conversionDirection = ConversionDirection.CD_DOCT_BIN2DOCX
        case "xlsx":
            conversionDirection = ConversionDirection.CD_XSLT_BIN2XSLX
        case "pptx":
            conversionDirection = ConversionDirection.CD_PPTT_BIN2PPTX
        case "odt":
            conversionDirection = ConversionDirection.CD_DOCT_BIN2ODT
        case "ods":
            conversionDirection = ConversionDirection.CD_XSLT_BIN2ODS
        case "odp":
            conversionDirection = ConversionDirection.CD_PPTT_BIN2ODP
        case "dotx":
            conversionDirection = ConversionDirection.CD_DOCT_BIN2DOTX
        case "xltx":
            conversionDirection = ConversionDirection.CD_XSLT_BIN2XLTX
        case "potx":
            conversionDirection = ConversionDirection.CD_PPTT_BIN2POTX
        case "ott":
            conversionDirection = ConversionDirection.CD_DOCT_BIN2OTT
        case "ots":
            conversionDirection = ConversionDirection.CD_XSLT_BIN2OTS
        case "otp":
            conversionDirection = ConversionDirection.CD_PPTT_BIN2OTP
        default:
            conversionDirection = ConversionDirection.CD_ERROR
        }

        converter.options = [
            "Key": converterKey,
            "FileData": NSNull(),
            "FileFrom": (inputPath + "Editor.bin").rawValue,
            "FileTo": file.id,
            "ConversionDirection": NSNumber(value: conversionDirection.rawValue),
            "FontDir": dataFontsPath,
            "TempDir": tempPath.rawValue,
            "Async": false,
        ]

        DispatchQueue.global().async {
            converter.start { status, progress, error in
                DispatchQueue.main.async {
                    if status == kDocumentLocalConverterBegin {
                        processing?(.begin, 0, error, file.id)
                    } else if status == kDocumentLocalConverterProgress {
                        processing?(.progress, progress, error, file.id)
                    } else if status == kDocumentLocalConverterEnd {
                        processing?(.end, 1, error, file.id)
                        ASCLocalFileHelper.shared.removeDirectory(tempPath)
                    } else if status == kDocumentLocalConverterError {
                        processing?(.error, 1, error, file.id)
                        ASCLocalFileHelper.shared.removeDirectory(tempPath)
                    }
                }
            }
        }
    }

    private func openChartEditor(_ controller: DEEditorViewController!, _ chartData: String) {
        let loader = ASCDocumentLoader(path: "")
        let document: ASCDocument! = ASCDocument()
        document.loader = loader

        let documentEditorNavigation = SEEditorNavigationController()

        if let editor = documentEditorNavigation.viewControllers.first as? SEEditorViewController {
            editor.documentInfo = [
                "viewMode": false,
                "chartEditor": true,
                "chartData": chartData,
                "appFonts": editorFontsPaths,
                "dataFontsPath": dataFontsPath,
            ]

            editor.delegate = self
            editor.editorViewLoaded = { editor.open(document) }

            controller.navigationController?.pushViewController(editor, animated: true)
        }
    }

    private func openChartEditor(_ controller: PEEditorViewController!, _ chartData: String) {
        let loader = ASCDocumentLoader(path: "")
        let document: ASCDocument! = ASCDocument()
        document.loader = loader

        let documentEditorNavigation = SEEditorNavigationController()

        if let editor = documentEditorNavigation.viewControllers.first as? SEEditorViewController {
            editor.documentInfo = [
                "viewMode": false,
                "chartEditor": true,
                "chartData": chartData,
                "appFonts": editorFontsPaths,
                "dataFontsPath": dataFontsPath,
            ]

            editor.delegate = self
            editor.editorViewLoaded = { editor.open(document) }

            controller.navigationController?.pushViewController(editor, animated: true)
        }
    }

    // MARK: - Local editing online files

    func editFileLocally(for provider: ASCFileProviderProtocol,
                         _ file: ASCFile,
                         viewMode: Bool,
                         handler: ASCEditorManagerOpenHandler? = nil,
                         closeHandler: ASCEditorManagerCloseHandler? = nil,
                         lockedHandler: ASCEditorManagerLockedHandler? = nil)
    {
        var cancel = false

        self.provider = provider
        openedlocallyFile = file
        self.closeHandler = nil
        openHandler = nil
        favoriteHandler = nil
        shareHandler = nil
        self.lockedHandler = lockedHandler

        if provider is ASCOnlyofficeProvider {
            fetchDocumentInfo(file, viewMode: viewMode, handler: { canEdit, error in
                if cancel {
                    handler?(.end, 1, nil, &cancel)
                    return
                }

                if error != nil {
                    handler?(.error, 1, error, &cancel)
                } else {
                    handler?(.progress, 0.1, nil, &cancel)

                    if cancel {
                        handler?(.end, 1, nil, &cancel)
                        return
                    }

                    self.closeHandler = closeHandler
                    self.openHandler = handler

                    if viewMode {
                        var cancel = false
                        self.downloadAndOpenFile(for: provider, file, viewMode, &cancel)
                    } else {
                        self.timer = Timer.scheduledTimer(timeInterval: 4,
                                                          target: self,
                                                          selector: #selector(ASCEditorManager.updateLocallyEditFile),
                                                          userInfo: file,
                                                          repeats: true)
                        self.timer?.fire()
                    }
                }
            })
        } else {
            self.closeHandler = closeHandler
            openHandler = handler

            downloadAndOpenFile(for: provider, file, viewMode, &cancel)
        }
    }

    private func stopLocallyEditing(_ clearHandlers: Bool = true) {
        provider = nil

        if timer != nil {
            if let file = openedlocallyFile {
                if let key = documentKeyForTrack {
                    OnlyofficeApiClient.request(
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
                trackingFileStatus = 0
            }
        }
    }

    func downloadAndOpenFile(for provider: ASCFileProviderProtocol, _ file: ASCFile, _ viewMode: Bool, _ cancel: inout Bool) {
        ASCEntityManager.shared.downloadTemp(for: provider, entity: file) { [unowned self] status, progress, result, error, cancel in
            if status == .begin {
                self.openHandler?(.progress, 0.1, nil, &cancel)
            }

            if status == .end || status == .error {
                if status == .error {
                    self.stopLocallyEditing()
                    self.openHandler?(.error, 1, nil, &cancel)
                } else {
                    self.openHandler?(.progress, 0.15, nil, &cancel)

                    if let newFile = result as? ASCFile {
                        self.provider = provider
                        self.editOnlineFileLocally(newFile, viewMode: viewMode)
                    } else {
                        self.stopLocallyEditing()
                        self.openHandler?(.error, 1, nil, &cancel)
                    }
                }
            } else if status == .progress {
                self.openHandler?(.progress, 0.1 + progress * 0.05, nil, &cancel)
            }
        }
    }

    @objc func updateLocallyEditFile(timer: Timer) {
        var cancel = false

        if let file = openedlocallyFile,
           let key = documentKeyForTrack
        {
            if trackingReadyForLocking == trackingFileStatus {
                OnlyofficeApiClient.request(
                    OnlyofficeAPI.Endpoints.Files.trackEdit(file: file), ["docKeyForTrack": key]
                ) { response, error in
                    if let error = error {
                        log.error(error)
                        self.openHandler?(.error, 1, error, &cancel)
                    }
                }
            } else {
                OnlyofficeApiClient.request(OnlyofficeAPI.Endpoints.Files.startEdit(file: file), ["editingAlone": "true"]) { response, error in
                    log.info("apiFileStartEdit")

                    if let error = error {
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
                        if let provider = ASCFileManager.onlyofficeProvider {
                            self.trackingFileStatus = self.trackingReadyForLocking
                            self.downloadAndOpenFile(for: provider, file, false, &cancel)
                        }
                    }
                }
            }
        }
    }

    func editOnlineFileLocally(_ file: ASCFile, viewMode: Bool = false) {
        var cancel = false

        openHandler?(.begin, 0.15, nil, &cancel)

        convertToEdit(file: file, processing: { status, progress, error, resultPath in
            if cancel {
                self.openHandler?(.end, 1, nil, &cancel)
                return
            }

            log.info("Local file convertering. Status: \(status)")
            self.openHandler?(.progress, 0.15 + progress * 0.75, error, &cancel)

            if status == .end {
                if cancel {
                    self.openHandler?(.end, 1, nil, &cancel)
                    return
                }

                let editorOpenHandler: ASCEditorManagerOpenHandler = { status, progress, error, cancel in
                    log.info("Local file open editor. Status: \(status), progress: \(progress), error: \(String(describing: error))")
                }

                self.openEditorLocal(file: file, viewMode: viewMode, locallyEditing: true, handler: editorOpenHandler)

                self.openHandler?(.end, 1, nil, &cancel)
            } else if status == .error {
                self.openHandler?(.error, 1, error, &cancel)
            } else if status == .silentError {
                self.openHandler?(.silentError, 1, error, &cancel)
            }
        })
    }

    func openEditorLocalCopy(file: ASCFile, viewMode: Bool = false, autosave: Bool = false, locallyEditing: Bool = false,
                             handler: ASCEditorManagerOpenHandler? = nil,
                             closeHandler: ASCEditorManagerCloseHandler? = nil)
    {
        self.closeHandler = closeHandler
        openEditorLocal(file: file, viewMode: viewMode, autosave: autosave, locallyEditing: locallyEditing, handler: handler)
    }

    // MARK: - Public

    func editLocal(
        _ file: ASCFile,
        viewMode: Bool = false,
        openHandler: ASCEditorManagerOpenHandler? = nil,
        closeHandler: ASCEditorManagerCloseHandler? = nil
    ) {
        var cancel = false

        openedFileInViewMode = viewMode

        openHandler?(.begin, 0.15, nil, &cancel)

        convertToEdit(file: file, processing: { status, progress, error, resultPath in
            if cancel {
                openHandler?(.end, 1, nil, &cancel)
                return
            }

            log.info("Local file convertering. Status: \(status)")
            openHandler?(.progress, progress, error, &cancel)

            if status == .end {
                if cancel {
                    openHandler?(.end, 1, nil, &cancel)
                    return
                }

                let editorOpenHandler: ASCEditorManagerOpenHandler = { status, progress, error, cancel in
                    log.info("Local file open editor. Status: \(status), progress: \(progress), error: \(String(describing: error))")
                }

                self.closeHandler = closeHandler
                self.openEditorLocal(file: file, viewMode: viewMode, handler: editorOpenHandler)

                openHandler?(.end, 1, nil, &cancel)
            } else if status == .error {
                openHandler?(.error, 1, error, &cancel)
            } else if status == .silentError {
                openHandler?(.silentError, 1, error, &cancel)
            }
        })
    }

    func editCloud(
        _ file: ASCFile,
        viewMode: Bool = false,
        handler: ASCEditorManagerOpenHandler? = nil,
        closeHandler: ASCEditorManagerCloseHandler? = nil,
        favoriteHandler: ASCEditorManagerFavoriteHandler? = nil,
        shareHandler: ASCEditorManagerShareHandler? = nil
    ) {
        var cancel = false

        self.closeHandler = nil
        self.favoriteHandler = nil
        self.shareHandler = nil

        func fetchAndOpen() {
            fetchDocumentInfo(file, viewMode: viewMode, handler: { canEdit, error in
                if cancel {
                    handler?(.end, 1, nil, &cancel)
                    return
                }

                if error != nil {
                    handler?(.error, 1, error, &cancel)
                } else {
                    handler?(.progress, 0.7, nil, &cancel)

                    if cancel {
                        handler?(.end, 1, nil, &cancel)
                        return
                    }

                    self.closeHandler = closeHandler
                    self.favoriteHandler = favoriteHandler
                    self.shareHandler = shareHandler
                    self.openEditorInCollaboration(file: file, viewMode: !canEdit, handler: handler)
                }
            })
        }

        handler?(.progress, 0.3, nil, &cancel)

        if let url = UserDefaults.standard.value(forKey: ASCConstants.SettingsKeys.collaborationService) as? String {
            documentServiceURL = url
            fetchAndOpen()
        } else {
            fetchDocumentService { url, version, error in
                if cancel {
                    handler?(.end, 1, nil, &cancel)
                    return
                }

                if error != nil {
                    handler?(.error, 1, error, &cancel)
                } else {
                    fetchAndOpen()
                }
            }
        }
    }

    func browsePdfLocal(_ pdf: ASCFile, handler: ASCEditorManagerOpenHandler? = nil) {
        var cancel = false

        openedFile = pdf

        handler?(.begin, 0, nil, &cancel)

        if pdf.device {
            ASCAnalytics.logEvent(ASCConstants.Analytics.Event.openPdf, parameters: [
                ASCAnalytics.Event.Key.portal: OnlyofficeApiClient.shared.baseURL?.absoluteString ?? ASCAnalytics.Event.Value.none,
                ASCAnalytics.Event.Key.onDevice: !pdf.id.contains(Path.userTemporary.rawValue),
            ])
            documentInteractionController = UIDocumentInteractionController(url: URL(fileURLWithPath: pdf.id))
            documentInteractionController?.uti = "com.adobe.pdf"
            documentInteractionController?.delegate = self
            documentInteractionController?.presentPreview(animated: true)
        }

        handler?(.end, 1, nil, &cancel)
    }

    func browsePdfCloud(for provider: ASCFileProviderProtocol, _ pdf: ASCFile, handler: ASCEditorManagerOpenHandler? = nil) {
        var cancel = false

        handler?(.begin, 0, nil, &cancel)

        if let viewUrl = pdf.viewUrl {
            let destination = Path.userTemporary + Path(pdf.title)
            provider.download(viewUrl, to: URL(fileURLWithPath: destination.rawValue)) { result, progress, error in
                if cancel {
                    provider.cancel()
                    handler?(.end, 1, nil, &cancel)
                    return
                }

                if error != nil {
                    handler?(.error, Float(progress), error, &cancel)
                } else if result != nil {
                    let localPdf = ASCFile()
                    localPdf.id = destination.rawValue
                    localPdf.title = pdf.title
                    localPdf.device = true

                    self.browsePdfLocal(localPdf)

                    handler?(.end, 1, nil, &cancel)
                } else {
                    handler?(.progress, Float(progress), error, &cancel)
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
                return (
                    (ASCConstants.FileExtensions.images.contains(fileExtension) ||
                        ASCConstants.FileExtensions.videos.contains(fileExtension)) &&
                        folderFile.title != file.title
                )
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
                    ASCAnalytics.Event.Key.portal: OnlyofficeApiClient.shared.baseURL?.absoluteString ?? ASCAnalytics.Event.Value.none,
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
                ASCAnalytics.Event.Key.portal: OnlyofficeApiClient.shared.baseURL?.absoluteString ?? ASCAnalytics.Event.Value.none,
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
            provider.download(viewUrl, to: URL(fileURLWithPath: destination.rawValue)) { result, progress, error in
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

    func convert(from srcFile: ASCFile, to dstFile: ASCFile, params: [String: Any]? = nil, processing: ASCFileManagerConverterHandler? = nil) {
        let srcExtension = srcFile.title.fileExtension().lowercased()
        let dstExtension = dstFile.title.fileExtension().lowercased()

        if !ASCConstants.FileExtensions.allowEdit.contains(srcExtension) {
            processing?(.error, 1, ASCEditorManagerError(msg: NSLocalizedString("Unsupported format.", comment: "")), nil)
            return
        }

        let converter = DocumentLocalConverter()

        converter.fontsPaths = editorFontsPaths
        converter.dataFontsPath = dataFontsPath

        let tempPath = Path.userTemporary + UUID().uuidString

        var options: [String: Any] = [:]

        var conversionDirection = ConversionDirection.CD_ERROR

        if srcExtension == "docx" {
            if dstExtension == "odt" {
                conversionDirection = ConversionDirection.CD_DOCXODT
            }
        } else if srcExtension == "xlsx" {
            if dstExtension == "ods" {
                conversionDirection = ConversionDirection.CD_XLSXODS
            }
        } else if srcExtension == "pptx" {
            if dstExtension == "odp" {
                conversionDirection = ConversionDirection.CD_PPTXODP
            }
        } else if srcExtension == "odt" {
            if dstExtension == "docx" {
                conversionDirection = ConversionDirection.CD_ODTDOCX
            }
        } else if srcExtension == "ods" {
            if dstExtension == "xlsx" {
                conversionDirection = ConversionDirection.CD_ODSXLSX
            }
        } else if srcExtension == "odp" {
            if dstExtension == "pptx" {
                conversionDirection = ConversionDirection.CD_ODPPPTX
            }
        } else if srcExtension == "csv" {
            if dstExtension == "xlsx" {
                conversionDirection = ConversionDirection.CD_CSV2XLSX

                if let params = params,
                   let encoding = params["encoding"] as? Int,
                   let delimiter = params["delimiter"] as? Int
                {
                    options += [
                        "encoding": encoding,
                        "delimiter": delimiter,
                    ]
                } else {
                    processing?(.silentError, 1, ASCEditorManagerError(msg: NSLocalizedString("Needs additional params.", comment: ""), type: .warning), nil)
                    return
                }
            }
        } else if srcExtension == "txt" {
            conversionDirection = ConversionDirection.CD_TXT2DOCX

            if let params = params,
               let encoding = params["encoding"] as? Int
            {
                options += [
                    "encoding": encoding,
                ]
            } else {
                processing?(.silentError, 1, ASCEditorManagerError(msg: NSLocalizedString("Needs additional params.", comment: ""), type: .warning), nil)
                return
            }
        }

        if conversionDirection == ConversionDirection.CD_ERROR {
            processing?(.error, 1, ASCEditorManagerError(msg: NSLocalizedString("Unsupported format.", comment: "")), nil)
            return
        }

        // Has password
        if let params = params, let password = params["password"] {
            options += [
                "Password": password,
            ]
        }

        options += [
            "Key": converterKey,
            "FileData": NSNull(),
            "FileFrom": srcFile.id,
            "FileTo": dstFile.id,
            "ConversionDirection": NSNumber(value: conversionDirection.rawValue),
            "FontDir": dataFontsPath,
            "TempDir": tempPath.rawValue,
            "Async": false,
        ]

        DispatchQueue.global().async {
            converter.start { status, progress, error in
                DispatchQueue.main.async {
                    if status == kDocumentLocalConverterBegin {
                        processing?(.begin, 0, error, dstFile.id)
                    } else if status == kDocumentLocalConverterProgress {
                        processing?(.progress, progress, error, dstFile.id)
                    } else if status == kDocumentLocalConverterEnd {
                        processing?(.end, 1, error, dstFile.id)
                        ASCLocalFileHelper.shared.removeDirectory(tempPath)
                    } else if status == kDocumentLocalConverterError {
                        if let error = error as NSError?, Int32(error.code) == kErrorPassword || Int32(error.code) == kErrorDRM {
                            processing?(.silentError, 1, error, dstFile.id)
                        } else {
                            processing?(.error, 1, error, dstFile.id)
                        }
                        ASCLocalFileHelper.shared.removeDirectory(tempPath)
                    }
                }
            }
        }
    }

    // MARK: - UIDocumentInteractionControllerDelegate

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

    // MARK: - DEEditorDelegate

    func documentLoading(_ controller: DEEditorViewController!, progress value: CGFloat) {
        log.info("DEEditorDelegate:documentLoading \(value)")

        if let file = openedFile, !file.device {
            OnlyofficeApiClient.request(OnlyofficeAPI.Endpoints.Files.startEdit(file: file)) { response, error in
                if let error = error {
                    log.error(error)
                }
            }
        }
    }

    func documentWorkCompleted(_ controller: DEEditorViewController!, document: DEDocument!) {
        log.info("DEEditorDelegate:documentWorkCompleted")

        cleanupEditorWindow()

        if let file = openedFile {
            var cancel = false

            if file.device {
                if document != nil {
                    /// Document changed

                    if openedlocallyFile == nil, openedCopy {
                        let copyFile = Path.userDocuments + Path(file.id).fileName
                        guard let dstPath = ASCLocalFileHelper.shared.resolve(filePath: copyFile) else {
                            closeHandler?(.error, 1, nil, nil, &cancel)
                            return
                        }

                        file.id = dstPath.rawValue

                    } else {
                        let fileExtension = file.title.fileExtension().lowercased()
                        if !ASCConstants.FileExtensions.editorImportDocuments.contains(fileExtension) {
                            /// Store original
                            _ = ASCLocalFileHelper.shared.move(from: Path(file.id), to: Path.userTemporary + file.title)
                        } else {
                            let fileTo = Path(Path(file.id).url.deletingPathExtension().path + ".docx")
                            guard let filePath = ASCLocalFileHelper.shared.resolve(filePath: fileTo) else {
                                closeHandler?(.error, 1, nil, nil, &cancel)
                                return
                            }

                            resolvedFilePath = filePath
                        }
                    }

                    convertToSave(file: file, password: document.password, processing: { status, progress, error, outputPath in
                        if status == .begin {
                            self.closeHandler?(.begin, 0, file, error, &cancel)
                        } else if status == .progress {
                            self.closeHandler?(.progress, progress, file, error, &cancel)
                        } else if status == .end {
                            let filePath = Path(file.id)

                            if let openedlocallyFile = self.openedlocallyFile, let provider = self.provider
                            {
                                // File is not original
                                let fileExtension = file.title.fileExtension().lowercased()
                                if ASCConstants.FileExtensions.editorImportDocuments.contains(fileExtension) {
                                    file.title = file.title.fileName() + ".docx"
                                    file.id = self.resolvedFilePath.rawValue
                                }

                                ASCEntityManager.shared.uploadEdit(
                                    for: provider,
                                    file: file,
                                    originalFile: openedlocallyFile,
                                    handler:
                                    { [unowned self] status, progress, result, error, cancel in
                                        if status == .begin {
                                            self.closeHandler?(.begin, 0, file, nil, &cancel)
                                        } else if status == .progress {
                                            self.closeHandler?(.progress, progress, file, nil, &cancel)
                                        } else if status == .end || status == .error {
                                            if status == .end {
                                                if let resultFile = result as? ASCFile {
                                                    self.closeHandler?(.end, 1, resultFile, nil, &cancel)
                                                } else {
                                                    self.closeHandler?(.end, 1, file, nil, &cancel)
                                                }
                                            } else {
                                                self.closeHandler?(.error, 1, file, nil, &cancel)
                                            }
                                            self.stopLocallyEditing()

                                            // Store backup
                                            if status == .error {
                                                // Backup on Device file
                                                let dateFormatter = DateFormatter()
                                                dateFormatter.dateFormat = "yyyyMMddHHmmss"

                                                let nowString = dateFormatter.string(from: Date())
                                                let backupPath = Path.userDocuments + Path("\(file.title.fileName())-Backup-\(nowString).\(file.title.fileExtension())")

                                                ASCLocalFileHelper.shared.copy(from: filePath,
                                                                               to: backupPath)
                                            }

                                            let lastTempFile = Path.userTemporary + file.title
                                            let autosaveFile = Path.userAutosavedInformation + file.title

                                            // Remove autosave
                                            ASCLocalFileHelper.shared.removeDirectory(lastTempFile)

                                            // Remove original
                                            ASCLocalFileHelper.shared.removeFile(autosaveFile)

                                            UserDefaults.standard.removeObject(forKey: ASCConstants.SettingsKeys.openedDocument)
                                            UserDefaults.standard.removeObject(forKey: ASCConstants.SettingsKeys.passwordOpenedDocument)
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
                                if ASCConstants.FileExtensions.editorImportDocuments.contains(fileExtension) {
                                    file.id = self.resolvedFilePath.rawValue
                                    file.title = file.title.fileName() + ".docx"

                                    let newFilePath = Path(file.id)
                                    file.created = newFilePath.creationDate
                                    file.updated = newFilePath.modificationDate
                                    file.displayContentLength = String.fileSizeToString(with: newFilePath.fileSize ?? 0)
                                    file.pureContentLength = Int(newFilePath.fileSize ?? 0)
                                }

                                self.closeHandler?(.end, 1, file, nil, &cancel)

                                // Remove autosave
                                ASCLocalFileHelper.shared.removeDirectory(Path.userTemporary + file.title)

                                // Remove original
                                ASCLocalFileHelper.shared.removeFile(Path.userAutosavedInformation + file.title)

                                UserDefaults.standard.removeObject(forKey: ASCConstants.SettingsKeys.openedDocument)
                                UserDefaults.standard.removeObject(forKey: ASCConstants.SettingsKeys.passwordOpenedDocument)
                            }

                        } else if status == .error {
                            self.closeHandler?(.error, 1, file, error, &cancel)

                            // Remove autosave
                            ASCLocalFileHelper.shared.removeDirectory(Path.userAutosavedInformation + file.title)

                            // Restore original
                            _ = ASCLocalFileHelper.shared.move(from: Path.userTemporary + file.title, to: Path(file.id))

                            UserDefaults.standard.removeObject(forKey: ASCConstants.SettingsKeys.openedDocument)
                            UserDefaults.standard.removeObject(forKey: ASCConstants.SettingsKeys.passwordOpenedDocument)
                        }
                    })
                } else {
                    stopLocallyEditing()

                    // No changes
                    ASCLocalFileHelper.shared.removeDirectory(Path.userAutosavedInformation + file.title)
                    closeHandler?(.end, 1, nil, nil, &cancel)

                    UserDefaults.standard.removeObject(forKey: ASCConstants.SettingsKeys.openedDocument)
                    UserDefaults.standard.removeObject(forKey: ASCConstants.SettingsKeys.passwordOpenedDocument)
                }
            } else {
                if let closeHandler = closeHandler {
                    closeHandler(.begin, 0, file, nil, &cancel)

                    ASCLocalFileHelper.shared.removeDirectory(Path.userAutosavedInformation + file.title)
                    UserDefaults.standard.removeObject(forKey: ASCConstants.SettingsKeys.openedDocument)
                    UserDefaults.standard.removeObject(forKey: ASCConstants.SettingsKeys.passwordOpenedDocument)

                    OnlyofficeApiClient.request(OnlyofficeAPI.Endpoints.Files.info(file: file)) { response, error in
                        if let newFile = response?.result {
                            closeHandler(.end, 1, newFile, nil, &cancel)
                        } else {
                            closeHandler(.error, 1, file, error, &cancel)
                        }
                    }
                }
            }

            openedFile = nil
        }
    }

    func documentExport(_ controller: DEEditorViewController!, document: DEDocument!, format: String!, processing: DEDocumentConverting!) {
        log.info("DEEditorDelegate:documentExport")

        if let file = openedFile {
            let tempExportPath = Path.userTemporary + UUID().uuidString

            let exportFile = ASCFile()
            exportFile.title = file.title.fileName() + "." + format
            exportFile.id = (tempExportPath + exportFile.title).rawValue

            do {
                try tempExportPath.createDirectory(withIntermediateDirectories: true)
            } catch {
                log.error("Export file couldn't create directory structure")
            }

            convertToExport(input: document.path, output: exportFile, processing: { status, progress, error, outputPath in
                if status == .begin {
                    processing("begin", 0, nil, nil)
                } else if status == .progress {
                    processing("progress", progress, nil, nil)
                } else if status == .end {
                    processing("end", 1, nil, exportFile.id)
                } else if status == .error {
                    processing("error", 1, ASCEditorManagerError(msg: NSLocalizedString("Could not convert file to export.", comment: "")), nil)
                }
            })
        }
    }

    func documentBackup(_ controller: DEEditorViewController!, document: DEDocument!) {
        log.info("DEEditorDelegate:documentBackup")

        if controller.isDocumentModifity {
            UserDefaults.standard.set(true, forKey: ASCConstants.SettingsKeys.openedDocumentModifity)
        }
    }

    func documentChartData(_ controller: DEEditorViewController!, data: String!) {
        openChartEditor(controller, data)
    }

    func documentEditorSettings(_ controller: DEEditorViewController!) -> [AnyHashable: Any]! {
        setenv("APPLICATION_NAME", ASCConstants.Name.appNameShort, 1)
        setenv("COMPANY_NAME", ASCConstants.Name.copyright, 1)

        return [
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

    func documentShare(_ complation: DEDocumentShareComplate!) {
        if let file = openedFile {
            shareHandler?(file)
        }
    }

    func documentFavorite(_ favorite: Bool, complation: DEDocumentFavoriteComplate!) {
        if let file = openedFile, let _ = favoriteHandler {
            favoriteHandler?(file) { favorite in
                self.openedFile?.isFavorite = favorite
                complation(favorite)
            }
        }
    }

    // MARK: - SEEditorDelegate

    func spreadsheetLoading(_ controller: SEEditorViewController!, progress value: CGFloat) {
        log.info("SEEditorDelegate:documentLoading \(value)")

        if let file = openedFile, !file.device {
            OnlyofficeApiClient.request(OnlyofficeAPI.Endpoints.Files.startEdit(file: file)) { response, error in
                if let error = error {
                    log.error(error)
                }
            }
        }
    }

    func spreadsheetWorkCompleted(_ controller: SEEditorViewController!, document: SEDocument!) {
        log.info("SEEditorDelegate:documentWorkCompleted")

        cleanupEditorWindow()

        if let file = openedFile {
            var cancel = false

            if file.device {
                // Save changes
                if document != nil {
                    if openedlocallyFile == nil, openedCopy {
                        let copyFile = Path.userDocuments + Path(file.id).fileName
                        guard let dstPath = ASCLocalFileHelper.shared.resolve(filePath: copyFile) else {
                            closeHandler?(.error, 1, nil, nil, &cancel)
                            return
                        }

                        file.id = dstPath.rawValue

                    } else {
                        let fileExtension = file.title.fileExtension().lowercased()
                        if !ASCConstants.FileExtensions.editorImportSpreadsheets.contains(fileExtension) {
                            // Store original
                            _ = ASCLocalFileHelper.shared.move(from: Path(file.id), to: Path.userTemporary + file.title)
                        } else {
                            let fileTo = Path(Path(file.id).url.deletingPathExtension().path + ".xlsx")
                            guard let filePath = ASCLocalFileHelper.shared.resolve(filePath: fileTo) else {
                                closeHandler?(.error, 1, nil, nil, &cancel)
                                return
                            }

                            resolvedFilePath = filePath
                        }
                    }

                    convertToSave(file: file, password: document.password, processing: { status, progress, error, outputPath in
                        if status == .begin {
                            self.closeHandler?(.begin, 0, file, error, &cancel)
                        } else if status == .progress {
                            self.closeHandler?(.progress, progress, file, error, &cancel)
                        } else if status == .end {
                            let filePath = Path(file.id)

                            if let openedlocallyFile = self.openedlocallyFile, let provider = self.provider {
                                // File is not original
                                let fileExtension = file.title.fileExtension().lowercased()
                                if ASCConstants.FileExtensions.editorImportSpreadsheets.contains(fileExtension) {
                                    file.title = file.title.fileName() + ".xlsx"
                                    file.id = self.resolvedFilePath.rawValue
                                }

                                ASCEntityManager.shared.uploadEdit(
                                    for: provider,
                                    file: file,
                                    originalFile: openedlocallyFile,
                                    handler:
                                    { [unowned self] status, progress, result, error, cancel in
                                        if status == .begin {
                                            self.closeHandler?(.begin, 0, file, nil, &cancel)
                                        } else if status == .progress {
                                            self.closeHandler?(.progress, progress, file, nil, &cancel)
                                        } else if status == .end || status == .error {
                                            if status == .end {
                                                if let resultFile = result as? ASCFile {
                                                    self.closeHandler?(.end, 1, resultFile, nil, &cancel)
                                                } else {
                                                    self.closeHandler?(.end, 1, file, nil, &cancel)
                                                }
                                            } else {
                                                self.closeHandler?(.error, 1, file, nil, &cancel)
                                            }
                                            self.stopLocallyEditing()

                                            // Store backup
                                            if status == .error {
                                                // Backup on Device file
                                                let dateFormatter = DateFormatter()
                                                dateFormatter.dateFormat = "yyyyMMddHHmmss"

                                                let nowString = dateFormatter.string(from: Date())
                                                let backupPath = Path.userDocuments + Path("\(file.title.fileName())-Backup-\(nowString).\(file.title.fileExtension())")

                                                ASCLocalFileHelper.shared.copy(from: filePath,
                                                                               to: backupPath)
                                            }

                                            let lastTempFile = Path.userTemporary + file.title
                                            let autosaveFile = Path.userAutosavedInformation + file.title

                                            // Remove autosave
                                            ASCLocalFileHelper.shared.removeDirectory(lastTempFile)

                                            // Remove original
                                            ASCLocalFileHelper.shared.removeFile(autosaveFile)

                                            UserDefaults.standard.removeObject(forKey: ASCConstants.SettingsKeys.openedDocument)
                                            UserDefaults.standard.removeObject(forKey: ASCConstants.SettingsKeys.passwordOpenedDocument)
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

                                let lastTempFile = Path.userTemporary + file.title
                                let autosaveFile = Path.userAutosavedInformation + file.title
                                let fileExtension = file.title.fileExtension().lowercased()

                                if ASCConstants.FileExtensions.editorImportSpreadsheets.contains(fileExtension) {
                                    file.id = self.resolvedFilePath.rawValue
                                    file.title = file.title.fileName() + ".xlsx"

                                    let newFilePath = Path(file.id)
                                    file.created = newFilePath.creationDate
                                    file.updated = newFilePath.modificationDate
                                    file.displayContentLength = String.fileSizeToString(with: newFilePath.fileSize ?? 0)
                                    file.pureContentLength = Int(newFilePath.fileSize ?? 0)
                                }

                                self.closeHandler?(.end, 1, file, nil, &cancel)

                                // Remove autosave
                                ASCLocalFileHelper.shared.removeDirectory(lastTempFile)

                                // Remove original
                                ASCLocalFileHelper.shared.removeFile(autosaveFile)

                                UserDefaults.standard.removeObject(forKey: ASCConstants.SettingsKeys.openedDocument)
                                UserDefaults.standard.removeObject(forKey: ASCConstants.SettingsKeys.passwordOpenedDocument)
                            }

                        } else if status == .error {
                            self.closeHandler?(.error, 1, file, error, &cancel)

                            // Remove autosave
                            ASCLocalFileHelper.shared.removeDirectory(Path.userAutosavedInformation + file.title)

                            // Restore original
                            _ = ASCLocalFileHelper.shared.move(from: Path.userTemporary + file.title, to: Path(file.id))

                            UserDefaults.standard.removeObject(forKey: ASCConstants.SettingsKeys.openedDocument)
                            UserDefaults.standard.removeObject(forKey: ASCConstants.SettingsKeys.passwordOpenedDocument)
                        }
                    })
                } else {
                    stopLocallyEditing()

                    // Don't save changes
                    ASCLocalFileHelper.shared.removeDirectory(Path.userAutosavedInformation + file.title)
                    closeHandler?(.end, 1, nil, nil, &cancel)

                    UserDefaults.standard.removeObject(forKey: ASCConstants.SettingsKeys.openedDocument)
                    UserDefaults.standard.removeObject(forKey: ASCConstants.SettingsKeys.passwordOpenedDocument)
                }
            } else {
                if let closeHandler = closeHandler {
                    closeHandler(.begin, 0, file, nil, &cancel)

                    UserDefaults.standard.removeObject(forKey: ASCConstants.SettingsKeys.openedDocument)
                    ASCLocalFileHelper.shared.removeDirectory(Path.userAutosavedInformation + file.title)

                    OnlyofficeApiClient.request(OnlyofficeAPI.Endpoints.Files.info(file: file)) { response, error in
                        if let newFile = response?.result {
                            closeHandler(.end, 1, newFile, nil, &cancel)
                        } else {
                            closeHandler(.error, 1, file, error, &cancel)
                        }
                    }
                }
            }

            openedFile = nil
        }
    }

    func spreadsheetExport(_ controller: SEEditorViewController!, document: SEDocument!, format: String!, processing: SEDocumentConverting!) {
        log.info("SEEditorDelegate:documentExport")

        if let file = openedFile {
            let tempExportPath = Path.userTemporary + UUID().uuidString

            let exportFile = ASCFile()
            exportFile.title = file.title.fileName() + "." + format
            exportFile.id = (tempExportPath + exportFile.title).rawValue

            do {
                try tempExportPath.createDirectory(withIntermediateDirectories: true)
            } catch {
                log.error("Export file couldn't create directory structure")
            }

            convertToExport(input: document.path, output: exportFile, processing: { status, progress, error, outputPath in
                if status == .begin {
                    processing("begin", 0, nil, nil)
                } else if status == .progress {
                    processing("progress", progress, nil, nil)
                } else if status == .end {
                    processing("end", 1, nil, exportFile.id)
                } else if status == .error {
                    processing("error", 1, ASCEditorManagerError(msg: NSLocalizedString("Could not convert file to export.", comment: "")), nil)
                }
            })
        }
    }

    func spreadsheetBackup(_ controller: SEEditorViewController!, document: SEDocument!) {
        if controller.isDocumentModifity {
            UserDefaults.standard.set(true, forKey: ASCConstants.SettingsKeys.openedDocumentModifity)
        }
    }

    func spreadsheetChartData(_ controller: SEEditorViewController!, data: String!) {
        if let n = controller.navigationController {
            if let documentController = n.viewControllers[0] as? DEEditorViewController {
                documentController.setChartData(data)
            }
            if let documentController = n.viewControllers[0] as? PEEditorViewController {
                documentController.setChartData(data)
            }
        }
    }

    func spreadsheetEditorSettings(_ controller: SEEditorViewController!) -> [AnyHashable: Any]! {
        setenv("APPLICATION_NAME", ASCConstants.Name.appNameShort, 1)
        setenv("COMPANY_NAME", ASCConstants.Name.copyright, 1)

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

    func spreadsheetShare(_ complation: SEDocumentShareComplate!) {
        if let file = openedFile {
            shareHandler?(file)
        }
    }

    func spreadsheetFavorite(_ favorite: Bool, complation: SEDocumentFavoriteComplate!) {
        if let file = openedFile, let _ = favoriteHandler {
            favoriteHandler?(file) { favorite in
                self.openedFile?.isFavorite = favorite
                complation(favorite)
            }
        }
    }

    // MARK: - PEEditorDelegate

    func presentationLoading(_ controller: PEEditorViewController!, progress value: CGFloat) {
        log.info("PEEditorDelegate:documentLoading \(value)")

        if let file = openedFile, !file.device {
            OnlyofficeApiClient.request(OnlyofficeAPI.Endpoints.Files.startEdit(file: file)) { response, error in
                if let error = error {
                    log.error(error)
                }
            }
        }
    }

    func presentationWorkCompleted(_ controller: PEEditorViewController!, document: PEDocument!) {
        log.info("PEEditorDelegate:documentWorkCompleted")

        cleanupEditorWindow()

        if let file = openedFile {
            var cancel = false

            if file.device {
                // Save changes
                if document != nil {
                    if openedlocallyFile == nil, openedCopy {
                        let copyFile = Path.userDocuments + Path(file.id).fileName
                        guard let dstPath = ASCLocalFileHelper.shared.resolve(filePath: copyFile) else {
                            closeHandler?(.error, 1, nil, nil, &cancel)
                            return
                        }

                        file.id = dstPath.rawValue

                    } else {
                        let fileExtension = file.title.fileExtension().lowercased()
                        if !ASCConstants.FileExtensions.editorImportPresentations.contains(fileExtension) {
                            // Store original
                            _ = ASCLocalFileHelper.shared.move(from: Path(file.id), to: Path.userTemporary + file.title)
                        } else {
                            let fileTo = Path(Path(file.id).url.deletingPathExtension().path + ".pptx")
                            guard let filePath = ASCLocalFileHelper.shared.resolve(filePath: fileTo) else {
                                closeHandler?(.error, 1, nil, nil, &cancel)
                                return
                            }

                            resolvedFilePath = filePath
                        }
                    }

                    convertToSave(file: file, password: document.password, processing: { status, progress, error, outputPath in
                        if status == .begin {
                            self.closeHandler?(.begin, 0, file, error, &cancel)
                        } else if status == .progress {
                            self.closeHandler?(.progress, progress, file, error, &cancel)
                        } else if status == .end {
                            let filePath = Path(file.id)

                            if let openedlocallyFile = self.openedlocallyFile, let provider = self.provider {
                                // File is not original
                                let fileExtension = file.title.fileExtension().lowercased()
                                if ASCConstants.FileExtensions.editorImportPresentations.contains(fileExtension) {
                                    file.title = file.title.fileName() + ".pptx"
                                    file.id = self.resolvedFilePath.rawValue
                                }

                                ASCEntityManager.shared.uploadEdit(
                                    for: provider,
                                    file: file,
                                    originalFile: openedlocallyFile,
                                    handler:
                                    { [unowned self] status, progress, result, error, cancel in
                                        if status == .begin {
                                            self.closeHandler?(.begin, 0, file, nil, &cancel)
                                        } else if status == .progress {
                                            self.closeHandler?(.progress, progress, file, nil, &cancel)
                                        } else if status == .end || status == .error {
                                            if status == .end {
                                                if let resultFile = result as? ASCFile {
                                                    self.closeHandler?(.end, 1, resultFile, nil, &cancel)
                                                } else {
                                                    self.closeHandler?(.end, 1, file, nil, &cancel)
                                                }
                                            } else {
                                                self.closeHandler?(.error, 1, file, nil, &cancel)
                                            }
                                            self.stopLocallyEditing()

                                            // Store backup
                                            if status == .error {
                                                // Backup on Device file
                                                let dateFormatter = DateFormatter()
                                                dateFormatter.dateFormat = "yyyyMMddHHmmss"

                                                let nowString = dateFormatter.string(from: Date())
                                                let backupPath = Path.userDocuments + Path("\(file.title.fileName())-Backup-\(nowString).\(file.title.fileExtension())")

                                                ASCLocalFileHelper.shared.copy(from: filePath,
                                                                               to: backupPath)
                                            }

                                            let lastTempFile = Path.userTemporary + file.title
                                            let autosaveFile = Path.userAutosavedInformation + file.title

                                            // Remove autosave
                                            ASCLocalFileHelper.shared.removeDirectory(lastTempFile)

                                            // Remove original
                                            ASCLocalFileHelper.shared.removeFile(autosaveFile)

                                            UserDefaults.standard.removeObject(forKey: ASCConstants.SettingsKeys.openedDocument)
                                            UserDefaults.standard.removeObject(forKey: ASCConstants.SettingsKeys.passwordOpenedDocument)
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
                                let lastTempFile = Path.userTemporary + file.title
                                let autosaveFile = Path.userAutosavedInformation + file.title

                                if ASCConstants.FileExtensions.editorImportPresentations.contains(fileExtension) {
                                    file.id = self.resolvedFilePath.rawValue
                                    file.title = file.title.fileName() + ".pptx"

                                    let newFilePath = Path(file.id)
                                    file.created = newFilePath.creationDate
                                    file.updated = newFilePath.modificationDate
                                    file.displayContentLength = String.fileSizeToString(with: newFilePath.fileSize ?? 0)
                                    file.pureContentLength = Int(newFilePath.fileSize ?? 0)
                                }

                                self.closeHandler?(.end, 1, file, nil, &cancel)

                                // Remove autosave
                                ASCLocalFileHelper.shared.removeDirectory(lastTempFile)

                                // Remove original
                                ASCLocalFileHelper.shared.removeFile(autosaveFile)

                                UserDefaults.standard.removeObject(forKey: ASCConstants.SettingsKeys.openedDocument)
                                UserDefaults.standard.removeObject(forKey: ASCConstants.SettingsKeys.passwordOpenedDocument)
                            }

                        } else if status == .error {
                            self.closeHandler?(.error, 1, file, error, &cancel)

                            // Remove autosave
                            ASCLocalFileHelper.shared.removeDirectory(Path.userAutosavedInformation + file.title)

                            // Restore original
                            _ = ASCLocalFileHelper.shared.move(from: Path.userTemporary + file.title, to: Path(file.id))

                            UserDefaults.standard.removeObject(forKey: ASCConstants.SettingsKeys.openedDocument)
                            UserDefaults.standard.removeObject(forKey: ASCConstants.SettingsKeys.passwordOpenedDocument)
                        }
                    })
                } else {
                    stopLocallyEditing()

                    // Don't save changes
                    ASCLocalFileHelper.shared.removeDirectory(Path.userAutosavedInformation + file.title)
                    closeHandler?(.end, 1, nil, nil, &cancel)

                    UserDefaults.standard.removeObject(forKey: ASCConstants.SettingsKeys.openedDocument)
                    UserDefaults.standard.removeObject(forKey: ASCConstants.SettingsKeys.passwordOpenedDocument)
                }
            } else {
                if let closeHandler = closeHandler {
                    closeHandler(.begin, 0, file, nil, &cancel)

                    UserDefaults.standard.removeObject(forKey: ASCConstants.SettingsKeys.openedDocument)
                    ASCLocalFileHelper.shared.removeDirectory(Path.userAutosavedInformation + file.title)

                    OnlyofficeApiClient.request(OnlyofficeAPI.Endpoints.Files.info(file: file)) { response, error in
                        if let newFile = response?.result {
                            closeHandler(.end, 1, newFile, nil, &cancel)
                        } else {
                            closeHandler(.error, 1, file, error, &cancel)
                        }
                    }
                }
            }

            openedFile = nil
        }
    }

    func presentationExport(_ controller: PEEditorViewController!, document: PEDocument!, format: String!, processing: PEDocumentConverting!) {
        log.info("PEEditorDelegate:presentationExport")

        if let file = openedFile {
            let tempExportPath = Path.userTemporary + UUID().uuidString

            let exportFile = ASCFile()
            exportFile.title = file.title.fileName() + "." + format
            exportFile.id = (tempExportPath + exportFile.title).rawValue

            do {
                try tempExportPath.createDirectory(withIntermediateDirectories: true)
            } catch {
                log.error("Export file couldn't create directory structure")
            }

            convertToExport(input: document.path, output: exportFile, processing: { status, progress, error, outputPath in
                if status == .begin {
                    processing("begin", 0, nil, nil)
                } else if status == .progress {
                    processing("progress", progress, nil, nil)
                } else if status == .end {
                    processing("end", 1, nil, exportFile.id)
                } else if status == .error {
                    processing("error", 1, ASCEditorManagerError(msg: NSLocalizedString("Could not convert file to export.", comment: "")), nil)
                }
            })
        }
    }

    func presentationBackup(_ controller: PEEditorViewController!, document: PEDocument!) {
        log.info("PEEditorDelegate:presentationBackup")

        if controller.isDocumentModifity {
            UserDefaults.standard.set(true, forKey: ASCConstants.SettingsKeys.openedDocumentModifity)
        }
    }

    func presentationChartData(_ controller: PEEditorViewController!, data: String!) {
        openChartEditor(controller, data)
    }

    func presentationEditorSettings(_ controller: PEEditorViewController!) -> [AnyHashable: Any]! {
        setenv("APPLICATION_NAME", ASCConstants.Name.appNameShort, 1)
        setenv("COMPANY_NAME", ASCConstants.Name.copyright, 1)

        return [
            "asc.pe.external.appname": ASCConstants.Name.appNameShort,
            "asc.pe.external.helpurl": "https://helpcenter.onlyoffice.com/%@%@mobile-applications/documents/presentation-editor/index.aspx",
        ]
    }

    func presentationShare(_ complation: PEDocumentShareComplate!) {
        if let file = openedFile {
            shareHandler?(file)
        }
    }

    func presentationFavorite(_ favorite: Bool, complation: PEDocumentFavoriteComplate!) {
        if let file = openedFile, let _ = favoriteHandler {
            favoriteHandler?(file) { favorite in
                self.openedFile?.isFavorite = favorite
                complation(favorite)
            }
        }
    }

    // MARK: - Utils

    func checkSDKVersion() -> Bool {
        if let version = UserDefaults.standard.value(forKey: ASCConstants.SettingsKeys.sdkVersion) as? String {
            let webSDK = version.components(separatedBy: ".")
            let localSDK = localSDKVersion()

            let allowCoauthoring = ASCConstants.remoteConfigValue(forKey: ASCConstants.RemoteSettingsKeys.allowCoauthoring)?.boolValue ?? true
            let checkSdkFully = ASCConstants.remoteConfigValue(forKey: ASCConstants.RemoteSettingsKeys.checkSdkFully)?.boolValue ?? true

            if !allowCoauthoring {
                return false
            }

            var maxVersionIndex = 2

            if !checkSdkFully {
                maxVersionIndex = 1
            }

            if localSDK.count > maxVersionIndex, webSDK.count > maxVersionIndex {
                for i in 0 ... maxVersionIndex {
                    if localSDK[i] != webSDK[i] {
                        return false
                    }
                }
                return true
            }
        }
        return false
    }

    func localSDKVersion() -> [String] {
        if let sdkVersion = DocumentEditor.DEEditorViewController().sdkVersion() {
            log.info("SDK Version:", sdkVersion)
            return sdkVersion.components(separatedBy: ".")
        }
        return []
    }

    // MARK: - Dialog Utils

    func showInputPasswordAlertAndEdit(file: ASCFile) {
        showInputPasswordAlert(for: file) { [weak self] password in
            guard let strongSelf = self else { return }

            if let password = password {
                var documentsVC: ASCDocumentsViewController?

                if let splitVC = UIApplication.topViewController() as? ASCBaseSplitViewController {
                    if splitVC.viewControllers.count > 1 {
                        if let documentsNC = splitVC.viewControllers.last as? ASCDocumentsNavigationController {
                            documentsVC = documentsNC.viewControllers.first as? ASCDocumentsViewController
                        }
                    } else {
                        documentsVC = ASCViewControllerManager.shared.rootController?.topMostViewController() as? ASCDocumentsViewController
                    }

                    if let documentsVC = documentsVC {
                        let openHandler = documentsVC.openProgress(
                            file: file,
                            title: NSLocalizedString("Processing", comment: "Caption of the processing") + "...",
                            0.15
                        )
                        let closeHandler = documentsVC.closeProgress(
                            file: file,
                            title: NSLocalizedString("Saving", comment: "Caption of the processing")
                        )

                        strongSelf.openedFilePassword = password
                        strongSelf.editLocal(
                            file,
                            viewMode: strongSelf.openedFileInViewMode,
                            openHandler: openHandler,
                            closeHandler: closeHandler
                        )
                    }
                }
            }
        }
    }

    func showInputPasswordAlert(for file: ASCFile, handler: @escaping (_ password: String?) -> Void) {
        let alertController = UIAlertController(
            title: NSLocalizedString("Protected File", comment: ""),
            message: file.device ? nil : NSLocalizedString("Once you enter the password and open the file, the current password to the file will be reset", comment: ""),
            preferredStyle: .alert,
            tintColor: nil
        )

        let cancelAction = UIAlertAction(title: ASCLocalization.Common.cancel, style: .cancel) { action in
            if let textField = alertController.textFields?.first {
                textField.selectedTextRange = nil
            }
            handler(nil)
        }

        let createAction = UIAlertAction(title: ASCLocalization.Common.ok) { action in
            if let textField = alertController.textFields?.first,
               let password = textField.text,
               password.length > 0
            {
                handler(password)
            } else {
                handler(nil)
            }
        }

        alertController.addAction(cancelAction)
        alertController.addAction(createAction)
        createAction.isEnabled = false
        alertController.addTextField { textField in
            textField.delegate = self
            textField.text = ""
            textField.isSecureTextEntry = true

            textField.add(for: .editingChanged) {
                createAction.isEnabled = (textField.text?.length)! > 0
            }

            delay(seconds: 0.2) {
                textField.selectAll(nil)
            }
        }

        if let topVC = ASCViewControllerManager.shared.topViewController {
            topVC.present(alertController, animated: true, completion: nil)
        }
    }

    func showConverterOptionsAlertAndEdit(file: ASCFile) {
        showConverterOptionsAlert { [weak self] encoding, delimiter in
            guard let strongSelf = self else { return }

            var documentsVC: ASCDocumentsViewController?

            if let splitVC = UIApplication.topViewController() as? ASCBaseSplitViewController {
                if splitVC.viewControllers.count > 1 {
                    if let documentsNC = splitVC.viewControllers.last as? ASCDocumentsNavigationController {
                        documentsVC = documentsNC.viewControllers.first as? ASCDocumentsViewController
                    }
                } else {
                    if let documentsNC = splitVC.viewControllers.first as? ASCBaseNavigationController {
                        documentsVC = documentsNC.viewControllers.last as? ASCDocumentsViewController
                    }
                }

                if let documentsVC = documentsVC {
                    let openHandler = documentsVC.openProgress(file: file, title: NSLocalizedString("Processing", comment: "Caption of the processing") + "...", 0.15)
                    let closeHandler = documentsVC.closeProgress(file: file, title: NSLocalizedString("Saving", comment: "Caption of the processing"))

                    strongSelf.encoding = encoding
                    strongSelf.delimiter = delimiter + 1

                    strongSelf.editLocal(file, viewMode: strongSelf.openedFileInViewMode, openHandler: openHandler, closeHandler: closeHandler)
                }
            }
        }
    }

    func showConverterOptionsAlert(handler: @escaping (_ encoding: Int, _ delimiter: Int) -> Void) {
        alert.show { encoding, delimiter in
            handler(encoding, delimiter)
        }
    }

    // MARK: - UITextField Delegate

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField.isFirstResponder {
            if let primaryLanguage = textField.textInputMode?.primaryLanguage, primaryLanguage == "emoji" {
                return false
            }
        }

        if let nsString = textField.text as NSString? {
            var newString = nsString.replacingCharacters(in: range, with: string)
            let newStringLenght = newString.length

            if newStringLenght < 1 {
                return true
            }

            if !textField.isSecureTextEntry {
                newString = newString.trimmingCharacters(in: CharacterSet(charactersIn: String.invalidTitleChars))
            }

            if newStringLenght != newString.length {
                return false
            }

            return true
        }

        return false
    }
}
