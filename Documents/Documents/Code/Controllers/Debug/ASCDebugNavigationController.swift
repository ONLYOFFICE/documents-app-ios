//
//  ASCDebugNavigationController.swift
//  Documents
//
//  Created by Alexander Yuzhin on 13.06.2020.
//  Copyright © 2020 Ascensio System SIA. All rights reserved.
//

import UIKit

class ASCDebugNavigationController: ASCBaseNavigationController {
    // MARK: - Properties

    var onDismissed: (() -> Void)?

    // MARK: - Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        if isBeingDismissed {
            onDismissed?()
        }
    }
}
