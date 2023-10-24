//
//  ASCCloudsViewController+ManagedAppConfig.swift
//  Documents
//
//  Created by Alexander Yuzhin on 28.09.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import UIKit

extension ASCCloudsViewController: ManagedAppConfigHook {
    func onApp(config: [String: Any?]) {
        connectProvidersFromConfigIfNeeded()
    }
}

extension ASCCloudsViewController {
    private func connectProvidersFromConfigIfNeeded() {
        let newProvidersKey = "newProviders"
        var appConfig = ManagedAppConfig.shared.appConfigAll

        guard let newProvidersInfo = appConfig[newProvidersKey] as? [[String: Any]] else {
            return
        }

        newProvidersInfo.forEach { providerInfo in
            guard let providerTypeString = providerInfo["type"] as? String,
                  let providerType = ASCFileProviderType(rawValue: providerTypeString)
            else {
                return
            }

            let connectProvider: (Bool, ASCFileProviderProtocol?) -> Void = { success, provider in
                if success, let provider = provider {
                    let isNewProvider = (ASCFileManager.cloudProviders.first(where: { $0.id == provider.id }) == nil)

                    if isNewProvider {
                        ASCFileManager.cloudProviders.insert(provider, at: 0)
                        ASCFileManager.storeProviders()
                    }

                    self.connectProvider(provider)
                    self.select(provider: provider)
                }
            }

            if let provider = ASCFileManager.createProvider(by: providerType) {
                provider.isReachable(with: providerInfo) { success, provider in
                    connectProvider(success, provider)
                }
            }
        }

        appConfig[newProvidersKey] = nil
        ManagedAppConfig.shared.setAppConfig(appConfig.count > 0 ? appConfig : nil)
    }
}
