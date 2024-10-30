//
//  ASCAppSettings.swift
//  Documents
//
//  Created by Alexander Yuzhin on 29.05.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import Foundation

enum ASCAppSettings {
    static var previewFiles: Bool {
        get { UserDefaults.standard.bool(forKey: ASCConstants.SettingsKeys.previewFiles) }
        set { UserDefaults.standard.set(newValue, forKey: ASCConstants.SettingsKeys.previewFiles) }
    }

    static var compressImage: Bool {
        get { UserDefaults.standard.bool(forKey: ASCConstants.SettingsKeys.compressImage) }
        set { UserDefaults.standard.set(newValue, forKey: ASCConstants.SettingsKeys.compressImage) }
    }

    static var gridLayoutFiles: Bool {
        get { UserDefaults.standard.bool(forKey: ASCConstants.SettingsKeys.gridLayoutFiles) }
        set { UserDefaults.standard.set(newValue, forKey: ASCConstants.SettingsKeys.gridLayoutFiles) }
    }

    enum Feature {
        // Allow external clouds category
        static var hideCloudsCategory: Bool {
            get { UserDefaults.standard.bool(forKey: ASCConstants.SettingsKeys.hideCloudsCategory) }
            set { UserDefaults.standard.set(newValue, forKey: ASCConstants.SettingsKeys.hideCloudsCategory) }
        }

        // Allow iCloud provider
        static var allowiCloud: Bool {
            get { UserDefaults.standard.bool(forKey: ASCConstants.SettingsKeys.debugAllowiCloud) }
            set { UserDefaults.standard.set(newValue, forKey: ASCConstants.SettingsKeys.debugAllowiCloud) }
        }

        // Allow skeleton animation for ONLYOFFICE categories on load
        static var allowCategoriesSkeleton: Bool {
            get { UserDefaults.standard.bool(forKey: ASCConstants.SettingsKeys.debugAllowCategoriesSkeleton) }
            set { UserDefaults.standard.set(newValue, forKey: ASCConstants.SettingsKeys.debugAllowCategoriesSkeleton) }
        }

        // Connect Dropbox Cloud via SDK
        static var dropboxSDKLogin: Bool {
            get { UserDefaults.standard.bool(forKey: ASCConstants.SettingsKeys.debugDropboxSDKLogin) }
            set { UserDefaults.standard.set(newValue, forKey: ASCConstants.SettingsKeys.debugDropboxSDKLogin) }
        }

        // Open editors in view mode
        static var openViewModeByDefault: Bool {
            get { UserDefaults.standard.bool(forKey: ASCConstants.SettingsKeys.debugOpenEditorViewModeDefault) }
            set { UserDefaults.standard.set(newValue, forKey: ASCConstants.SettingsKeys.debugOpenEditorViewModeDefault) }
        }

        // Disable check of sdk version
        static var disableSdkVersionCheck: Bool {
            get { UserDefaults.standard.bool(forKey: ASCConstants.SettingsKeys.debugDisableSdkVersionCheck) }
            set { UserDefaults.standard.set(newValue, forKey: ASCConstants.SettingsKeys.debugDisableSdkVersionCheck) }
        }
    }
}
