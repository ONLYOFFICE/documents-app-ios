//
//  KingfisherWrapper+Extensions.swift
//  Documents
//
//  Created by Alexander Yuzhin on 08.04.2020.
//  Copyright © 2020 Ascensio System SIA. All rights reserved.
//

import Kingfisher

extension KingfisherWrapper where Base: KFCrossPlatformImageView {

    @discardableResult
    public func setProviderImage(
        with resource: Resource?,
        for provider: Any,
        placeholder: Placeholder? = nil,
        options: KingfisherOptionsInfo? = nil,
        progressBlock: DownloadProgressBlock? = nil,
        completionHandler: ((Swift.Result<RetrieveImageResult, KingfisherError>) -> Void)? = nil) -> DownloadTask?
    {
        guard let provider = provider as? ASCFileProviderProtocol else { return nil }
        
        let defaultTimeout: TimeInterval = 15
        let modifier = AnyModifier { request in
            var apiRequest = request
            apiRequest.timeoutInterval = defaultTimeout
            
            if let authorization = provider.authorization {
                apiRequest.setValue(authorization, forHTTPHeaderField: "Authorization")
            }
            return apiRequest
        }

        var localOptions = options ?? [.transition(.fade(0.3))]
        
        if provider is ASCOnlyofficeProvider {
            if let baseUrl = ASCOnlyOfficeApi.shared.baseUrl,
                let resource = resource,
                URL(string: baseUrl)?.host == resource.downloadURL.host
            {
                localOptions.append(.requestModifier(modifier))
            } else {
                localOptions.append(.requestModifier(AnyModifier { request in
                    var apiRequest = request
                    apiRequest.timeoutInterval = defaultTimeout
                    return apiRequest
                }))
            }
        } else {
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
