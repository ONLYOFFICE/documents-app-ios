//
//  WhatsNewService.swift
//  Documents
//
//  Created by Alexander Yuzhin on 13.08.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import WhatsNewKit

final class WhatsNewService {
    
    class _WhatsNewService {
        
        class var news: [WhatsNew.Item] {
            return [
                WhatsNew.Item(
                    title: NSLocalizedString("OneDrive and kDrive access", comment: ""),
                    subtitle: NSLocalizedString("View and edit files in OneDrive and kDrive directly from the app. Access your storages from the Clouds tab.", comment: ""),
                    image: Asset.Images.whatsnewFutureClouds.image
                ),
                WhatsNew.Item(
                    title: NSLocalizedString("Favorites and Recents", comment: ""),
                    subtitle: NSLocalizedString("Access files in Favorites and Recents on ONLYOFFICE portal from the app", comment: ""),
                    image: Asset.Images.whatsnewFutureOnlyoffice.image
                )
            ]
        }
        
        class func presentWhatsNew() {
            let dummyButton = ASCButtonStyle()
            dummyButton.styleType = .default
            
            // Initialize default Configuration
            var configuration = WhatsNewViewController.Configuration()
            configuration.completionButton.title = NSLocalizedString("Get started", comment: "")
            configuration.completionButton.backgroundColor = dummyButton.backgroundColor ?? Asset.Colors.brend.color
            configuration.completionButton.cornerRadius = dummyButton.layerCornerRadius
            configuration.titleView.titleFont = ASCTextStyle.largeTitleBold.font
            configuration.itemsView.titleFont = ASCTextStyle.title3Bold.font
            configuration.itemsView.subtitleFont = ASCTextStyle.subhead.font
            configuration.itemsView.autoTintImage = false
            
            if #available(iOS 13.0, *) {
                configuration.itemsView.subtitleColor = .secondaryLabel
            } else {
                configuration.itemsView.subtitleColor = .darkGray
            }

            /// Increase TitleView Insets
            configuration.titleView.insets.top = 60
            configuration.titleView.insets.bottom = 30
            
            /// Adjusts Insets for iPad
            configuration.padAdjustment = { configuration in
                /// Increase TitleView Insets
                configuration.titleView.insets.top = 80
                configuration.titleView.insets.left = 40
                configuration.titleView.insets.right = 40
                configuration.titleView.insets.bottom = 50
                
                /// Increase ItemsView Insets
                configuration.itemsView.insets.top = 10
                configuration.itemsView.insets.left = 80
                configuration.itemsView.insets.right = 80
                configuration.itemsView.insets.bottom = 20
                
                /// Increase CompletionButton Insets
                configuration.completionButton.insets.top = 40
                configuration.completionButton.insets.left = 80
                configuration.completionButton.insets.right = 80
                configuration.completionButton.insets.bottom = 40
            }
            
            // Initialize WhatsNew
            let whatsNew = WhatsNew(
                version: WhatsNew.Version(stringLiteral: ASCCommon.appVersion ?? "1.0"),
                title: NSLocalizedString("What's New", comment: ""),
                items: _WhatsNewService.news
            )

            let whatsNewViewController: WhatsNewViewController? = WhatsNewViewController(
                whatsNew: whatsNew,
                configuration: configuration
            )

            delay(seconds: 0.2) {
                if let topVC = ASCViewControllerManager.shared.rootController?.topMostViewController() {
                    if UIDevice.pad {
                        whatsNewViewController?.modalPresentationStyle = .formSheet
                        whatsNewViewController?.preferredContentSize = ASCConstants.Size.defaultPreferredContentSize
                    }
                    whatsNewViewController?.present(on: topVC)
                }
            }
        }
    }
    
    public class func show(force: Bool = false) {
        let storeAppVersion = UserDefaults.standard.string(forKey: ASCConstants.SettingsKeys.appVersion)
        
        if let appVersion = ASCCommon.appVersion, storeAppVersion != appVersion {
            UserDefaults.standard.set(appVersion, forKey: ASCConstants.SettingsKeys.appVersion)
            _WhatsNewService.presentWhatsNew()
        } else if force {
            _WhatsNewService.presentWhatsNew()
        }
    }
    
}
