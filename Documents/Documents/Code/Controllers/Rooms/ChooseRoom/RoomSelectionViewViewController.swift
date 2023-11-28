//
//  RoomSelectionViewViewController.swift
//  Documents-opensource
//
//  Created by Pavel Chernyshev on 28.11.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import Foundation

import SwiftUI

class RoomSelectionViewViewController: UIHostingController<RoomSelectionView> {
    // MARK: - Lifecycle Methods

    required init?(coder aDecoder: NSCoder) {
        super.init(
            coder: aDecoder,
            rootView: RoomSelectionView()
        )
    }

    init(onAction: @escaping (RoomSelectionView) -> Void) {
        super.init(
            rootView: RoomSelectionView()
        )
    }
}
