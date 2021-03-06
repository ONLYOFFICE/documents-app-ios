//
//  ASCConstants.swift
//  Documents
//
//  Created by Alexander Yuzhin on 3/17/17.
//  Copyright © 2017 Ascensio System SIA. All rights reserved.
//

import Foundation
import UIKit
import FirebaseRemoteConfig

class ASCConstants {
    struct Name {
        static let appNameShort             = NSLocalizedString("ONLYOFFICE", comment: "Short App Name")
        static let appNameFull              = NSLocalizedString("ONLYOFFICE Documents", comment: "Full App Name")
        static let copyright                = String(format: NSLocalizedString("© Ascensio System SIA %d", comment: ""), Calendar.current.component(.year, from: Date()))
    }

    struct Keys {
        static let portalRegistration       = ASCConstants.internalConstants["KeysPortalRegistration"] as? String ?? ""
        static let ascDocumentServiceKey    = ASCConstants.internalConstants["KeysAscDocumentServiceKey"] as? String ?? ""
        static let ascDocumentServiceKeyId  = ASCConstants.internalConstants["KeysAscDocumentServiceKeyId"] as? String ?? ""
        static let converterKey             = ASCConstants.internalConstants["KeysConverterKey"] as? String ?? ""
    }

    struct Urls {
        static let portalPersonal           = "://personal.onlyoffice.com"
        static let apiSystemUrl             = "https://api-system.%@"
        static let apiValidatePortalName    = "api/portal/validateportalname"
        static let apiRegistrationPortal    = "api/portal/register"
        static let apiForgetPassword        = "%@/auth.aspx#passrecovery"
        static let supportMailTo            = "support@onlyoffice.com"
        static let legalTerms               = "https://www.onlyoffice.com/legalterms.aspx"
        static let applicationPage          = "https://www.onlyoffice.com/mobile.aspx"
        static let applicationFeedbackForum = "https://cloud.onlyoffice.org/viewforum.php?f=48"
        static let appReview                = "itms-apps://itunes.apple.com/app/id944896972?action=write-review"
        static let appStoreGoogleAuth       = "https://itunes.apple.com/app/id388497605"
        static let help2authByApp           = "https://helpcenter.onlyoffice.com/guides/two-factor-authentication.aspx#step4"
        static let documentServiceDomain    = ASCConstants.internalConstants["UrlsDocumentServiceDomain"] as? String ?? ""
    }
    
    struct SettingsKeys {
        static let sortDocuments                = "asc-sort-documents"
        static let collaborationService         = "asc-collaboration-service"
        static let appVersion                   = "asc-documents-version"
        static let lastFolder                   = "asc-last-folder"
        static let compressImage                = "asc-settings-compress-image"
        static let previewFiles                 = "asc-settings-preview-files"
        static let allowTouchId                 = "asc-settings-allow-touchid"
        static let forceCreateNewDocument       = "asc-shortcut-new-document"
        static let forceCreateNewSpreadsheet    = "asc-shortcut-new-spreadsheet"
        static let forceCreateNewPresentation   = "asc-shortcut-new-presentation"
        static let openedDocument               = "asc-opened-document"
        static let openedDocumentModifity       = "asc-opened-document-modifity"
        static let importFile                   = "asc-import-file"
        static let pushAllow                    = "asc-push-allow"
        static let pushDeviceToken              = "asc-push-device-token"
        static let pushFCMToken                 = "asc-push-fcm-token"
        static let pushUserInfo                 = "asc-push-user-info"
        static let sdkVersion                   = "asc-sdk-version"
        static let passwordOpenedDocument       = "asc-opened-document-password"
        static let lastCloudIndex               = "asc-last-cloud-index"


        static func setupDefaults() {
            UserDefaults.standard.register(defaults: [ASCConstants.SettingsKeys.compressImage: true])
            UserDefaults.standard.register(defaults: [ASCConstants.SettingsKeys.allowTouchId: true])
            UserDefaults.standard.register(defaults: [ASCConstants.SettingsKeys.previewFiles: true])
        }
    }

    struct Keychain {
        static let group                    = ASCConstants.internalConstants["KeychainGroup"] as? String ?? ""
        static let keyAccounts              = "asc-accounts"
        static let keyProviders             = "asc-providers"
        static let keyLastProviderId        = "asc-provider-id"
    }

    struct RemoteSettingsKeys {
        static let allowCoauthoring         = "allow_coauthoring"
        static let checkSdkFully            = "check_sdk_fully"

        static func setupDefaults() {
            let defaultValues: [String: NSObject] = [
                allowCoauthoring: NSNumber(value: true),
                checkSdkFully: NSNumber(value: true)
            ]

            RemoteConfig.remoteConfig().setDefaults(defaultValues)
            fetchRemoteConfig()
        }
    }

    struct Analytics {
        struct Event {
            static let createPortal             = "portal_create"
            static let loginPortal              = "portal_login"
            static let switchAccount            = "account_switch"
            static let openEditor               = "open_editor"
            static let openPdf                  = "open_pdf"
            static let openMedia                = "open_media"
            static let openExternal             = "open_external"
            static let createEntity             = "create_entity"
        }
        
        static var allow: Bool {
            guard let allow = UserDefaults.standard.object(forKey: "share_analytics") as? Bool else {
                return true
            }
            return allow
        }
    }

    struct Shortcuts {
        static let newDocument                  = "asc-shortcut-new-document"
        static let newSpreadsheet               = "asc-shortcut-new-spreadsheet"
        static let newPresentation              = "asc-shortcut-new-presentation"
    }

