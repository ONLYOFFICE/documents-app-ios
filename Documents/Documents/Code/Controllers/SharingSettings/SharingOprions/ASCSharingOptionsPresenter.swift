//
//  ASCSharingOptionsPresenter.swift
//  Documents
//
//  Created by Pavel Chernyshev on 28.06.2021.
//  Copyright (c) 2021 Ascensio System SIA. All rights reserved.
//

import UIKit

protocol ASCSharingOptionsPresentationLogic {
    func presentData(response: ASCSharingOptions.Model.Response.ResponseType)
}

class ASCSharingOptionsPresenter: ASCSharingOptionsPresentationLogic {
    weak var viewController: ASCSharingOptionsDisplayLogic?
    
    func presentData(response: ASCSharingOptions.Model.Response.ResponseType) {
        switch response {
        
        case .presentRightHolders(sharedInfoItems: let sharedInfoItems, currentUser: let currentUser):
            
            let isImportant: (ASCShareInfo) -> Bool = { shareInfo in
                var isShareInfoUserIsCurrenUser = false
                if let shareInfoUserId = shareInfo.user?.userId,
                   let currentUserId = currentUser?.userId
                {
                    isShareInfoUserIsCurrenUser = shareInfoUserId == currentUserId
                }
                return shareInfo.owner || isShareInfoUserIsCurrenUser
            }
            
            var imprtantRightHolders: [ASCSharingRightHolderViewModel] = []
            var otherRightHolders: [ASCSharingRightHolderViewModel] = []
            
            sharedInfoItems.forEach({ sharedInfo  in
                var name = ""
                if let user = sharedInfo.user {
                    name = user.displayName ?? ""
                } else if let group = sharedInfo.group {
                    name = group.name ?? ""
                }
                
                let access = ASCSharingRightHolderViewModel.Access(documetAccess: sharedInfo.access,
                                                                   accessEditable: !sharedInfo.locked && !sharedInfo.owner)
                
                let avatarUrl: String? = sharedInfo.user?.avatarRetina ?? sharedInfo.user?.avatar
                
                let viewModel = ASCSharingRightHolderViewModel(avatarUrl: avatarUrl,
                                               name: name,
                                               department: sharedInfo.user?.department,
                                               isOwner: sharedInfo.owner,
                                               access: access)
                if isImportant(sharedInfo) {
                    imprtantRightHolders.append(viewModel)
                } else {
                    otherRightHolders.append(viewModel)
                }
            })

            viewController?.displayRightHolders(viewModel: .displayRightHolders(importantRightHolders: imprtantRightHolders,
                                                                                otherRightHolders: otherRightHolders))
        }
    }
    
}
