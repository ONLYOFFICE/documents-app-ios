//
//  AppDelegate.swift
//  Documents
//
//  Created by Alexander Yuzhin on 2/6/17.
//  Copyright © 2017 Ascensio System SIA. All rights reserved.
//

import CoreServices
import CoreSpotlight
import FirebaseCore
import FirebaseMessaging
import GoogleSignIn
import Siren
import SwiftyDropbox
import UIKit
import UserNotifications
#if DEBUG
    import Atlantis
#endif

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    // MARK: - Application Lifecycle

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        self.launchOptions = launchOptions

        initializeDI()

        if ASCCommon.isUnitTesting {
            return true
        }

        #if DEBUG
            Atlantis.start()
        #endif

        ASCStyles.initialize

        ASCLogIntercepter.shared.start()
        ASCAccountsManager.start()

        #if !OPEN_SOURCE
            // Use Firebase library to configure APIs
            FirebaseApp.configure()

            // Reset application badge
            ASCCommon.applicationIconBadgeNumber = 0

            // Register for remote notifications
            Messaging.messaging().delegate = self
            UNUserNotificationCenter.current().delegate = self

            DropboxClientsManager.setupWithAppKey(ASCConstants.Clouds.Dropbox.appId)

            // Initialize searchable promo
            searchablePromoInit()
        #endif

        // Check Update
        configureAppUpdater()

        return true
    }

    // MARK: - UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }

    private func searchablePromoInit() {
        CSSearchableIndex.default().deleteSearchableItems(withDomainIdentifiers: [ASCConstants.Searchable.domainPromo]) { error in
            var searchableItems = [CSSearchableItem]()

            for (index, keyword) in ASCConstants.Searchable.promoKeywords.enumerated() {
                let searchItemAttributeSet = CSSearchableItemAttributeSet(itemContentType: kUTTypeText as String)
                searchItemAttributeSet.title = keyword

                let searchableItem = CSSearchableItem(
                    uniqueIdentifier: "\(index)",
                    domainIdentifier: ASCConstants.Searchable.domainPromo,
                    attributeSet: searchItemAttributeSet
                )
                searchableItems.append(searchableItem)
            }

            CSSearchableIndex.default().indexSearchableItems(searchableItems) { error in
                if let error = error {
                    print(error.localizedDescription)
                }
            }
        }
    }

    private func configureAppUpdater() {
        let siren = Siren.shared
        let rules = Rules(promptFrequency: .immediately, forAlertType: .option)

        Siren.shared.rulesManager = RulesManager(globalRules: rules,
                                                 showAlertAfterCurrentVersionHasBeenReleasedForDays: 1)

        siren.wail()
    }
}
