//
//  ASCShareRights.swift
//  Documents-develop
//
//  Created by Lolita Chernysheva on 20.11.2025.
//  Copyright © 2025 Ascensio System SIA. All rights reserved.
//

import Foundation
import ObjectMapper
import SwiftUI
import UIKit

final class ASCShareRights: Mappable {
    var user: [ASCShareAccess] = []
    var externalLink: [ASCShareAccess] = []
    var group: [ASCShareAccess] = []
    var primaryExternalLink: [ASCShareAccess] = []

    init() {}

    required init?(map: Map) {}

    func mapping(map: Map) {
        let transform = ShareAccessArrayTransform()

        user <- (map["User"], transform)
        externalLink <- (map["ExternalLink"], transform)
        group <- (map["Group"], transform)
        primaryExternalLink <- (map["PrimaryExternalLink"], transform)
    }
}

struct ShareAccessArrayTransform: TransformType {
    typealias Object = [ASCShareAccess]
    typealias JSON = [String]

    func transformFromJSON(_ value: Any?) -> [ASCShareAccess]? {
        guard let strings = value as? [String] else { return nil }
        return strings.compactMap(ASCShareAccess.init(serverString:))
    }

    func transformToJSON(_ value: [ASCShareAccess]?) -> [String]? {
        guard let value else { return nil }
        return value.map { $0.serverString }
    }
}
