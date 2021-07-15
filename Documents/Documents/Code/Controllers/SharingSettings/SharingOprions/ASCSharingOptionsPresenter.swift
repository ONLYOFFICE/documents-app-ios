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
        
        case .presentRightHolders(rightHoldersResponse: let rightHoldersResponse):
            let sharedInfoItems = rightHoldersResponse.sharedInfoItems
            let currentUser = rightHoldersResponse.currentUser
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
                var id: String?
                var avatarUrl: String?
                var rightHolderType: ASCSharingRightHolderType?
                if let user = sharedInfo.user {
                    id = user.userId
                    name = user.displayName ?? ""
                    avatarUrl = sharedInfo.user?.avatarRetina ?? sharedInfo.user?.avatar
                    rightHolderType = .user
                } else if let group = sharedInfo.group {
                    id = group.id
                    name = group.name ?? ""
                    rightHolderType = .group
                }
                
                let access = ASCSharingRightHolderViewModelAccess(entityAccess: sharedInfo.access,
                                                                   accessEditable: !sharedInfo.locked && !sharedInfo.owner)
                if let unwrapedId = id {
                    let viewModel = ASCSharingRightHolderViewModel(id: unwrapedId,
                                                                   avatarUrl: avatarUrl,
                                                                   name: name,
                                                                   department: sharedInfo.user?.department,
                                                                   isOwner: sharedInfo.owner,
                                                                   rightHolderType: rightHolderType ?? .user,
                                                                   access: access)
                    if isImportant(sharedInfo) {
                        imprtantRightHolders.append(viewModel)
                    } else {
                        otherRightHolders.append(viewModel)
                    }
                }
            })
            viewController?.display(viewModel: .displayRightHolders(.init(internalLink: rightHoldersResponse.internalLink,
                                                                          externalLink: rightHoldersResponse.externalLink,
                                                                          importantRightHolders: imprtantRightHolders,
                                                                          otherRightHolders: otherRightHolders)))
        case .presentChangeRightHolderAccess(changeRightHolderResponse: let changeRightHolderResponse):
            viewController?.display(viewModel: .displayChangeRightHolderAccess(.init(rightHolder: changeRightHolderResponse.rightHolder,
                                                                                     error: changeRightHolderResponse.error)))
        }
    }
    
}
