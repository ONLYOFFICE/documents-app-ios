//
//  ASCConnectStorageWebDavControllerConfiguration.swift
//  Documents
//
//  Created by Alexander Yuzhin on 06.09.2022.
//  Copyright © 2022 Ascensio System SIA. All rights reserved.
//

import UIKit

struct ASCConnectStorageWebDavControllerConfiguration {
    var provider: ASCFolderProviderType = .webDav
    var loginTitle: String?
    var needServer: Bool
    var logo: UIImage?
    var title: String?
    var instruction: String?
    var complation: (([String: String]) -> Void)?

    static func defaultConfiguration() -> ASCConnectStorageWebDavControllerConfiguration {
        return ASCConnectStorageWebDavControllerConfiguration(
            provider: .webDav
        )
    }

    init(
        provider: ASCFolderProviderType,
        loginTitle: String? = nil,
        needServer: Bool? = nil,
        logo: UIImage? = nil,
        title: String? = nil,
        instruction: String? = nil,
        complation: (([String: String]) -> Void)? = nil
    ) {
        self.provider = provider
        self.loginTitle = loginTitle ?? NSLocalizedString("Login", comment: "")
        self.needServer = needServer ?? true
        self.logo = logo
        self.title = title
        self.instruction = instruction
        self.complation = complation
    }
}
