//
//  RoomSharingRootViewController.swift
//  Documents
//
//  Created by Lolita Chernysheva on 19.12.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import Foundation
import SwiftUI

class RoomSharingRootViewController: UIHostingController<RoomSharingView> {
    // MARK: - Lifecycle Methods
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init?(coder aDecoder: NSCoder) is not implemented")
    }

    init(room: ASCFolder, sharingRoomService: NetworkSharingRoomServiceProtocol) {
        super.init(
            rootView: RoomSharingView(
                viewModel: .init(room: room, sharingRoomService: sharingRoomService)
            )
        )
    }
}