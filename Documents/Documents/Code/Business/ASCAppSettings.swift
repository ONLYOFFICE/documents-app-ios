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

    enum Feature {
        // Hide the searchbar in the navigationbar if the list of documents is empty
        static var hideSearchbarIfEmpty: Bool {
            get { UserDefaults.standard.bool(forKey: ASCConstants.SettingsKeys.debugHideSearchbarIfEmpty) }
            set { UserDefaults.standard.set(newValue, forKey: ASCConstants.SettingsKeys.debugHideSearchbarIfEmpty) }
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

        // Force RTL
        static var forceRtl: Bool {
            get { UserDefaults.standard.bool(forKey: ASCConstants.SettingsKeys.debugForceRtl) }
            set { UserDefaults.standard.set(newValue, forKey: ASCConstants.SettingsKeys.debugForceRtl) }
        }
    }
}
