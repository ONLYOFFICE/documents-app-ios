//
//  UIImageView+Extensions.swift
//  Documents
//
//  Created by Pavel Chernyshev on 29.09.2025.
//  Copyright © 2025 Ascensio System SIA. All rights reserved.
//

import UIKit

extension UIImageView {
    static func kfImage(
        for url: URL,
        provider: ASCFileProviderProtocol? = nil,
        placeholder: UIImage? = nil,
        completion: @escaping (UIImage?) -> Void
    ) {
        UIImageView().kf.setProviderImage(
            with: url,
            for: provider,
            completionHandler: { kfResult in
                if case let .success(value) = kfResult {
                    completion(value.image)
                } else {
                    completion(nil)
                }
            }
        )
    }

    static func kfImage(
        for url: URL,
        provider: ASCFileProviderProtocol? = nil,
        placeholder: UIImage? = nil
    ) async throws -> UIImage {
        try await withCheckedThrowingContinuation { continuation in
            UIImageView().kf.setProviderImage(
                with: url,
                for: provider,
                placeholder: placeholder,
                completionHandler: { result in
                    switch result {
                    case let .success(value):
                        continuation.resume(returning: value.image)
                    case let .failure(error):
                        continuation.resume(throwing: error)
                    }
                }
            )
        }
    }
}
