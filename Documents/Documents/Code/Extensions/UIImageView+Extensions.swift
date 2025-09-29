//
//  UIImageView+Extensions.swift
//  Documents-develop
//
//  Created by Pavel Chernyshev on 29.09.2025.
//  Copyright © 2025 Ascensio System SIA. All rights reserved.
//

import UIKit

extension UIImageView {
    
    static func kfImage(
        for url: URL,
        placeholder: UIImage? = nil,
        completion: @escaping (UIImage?) -> Void
    ) {
        UIImageView().kf.apiSetImage(
            with: url,
            placeholder: placeholder,
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
        placeholder: UIImage? = nil
    ) async throws -> UIImage {
        try await withCheckedThrowingContinuation { continuation in
            UIImageView().kf.setImage(
                with: url,
                placeholder: placeholder
            ) { result in
                switch result {
                case .success(let value):
                    continuation.resume(returning: value.image)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
