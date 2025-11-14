//
//  URL+Extensions.swift
//  Documents
//
//  Created by Alexander Yuzhin on 18/04/2019.
//  Copyright © 2019 Ascensio System SIA. All rights reserved.
//

import AVFoundation
import UIKit

public extension URL {
    /// Generates new URL that does not have path and query.
    ///
    ///     let url = URL(string: "https://domain.com/path/other?q=1234")!
    ///     print(url.dropPathAndQuery()) // prints "https://domain.com"
    func dropPathAndQuery() -> URL {
        if var components = URLComponents(string: absoluteString) {
            components.path = ""
            components.query = nil
            components.fragment = nil
            return components.url ?? self
        }
        return self
    }

    /// Generate a thumbnail image from given url. Returns nil if no thumbnail could be created. This function may take some time to complete. It's recommended to dispatch the call if the thumbnail is not generated from a local resource.
    ///
    ///     var url = URL(string: "https://video.golem.de/files/1/1/20637/wrkw0718-sd.mp4")!
    ///     var thumbnail = url.thumbnail()
    ///     thumbnail = url.thumbnail(fromTime: 5)
    ///
    ///     DisptachQueue.main.async {
    ///         someImageView.image = url.thumbnail()
    ///     }
    ///
    /// - Parameter time: Seconds into the video where the image should be generated.
    /// - Returns: The UIImage result of the AVAssetImageGenerator
    func thumbnail(fromTime time: Float64 = 0) -> UIImage? {
        let imageGenerator = AVAssetImageGenerator(asset: AVAsset(url: self))
        let time = CMTimeMakeWithSeconds(time, preferredTimescale: 1)
        var actualTime = CMTimeMake(value: 0, timescale: 0)

        guard let cgImage = try? imageGenerator.copyCGImage(at: time, actualTime: &actualTime) else {
            return nil
        }
        return UIImage(cgImage: cgImage)
    }

    func appendingSafePath(_ path: String) -> URL {
        let trimmedBase = self.absoluteString.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let trimmedPath = path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let fullString = "\(trimmedBase)/\(trimmedPath)"
        return URL(string: fullString) ?? self
    }
}
