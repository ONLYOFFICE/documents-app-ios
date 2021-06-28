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
        
        case .presentRightHolders(sharedInfoItems: let sharedInfoItems):
            let rightHolders: [ASCSharingRightHolderViewModel] = sharedInfoItems.map({ sharedInfo  in
                var name = ""
                var type: ASCSharingRightHolderViewModel.RightHolderType = .manager
                var image: UIImage? = nil // MARK: - TODO
                if let user = sharedInfo.user {
                    name = user.userName ?? ""
                } else if let group = sharedInfo.group {
                    name = group.name ?? ""
                    type = .group
                }
                
                // MARK: - TODO make shure is any no owner editable ?
                let access = ASCSharingRightHolderViewModel.Access(documetAccess: sharedInfo.access, accessEditable: !sharedInfo.owner)
                
                return ASCSharingRightHolderViewModel(avatar: UIImage(),
                                               name: name,
                                               isOwner: sharedInfo.owner,
                                               rightHolderType: type,
                                               access: access)
            })
            
            // MARK: - TODO add current user to impornant array
            let imprtantRightHolders = rightHolders.filter({ $0.isOwner })
            let otherRightHolders = rightHolders.filter({ !$0.isOwner })
            
            viewController?.displayRightHolders(viewModel: .displayRightHolders(importantRightHolders: imprtantRightHolders,
                                                                                otherRightHolders: otherRightHolders))
        }
    }
    
}
