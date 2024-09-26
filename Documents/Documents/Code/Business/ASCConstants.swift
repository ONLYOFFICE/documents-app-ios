//
//  ASCConstants.swift
//  Documents
//
//  Created by Alexander Yuzhin on 3/17/17.
//  Copyright © 2017 Ascensio System SIA. All rights reserved.
//

import FirebaseRemoteConfig
import Foundation
import UIKit

class ASCConstants {
    enum Name {
        static let appNameShort = NSLocalizedString("ONLYOFFICE", comment: "Short App Name")
        static let appNameFull = NSLocalizedString("ONLYOFFICE Documents", comment: "Full App Name")
        static let copyright = String(format: NSLocalizedString("© Ascensio System SIA %d", comment: ""), Calendar.current.component(.year, from: Date()))
        static let brendPortalName = NSLocalizedString("ONLYOFFICE portal", comment: "Full App Name")
    }

    enum Keys {
        static let portalRegistration = ASCConstants.internalConstants["KeysPortalRegistration"] as? String ?? ""
        static let recaptcha = ASCConstants.internalConstants["ReCaptcha"] as? String ?? ""
        static let recaptchaInfo = ASCConstants.internalConstants["ReCaptchaInfo"] as? String ?? ""
        static let licenseName = "F8D434904F7142C49EB3E4CD738CFE01"
    }

    enum Urls {
        static let personalPortals = ["://personal.onlyoffice.com", "://personal.teamlab.info"]
        static let apiSystemUrl = "https://api-system.%@"
        static let apiValidatePortalName = "apisystem/portal/validateportalname"
        static let apiRegistrationPortal = "apisystem/portal/register"
        static let apiForgetPassword = "%@/auth.aspx#passrecovery"
        static let supportMailTo = "support@onlyoffice.com"
        static let legalTerms = "https://www.onlyoffice.com/legalterms.aspx"
        static let applicationPage = "https://www.onlyoffice.com/mobile.aspx"
        static let applicationFeedbackForum = "https://cloud.onlyoffice.org/viewforum.php?f=48"
        static let appReview = "itms-apps://itunes.apple.com/app/id944896972?action=write-review"
        static let appStoreGoogleAuth = "https://itunes.apple.com/app/id388497605"
        static let help2authByApp = "https://helpcenter.onlyoffice.com/guides/two-factor-authentication.aspx#step4"
        static let documentServiceDomain = ASCConstants.internalConstants["UrlsDocumentServiceDomain"] as? String ?? ""
        static let portalUserAccessRightsPath = "Management.aspx?type=4"
    }

    enum SettingsKeys {
        static let sortDocuments = "asc-sort-documents"
        static let collaborationService = "asc-collaboration-service"
        static let appVersion = "asc-documents-version"
        static let lastFolder = "asc-last-folder"
        static let compressImage = "asc-settings-compress-image"
        static let previewFiles = "asc-settings-preview-files"
        static let allowTouchId = "asc-settings-allow-touchid"
        static let forceCreateNewDocument = "asc-shortcut-new-document"
        static let forceCreateNewSpreadsheet = "asc-shortcut-new-spreadsheet"
        static let forceCreateNewPresentation = "asc-shortcut-new-presentation"
        static let openedDocumentFile = "asc-opened-document-file"
        static let openedDocumentModified = "asc-opened-document-modified"
        static let pushAllow = "asc-push-allow"
        static let pushDeviceToken = "asc-push-device-token"
        static let pushFCMToken = "asc-push-fcm-token"
        static let pushUserInfo = "asc-push-user-info"
        static let sdkVersion = "asc-sdk-version"
        static let lastCloudIndex = "asc-last-cloud-index"
        static let pushAllNotification = "asc-push-all"
        static let appTheme = "asc-app-theme"
        static let gridLayoutFiles = "asc-grid-layout-files"
        static let hideCloudsCategory = "asc-hide-clouds-category"

        // Debug
        static let debugAllowiCloud = "asc-debug-allowicloud"
        static let debugAllowCategoriesSkeleton = "asc-debug-allowcategoriesskeleton"
        static let debugDropboxSDKLogin = "asc-debug-dropboxsdklogin"
        static let debugOpenEditorViewModeDefault = "asc-debug-openeditorviewmodedefault"
        static let debugDisableSdkVersionCheck = "asc-debug-disablesdkversioncheck"

        static func setupDefaults() {
            UserDefaults.standard.register(defaults: [ASCConstants.SettingsKeys.compressImage: true])
            UserDefaults.standard.register(defaults: [ASCConstants.SettingsKeys.allowTouchId: true])
            UserDefaults.standard.register(defaults: [ASCConstants.SettingsKeys.previewFiles: true])
            UserDefaults.standard.register(defaults: [ASCConstants.SettingsKeys.pushAllNotification: true])

            // Debug
            UserDefaults.standard.register(defaults: [ASCConstants.SettingsKeys.debugAllowiCloud: true])
            UserDefaults.standard.register(defaults: [ASCConstants.SettingsKeys.debugAllowCategoriesSkeleton: false])
            UserDefaults.standard.register(defaults: [ASCConstants.SettingsKeys.debugDropboxSDKLogin: true])
            UserDefaults.standard.register(defaults: [ASCConstants.SettingsKeys.debugOpenEditorViewModeDefault: true])
        }
    }

