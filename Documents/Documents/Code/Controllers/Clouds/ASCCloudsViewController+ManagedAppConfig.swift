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
        connectProvidersFromConfigIfNeeded(config: config)
    }
}

extension ASCCloudsViewController {
    enum MDMOperationType: String {
        case newProviders
        case unknown
    }

    private func connectProvidersFromConfigIfNeeded(config: [String: Any?]) {
        let type = MDMOperationType(rawValue: config["type"] as? String ?? "") ?? .unknown

        guard
            type == .newProviders,
            let options = config["options"] as? [[String: Any]]
        else {
            return
        }

        for providerInfo in options {
            guard let providerTypeString = providerInfo["type"] as? String,
                  let providerType = ASCFileProviderType(rawValue: providerTypeString)
            else {
                continue
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

        ManagedAppConfig.shared.processed = true
    }
}
