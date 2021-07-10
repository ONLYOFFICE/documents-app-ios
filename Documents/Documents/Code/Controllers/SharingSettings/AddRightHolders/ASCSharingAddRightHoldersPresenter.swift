//
//  ASCSharingAddRightHoldersPresenter.swift
//  Documents
//
//  Created by Павел Чернышев on 09.07.2021.
//  Copyright (c) 2021 Ascensio System SIA. All rights reserved.
//

import UIKit

protocol ASCSharingAddRightHoldersPresentationLogic {
    func presentData(responseType: ASCSharingAddRightHolders.Model.Response.ResponseType)
}

class ASCSharingAddRightHoldersPresenter: ASCSharingAddRightHoldersPresentationLogic {
    weak var viewController: ASCSharingAddRightHoldersDisplayLogic?
    
    func presentData(responseType: ASCSharingAddRightHolders.Model.Response.ResponseType) {
        switch responseType {
        case .presentUsers(response: let response):
            var viewModels: [ASCSharingRightHolderViewModel] = []
            let users = response.users.sorted(by: { $0.userName ?? "" < $1.userName ?? "" })
            for user in users {
                viewModels.append(ASCSharingRightHolderViewModel(
                                    id: user.userId ?? "",
                                    avatarUrl: user.avatar,
                                    name: user.userName ?? "",
                                    department: user.department,
                                    isOwner: false,
                                    rightHolderType: .user,
                                    access: nil))
            }
            viewController?.displayData(viewModelType: .displayUsers(.init(users: viewModels)))
        case .presentGroups(response: let response):
            return
        }
    }
    
}