    enum Keychain {
        static let group = ASCConstants.internalConstants["KeychainGroup"] as? String ?? ""
        static let keyAccounts = "asc-accounts"
        static let keyProviders = "asc-providers"
        static let keyLastProviderId = "asc-provider-id"
    }

    enum RemoteSettingsKeys {
        static let allowCoauthoring = "allow_coauthoring"
        static let checkSdkFully = "check_sdk_fully"
        static let recaptchaForPortalRegistration = "recaptcha_for_portal_registration"
        static let privacyPolicyLink = "link_privacy_policy"
        static let termsOfServiceLink = "link_terms_of_service"

        static func setupDefaults() {
            let defaultValues: [String: NSObject] = [
                allowCoauthoring: NSNumber(value: true),
                checkSdkFully: NSNumber(value: true),
                recaptchaForPortalRegistration: NSNumber(value: true),
                privacyPolicyLink: NSString(string: "https://help.onlyoffice.com/products/files/doceditor.aspx?fileid=5048502&doc=SXhWMEVzSEYxNlVVaXJJeUVtS0kyYk14YWdXTEFUQmRWL250NllHNUFGbz0_IjUwNDg1MDIi0"),
                termsOfServiceLink: NSString(string: "https://help.onlyoffice.com/products/files/doceditor.aspx?fileid=5048471&doc=bXJ6UmJacDVnVDMxV01oMHhrUlpwaGFBcXJUUUE3VHRuTGZrRUF5a1NKVT0_IjUwNDg0NzEi0"),
            ]

            #if !OPEN_SOURCE
                RemoteConfig.remoteConfig().setDefaults(defaultValues)
                fetchRemoteConfig()
            #endif
        }
    }

    enum Analytics {
        enum Event {
            static let createPortal = "portal_create"
            static let loginPortal = "portal_login"
            static let switchAccount = "account_switch"
            static let openEditor = "open_editor"
            static let openPdf = "open_pdf"
            static let openMedia = "open_media"
            static let openExternal = "open_external"
            static let createEntity = "create_entity"
        }

        static var allow: Bool {
            guard let allow = UserDefaults.standard.object(forKey: "share_analytics") as? Bool else {
                return true
            }
            return allow
        }
    }

    enum Shortcuts {
        static let newDocument = "asc-shortcut-new-document"
        static let newSpreadsheet = "asc-shortcut-new-spreadsheet"
        static let newPresentation = "asc-shortcut-new-presentation"
    }

    enum Notifications {
        static let loginOnlyofficeCompleted = Notification.Name("ASCEventOnlyofficeLogInCompleted")
        static let logoutOnlyofficeCompleted = Notification.Name("ASCEventOnlyofficeLogOutCompleted")
        static let userInfoOnlyofficeUpdate = Notification.Name("ASCEventUserInfoOnlyofficeUpdate")
        static let shortcutLaunch = Notification.Name("ASCEventShortcutLaunch")
        static let networkStatusChanged = Notification.Name("ASCEventNetworkStatusChanged")
        static let updateFileInfo = Notification.Name("ASCEventUpdateFileInfo")
        static let updateSizeClass = Notification.Name("ASCEventUpdateSizeClass")
        static let appDidBecomeActive = Notification.Name("ASCEventAppDidBecomeActive")
        static let pushInfo = Notification.Name("ASCEventPushInfo")
        static let reloadData = Notification.Name("ASCEventReloadData")
        static let updateDocumentsViewLayoutType = Notification.Name("ASCEventUpdateDocumentsViewLayoutType")
    }

    enum FileExtensions {
        static let documents = ["docx", "doc", "odt", "rtf", "mht", "html", "htm", "epub", "fb2", "txt"]
        static let spreadsheets = ["xlsx", "xls", "csv", "ods"]
        static let presentations = ["pptx", "ppt", "odp"]
        static let formTemplates = ["docxf"]
        static let forms = ["docxf", "oform"]
        static let images = ["jpg", "jpeg", "png", "gif", "bmp", "tif", "tiff", "ico"]
        static let videos = ["mpg", "mpeg", "mpg4", "mp4", "m4v", "mov", "avi", "vfw", "m75", "m15", "3g2", "3gp2", "3gp", "3gpp"]
        static let archives = ["zip", "tar", "gz"]
        static let allowEdit = ["docx", "xlsx", "pptx", "csv", "txt", "odt", "ods", "odp", "doc", "xls", "ppt", "rtf", "mht", "html", "htm", "epub", "fb2", "docxf", "oform"]
        static let editorImportDocuments = ["doc", "odt", "txt", "rtf", "mht", "html", "htm", "epub", "fb2"]
        static let editorImportSpreadsheets = ["xls", "ods", "csv"]
        static let editorImportPresentations = ["ppt", "odp"]
        static let editorExportDocuments = ["docx", "odt", "dotx", "ott", "docxf", "oform"]
        static let editorExportSpreadsheets = ["xlsx", "ods", "xltx", "ots"]
        static let editorExportPresentations = ["pptx", "odp", "potx", "otp"]
        static let editorExportFormats = editorExportDocuments + editorExportSpreadsheets + editorExportPresentations

