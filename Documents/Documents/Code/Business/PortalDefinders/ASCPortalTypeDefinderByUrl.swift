//
//  ASCPortalTypeDefinderByUrl.swift
//  Documents
//
//  Created by Pavel Chernyshev on 25.11.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import Foundation

class ASCPortalTypeDefinderByUrl: ASCPortalTypeDefinderProtocol {
    var url: URL?

    init(url: URL? = nil) {
        self.url = url
    }

    func definePortalType() -> ASCPortalType {
        guard let url = url else { return .unknown }

        if url.absoluteString.contains(ASCConstants.Urls.personalPortals) {
            return .personal
        }

        return .unknown
    }
}
