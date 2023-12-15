//
//  CreateRoomRouteViewViewController.swift
//  Documents-opensource
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
            rootView: CreateRoomRouteView { _ in }
        )
    }

    init(onAction: @escaping (ASCFolder) -> Void) {
        super.init(
            rootView: CreateRoomRouteView(onCreate: onAction)
        )
    }
}
