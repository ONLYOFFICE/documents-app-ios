//
//  EditRoomViewController.swift
//  Documents-develop
//
//  Created by Victor Tihovodov on 10.01.2024.
//  Copyright © 2024 Ascensio System SIA. All rights reserved.
//

import Foundation
import SwiftUI

class EditRoomViewController: UIHostingController<EditRoomRouteView> {
    // MARK: - Lifecycle Methods

    required init?(coder aDecoder: NSCoder) {
        super.init(
            coder: aDecoder
        )
    }

    init(folder: ASCFolder, onAction: @escaping (ASCFolder) -> Void) {
        super.init(
            rootView: EditRoomRouteView(folder: folder, onEdited: onAction)
        )
    }
}
