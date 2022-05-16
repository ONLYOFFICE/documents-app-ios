//
//  UIImage+Extension.swift
//  Documents
//
//  Created by Alexander Yuzhin on 21.07.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import UIKit

// MARK: - Initializers

public extension UIImage {
    /// Create UIImage from color and size.
    ///
    /// - Parameters:
    ///   - color: image fill color.
    ///   - size: image size.
    convenience init(color: UIColor, size: CGSize) {
        UIGraphicsBeginImageContextWithOptions(size, false, 1)

        defer {
            UIGraphicsEndImageContext()
        }

        color.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))

        guard let aCgImage = UIGraphicsGetImageFromCurrentImageContext()?.cgImage else {
            self.init()
            return
        }

        self.init(cgImage: aCgImage)
    }

    /// Create a new image from a base 64 string.
    ///
    /// - Parameters:
    ///   - base64String: a base-64 `String`, representing the image
    ///   - scale: The scale factor to assume when interpreting the image data created from the base-64 string. Applying a scale factor of 1.0 results in an image whose size matches the pixel-based dimensions of the image. Applying a different scale factor changes the size of the image as reported by the `size` property.
    convenience init?(base64String: String, scale: CGFloat = 1.0) {
        guard let data = Data(base64Encoded: base64String) else { return nil }
        self.init(data: data, scale: scale)
    }

    /// Create a new image from a URL
    ///
    /// - Important:
    ///   Use this method to convert data:// URLs to UIImage objects.
    ///   Don't use this synchronous initializer to request network-based URLs. For network-based URLs, this method can block the current thread for tens of seconds on a slow network, resulting in a poor user experience, and in iOS, may cause your app to be terminated.
    ///   Instead, for non-file URLs, consider using this in an asynchronous way, using `dataTask(with:completionHandler:)` method of the URLSession class or a library such as `AlamofireImage`, `Kingfisher`, `SDWebImage`, or others to perform asynchronous network image loading.
    /// - Parameters:
    ///   - url: a `URL`, representing the image location
    ///   - scale: The scale factor to assume when interpreting the image data created from the URL. Applying a scale factor of 1.0 results in an image whose size matches the pixel-based dimensions of the image. Applying a different scale factor changes the size of the image as reported by the `size` property.
    convenience init?(url: URL, scale: CGFloat = 1.0) throws {
        let data = try Data(contentsOf: url)
        self.init(data: data, scale: scale)
    }
}
