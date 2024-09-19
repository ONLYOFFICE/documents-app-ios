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
    
    @Published var author: ASCUser?
    
    var form: ASCFile
    var formNumber: Int
    
    //MARK: - Published vars
    
    init(form: ASCFile, formNumber: Int) {
        self.form = form
        self.formNumber = formNumber
        self.author = form.createdBy
    }
    
    func checkReadyForm() {
        
    }
    
    func onCopyLink() {
        FormCompleteNetworkService().copyFormLink(form: form) { result in
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

