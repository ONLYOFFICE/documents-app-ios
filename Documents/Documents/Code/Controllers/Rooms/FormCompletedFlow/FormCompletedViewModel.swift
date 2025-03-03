//
//  FormCompletedViewModel.swift
//  Documents
//
//  Created by Lolita Chernysheva on 09.09.2024.
//  Copyright © 2024 Ascensio System SIA. All rights reserved.
//

import Combine
import Foundation
import MBProgressHUD

final class FormCompletedViewModel: ObservableObject {
    typealias FormSharingLinkModel = RoomSharingLinkModel

    var formModel: FormModel

    var onCheckReadyForm: () -> Void

    // MARK: - Published vars

    init(formModel: FormModel, onCheckReadyForm: @escaping () -> Void) {
        self.formModel = formModel
        self.onCheckReadyForm = onCheckReadyForm
    }

    func checkReadyForm() {
        onCheckReadyForm()
    }
    
    func onCopyLink() {
        let hud = MBProgressHUD.showTopMost()
        UIPasteboard.general.string = formModel.form.webUrl
        hud?.setState(result: .success(NSLocalizedString("Link successfully\ncopied to clipboard", comment: "Button title")))
        hud?.hide(animated: true, afterDelay: .standardDelay)
    }
}
