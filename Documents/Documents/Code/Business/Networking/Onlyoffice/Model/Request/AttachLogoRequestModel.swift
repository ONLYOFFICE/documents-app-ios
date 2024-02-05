//
//  AttachLogoRequestModel.swift
//  Documents-opensource
//
//  Created by Pavel Chernyshev on 14.12.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import Foundation

struct AttachLogoRequestModel: Codable {
    var tmpFile: String
    var x: Int = 0
    var y: Int = 0
    var width: CGFloat
    var height: CGFloat
}
