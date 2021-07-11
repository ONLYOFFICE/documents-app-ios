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
            let usersIdsSet = Set(response.sharedEntities.map({ $0.user?.userId }).compactMap({ $0 }))
            var sharedIndexes: [Int] = []
            for user in users {
                viewModels.append(ASCSharingRightHolderViewModel(
                                    id: user.userId ?? "",
                                    avatarUrl: user.avatar,
                                    name: user.userName ?? "",
                                    department: user.department,
                                    isOwner: false,
                                    rightHolderType: .user,
                                    access: nil))
                if let id = user.userId, usersIdsSet.contains(id) {
                    sharedIndexes.append(users.count - 1)
                }
            }
            viewController?.displayData(viewModelType: .displayUsers(.init(users: viewModels, selectedIndexes: sharedIndexes)))
        case .presentGroups(response: let response):
            var viewModels: [ASCSharingRightHolderViewModel] = []
            let groups = response.groups.sorted(by: { $0.name ?? "" < $1.name ?? "" })
            let groupIdsSet = Set(response.sharedEntities.map({ $0.group?.id }).compactMap({ $0 }))
            var sharedIndexes: [Int] = []
            for group in groups {
                viewModels.append(ASCSharingRightHolderViewModel(
                                    id: group.id ?? "",
                                    name: group.name ?? "",
                                    isOwner: false,
                                    rightHolderType: .group,
                                    access: nil))
                if let id = group.id, groupIdsSet.contains(id) {
                    sharedIndexes.append(groups.count - 1)
                }
            }
            viewController?.displayData(viewModelType: .displayGroups(.init(groups: viewModels, selectedIndexes: sharedIndexes)))
        }
    }
    
}
