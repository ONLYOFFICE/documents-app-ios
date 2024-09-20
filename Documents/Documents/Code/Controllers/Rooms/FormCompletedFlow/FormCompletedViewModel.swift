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

    // MARK: - Published vars

    init(formModel: FormModel) {
        self.formModel = formModel
    }

    func checkReadyForm() {}

    func onCopyLink() {
        FormCompleteNetworkService().copyFormLink(form: formModel.form) { result in
            switch result {
            case let .success(link):
                let hud = MBProgressHUD.showTopMost()
                UIPasteboard.general.string = link.sharedTo.shareLink
                hud?.setState(result: .success(NSLocalizedString("Link successfully\ncopied to clipboard", comment: "Button title")))
                hud?.hide(animated: true, afterDelay: .standardDelay)

            case let .failure(error):
                print(error.localizedDescription)
            }
        }
    }
}