    struct Notifications {
        static let loginOnlyofficeCompleted     = Notification.Name("ASCEventOnlyofficeLogInCompleted")
        static let logoutOnlyofficeCompleted    = Notification.Name("ASCEventOnlyofficeLogOutCompleted")
        static let userInfoOnlyofficeUpdate     = Notification.Name("ASCEventUserInfoOnlyofficeUpdate")
        static let shortcutLaunch               = Notification.Name("ASCEventShortcutLaunch")
        static let importFileLaunch             = Notification.Name("ASCEventImportFileLaunch")
        static let networkStatusChanged         = Notification.Name("ASCEventNetworkStatusChanged")
        static let updateFileInfo               = Notification.Name("ASCEventUpdateFileInfo")
        static let updateSizeClass              = Notification.Name("ASCEventUpdateSizeClass")
        static let openLocalFileByUrl           = Notification.Name("ASCEventOpenLocalFileByUrl")
        static let appDidBecomeActive           = Notification.Name("ASCEventAppDidBecomeActive")
        static let pushInfo                     = Notification.Name("ASCEventPushInfo")
        static let reloadData                   = Notification.Name("ASCEventReloadData")
    }

    struct FileExtensions {
        static let documents                    = ["docx", "doc", "odt", "rtf", "mht", "html", "htm", "epub", "fb2", "txt"]
        static let spreadsheets                 = ["xlsx", "xls", "csv", "ods"]
        static let presentations                = ["pptx", "ppt", "odp"]
        static let images                       = ["jpg", "jpeg", "png", "gif", "bmp", "tif", "tiff", "ico"]
        static let videos                       = ["mpg", "mpeg", "mpg4", "mp4", "m4v", "mov", "avi", "vfw", "m75", "m15", "3g2", "3gp2", "3gp", "3gpp"]
        static let allowEdit                    = ["docx", "xlsx", "pptx", "csv", "txt", "odt", "ods", "odp", "doc", "xls", "ppt", "rtf", "mht", "html", "htm", "epub", "fb2"]
        static let editorImportDocuments        = ["doc", "odt", "txt", "rtf", "mht", "html", "htm", "epub", "fb2"]
        static let editorImportSpreadsheets     = ["xls", "ods", "csv"]
        static let editorImportPresentations    = ["ppt", "odp"]
        static let editorExportDocuments        = ["docx", "odt", "dotx", "ott"]
        static let editorExportSpreadsheets     = ["xlsx", "ods", "xltx", "ots"]
        static let editorExportPresentations    = ["pptx", "odp", "potx", "otp"]
        static let editorExportFormats          = editorExportDocuments + editorExportSpreadsheets + editorExportPresentations
    }

    struct Clouds {
        static let defaultConnectFolderProviders: [ASCFolderProviderType]   = [.sharePoint, .nextCloud, .ownCloud, .webDav] // default portal storage set
        static let defaultConnectCloudProviders: [ASCFileProviderType]      = [.nextcloud, .owncloud, .googledrive, .dropbox, .webdav] // external clouds set
        static let preferredOrderCloudProviders: [ASCFolderProviderType]    = [
            .nextCloud, .ownCloud, .google, .googleDrive, .dropBox, .skyDrive,
            .oneDrive, .sharePoint, .boxNet, .yandex, .webDav
        ]
        
        struct Dropbox {
            static let clientId: String     = ASCConstants.internalConstants["DropboxClientId"] as? String ?? ""
            static let redirectUri: String  = "https://service.onlyoffice.com/oauth2.aspx"
        }
        
        struct Facebook {
            static let appId: String        = ASCConstants.internalConstants["FacebookAppID"] as? String ?? ""
        }
    }

    struct Size {
        static let defaultPreferredContentSize = CGSize(width: 540, height: 620)
    }
    
    struct Colors {
        static var brend        : UIColor { return UIColor(hex: "#2d6bb0") }
        static var brendAction  : UIColor { return UIColor(hex: "#007bff") }
        static var red          : UIColor { if #available(iOS 13.0, *) { return  UIColor.systemRed   } else { return UIColor(hex: "#ff3b30") } }
        static var darkerGrey   : UIColor { if #available(iOS 13.0, *) { return  UIColor.systemGray  } else { return UIColor(hex: "#424245") } }
        static var darkGrey     : UIColor { if #available(iOS 13.0, *) { return  UIColor.systemGray2 } else { return UIColor(hex: "#555555") } }
        static var grey         : UIColor { if #available(iOS 13.0, *) { return  UIColor.systemGray3 } else { return UIColor(hex: "#999da6") } }
        static var lightGrey    : UIColor { if #available(iOS 13.0, *) { return  UIColor.systemGray4 } else { return UIColor(hex: "#c8c7cc") } }
        static var lighterGrey  : UIColor { if #available(iOS 13.0, *) { return  UIColor.systemGray6 } else { return UIColor(hex: "#eff1f3") } }
    }

    struct Searchable {
        static let domainPromo          = "promo"
        static let domainDocuments      = "documents"
        static let promoKeywords        = ["ONLYOFFICE"]
    }

    static func remoteConfigValue(forKey key: String) -> RemoteConfigValue? {
        return RemoteConfig.remoteConfig().configValue(forKey: key)
    }

    static fileprivate func fetchRemoteConfig() {
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
    
    class var internalConstants: [String : Any] {
        if let url = Bundle.main.url(forResource:"Internal", withExtension: "plist") {
            do {
                let data = try Data(contentsOf:url)
                return try PropertyListSerialization.propertyList(from: data, format: nil) as? [String : Any] ?? [:]
            } catch {
                log.error(error)
            }
        }
        return [:]
    }

}


extension ASCConstants.Urls {
    static let defaultDomainRegions = "onlyoffice.com"
    static let domainRegions: [String : String] = ASCConstants.internalConstants["DomainRegions"] as? [String : String] ?? [:]
}
