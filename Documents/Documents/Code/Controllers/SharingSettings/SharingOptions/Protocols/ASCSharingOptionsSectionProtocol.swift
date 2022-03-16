//
//  ASCSharingOptionsSectionProtocol.swift
//  Documents
//
//  Created by Pavel Chernyshev on 30.06.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import UIKit

protocol ASCSharingOptionsSectionProtocol {
    func title() -> String
    func heightForRow() -> CGFloat
    func heightForSectionHeader() -> CGFloat
}
