//
//  CreateRoomRouteViewViewController.swift
//  Documents
//
//  Created by Pavel Chernyshev on 28.11.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import Foundation

import SwiftUI

class CreateRoomRouteViewViewController: UIHostingController<CreateRoomRouteView> {
    // MARK: - Lifecycle Methods

    required init?(coder aDecoder: NSCoder) {
        super.init(
            coder: aDecoder,
            rootView: CreateRoomRouteView(roomName: "", hideActivityOnSuccess: true) { _ in }
        )
    }

    init(roomName: String = "", hideActivityOnSuccess: Bool = true, onAction: @escaping (ASCFolder) -> Void) {
        super.init(
            rootView: CreateRoomRouteView(roomName: roomName, hideActivityOnSuccess: hideActivityOnSuccess, onCreate: onAction)
        )
    }
}
