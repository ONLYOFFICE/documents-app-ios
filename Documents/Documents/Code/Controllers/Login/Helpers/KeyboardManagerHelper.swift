//
//  KeyboardManagerHelper.swift
//  Documents
//
//  Created by Lolita Chernysheva on 18.03.2022.
//  Copyright © 2022 Ascensio System SIA. All rights reserved.
//

import UIKit

class KeyboardManagerHelper {
    private init() {}
    static let shared = KeyboardManagerHelper()
    static var disablingKeyboardToolbarByScreen: String?
}