        static let docx = "docx"
        static let xlsx = "xlsx"
        static let pptx = "pptx"
        static let oform = "oform"
        static let docxf = "docxf"
        static let pdf = "pdf"
    }

    enum Clouds {
        static let defaultConnectFolderProviders: [ASCFolderProviderType] = [.sharePoint, .nextCloud, .ownCloud, .kDrive, .webDav] // default portal storage set
        static let defaultConnectCloudProviders: [ASCFileProviderType] = [.nextcloud, .owncloud, .googledrive, .dropbox, .onedrive, .kdrive, .webdav] // external clouds set
        static let preferredOrderCloudProviders: [ASCFolderProviderType] = [
            .nextCloud, .ownCloud, .google, .googleDrive, .dropBox, .skyDrive,
            .oneDrive, .sharePoint, .boxNet, .yandex, .kDrive, .webDav,
        ]

        enum Dropbox {
            static let clientId: String = ASCConstants.internalConstants["DropboxClientId"] as? String ?? ""
            static let appId: String = ASCConstants.internalConstants["DropboxAppId"] as? String ?? ""
            static let clientSecret: String = ASCConstants.internalConstants["DropboxClientSecret"] as? String ?? ""
            static let redirectUri: String = ASCConstants.internalConstants["DropboxRedirectUrl"] as? String ?? ""
        }

        enum OneDrive {
            static let clientId: String = ASCConstants.internalConstants["OneDriveClientId"] as? String ?? ""
            static let clientSecret: String = ASCConstants.internalConstants["OneDriveClientSecret"] as? String ?? ""
            static let redirectUri: String = ASCConstants.internalConstants["OneDriveRedirectUrl"] as? String ?? ""
        }

        enum Microsoft {
            static let clientId: String = ASCConstants.internalConstants["MicrosoftClientId"] as? String ?? ""
            static let redirectUri: String = ASCConstants.internalConstants["MicrosoftRedirectUrl"] as? String ?? ""
        }

        enum Facebook {
            static let appId: String = ASCConstants.internalConstants["FacebookAppID"] as? String ?? ""
            static let clientToken: String = ASCConstants.internalConstants["FacebookClientToken"] as? String ?? ""
        }
    }

    enum Size {
        static let defaultPreferredContentSize = CGSize(width: 540, height: 620)
    }

    enum Colors {
        static var red: UIColor { UIColor.systemRed }
        static var darkerGrey: UIColor { UIColor.systemGray }
        static var darkGrey: UIColor { UIColor.systemGray2 }
        static var grey: UIColor { UIColor.systemGray3 }
        static var lightGrey: UIColor { UIColor.systemGray4 }
        static var lighterGrey: UIColor { UIColor.systemGray6 }
    }

    enum Searchable {
        static let domainPromo = "promo"
        static let domainDocuments = "documents"
        static let promoKeywords = ["ONLYOFFICE"]
    }

    enum Locale {
        static let defaultLangCode = "EN"
        static let avalibleLangCodes = ["EN", "RU", "FR", "DE", "ES", "CS"]
    }

    static func remoteConfigValue(forKey key: String) -> RemoteConfigValue? {
        #if !OPEN_SOURCE
            RemoteConfig.remoteConfig().configValue(forKey: key)
        #else
            nil
        #endif
    }

    fileprivate static func fetchRemoteConfig() {
        let remoteConfig = RemoteConfig.remoteConfig()

        #if DEBUG
            let debugSettings = RemoteConfigSettings()
            debugSettings.minimumFetchInterval = 0
            remoteConfig.configSettings = debugSettings
        #endif

        remoteConfig.fetch(withExpirationDuration: 0) { status, error in
            if status == .success {
                remoteConfig.activate { changed, error in
                    if let error = error {
                        log.error("Got an error fetching remote values: \(String(describing: error))")
                    }
                }
            } else {
                log.error("Got an error fetching remote values: \(String(describing: error))")
            }
        }
    }

    class var internalConstants: [String: Any] {
        if let url = Bundle.main.url(forResource: "Internal", withExtension: "plist") {
            do {
                let data = try Data(contentsOf: url)
                return try PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any] ?? [:]
            } catch {
                log.error(error)
            }
        }
        return [:]
    }

    enum CacheKeys {
        static let onlyofficeCategoriesPrefix = "onlyoffice_categories_v2"
    }
}

extension ASCConstants.Urls {
    static let defaultDomainRegions = "onlyoffice.com"
    static let domainRegions: [String: String] = ASCConstants.internalConstants["DomainRegionsDocSpace"] as? [String: String] ?? [:]
}
