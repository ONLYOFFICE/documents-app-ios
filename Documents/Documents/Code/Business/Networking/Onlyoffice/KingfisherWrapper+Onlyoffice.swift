//
//  KingfisherWrapper+Onlyoffice.swift
//  Documents
//
//  Created by Alexander Yuzhin on 03.05.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import Kingfisher

public extension KingfisherWrapper where Base: KFCrossPlatformImageView {
    @discardableResult
    func apiSetImage(
        with resource: Resource?,
        placeholder: Placeholder? = nil,
        options: KingfisherOptionsInfo? = nil,
        progressBlock: DownloadProgressBlock? = nil,
        completionHandler: ((Swift.Result<RetrieveImageResult, KingfisherError>) -> Void)? = nil
    ) -> DownloadTask? {
//        guard let apiClient = ASCFileManager.onlyofficeProvider?.apiClient else { return nil }

        let modifier = AnyModifier { request in
            var apiRequest = request

            if OnlyofficeApiClient.shared.isHttp2 {
                apiRequest.setValue("Bearer \(OnlyofficeApiClient.shared.token ?? "")", forHTTPHeaderField: "Authorization")
            } else {
                apiRequest.setValue(OnlyofficeApiClient.shared.token, forHTTPHeaderField: "Authorization")
            }

            return apiRequest
        }

        var localOptions = options ?? [.transition(.fade(0.2))]

        // TODO: Hotfix by Linnic. Remove after resolve of conflict between SAAS and Enterprise versions
        if let baseUrl = OnlyofficeApiClient.shared.baseURL?.absoluteString,
           let resource = resource,
           URL(string: baseUrl)?.host == resource.downloadURL.host
        {
            localOptions.append(.requestModifier(modifier))
        }

        return setImage(
            with: resource,
            placeholder: placeholder,
            options: localOptions,
            progressBlock: progressBlock,
            completionHandler: completionHandler
        )
    }
}
