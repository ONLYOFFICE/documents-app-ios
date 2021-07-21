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
            var viewModels: [(ASCSharingRightHolderViewModel, IsSelected)] = []
            let users = response.users.sorted(by: { $0.userName ?? "" < $1.userName ?? "" })
            let usersIdsSet: Set<String> = Set(response.sharedEntities.map({ $0.user?.userId ?? nil }).compactMap({ $0 }))
            
            let currentUserId = response.currentUser?.userId
            let entityOwnerUserId = response.entityOwner?.userId
            
            for user in users {
                let isCurrentUser = currentUserId != nil && currentUserId == user.userId
                let isEnityOwner = entityOwnerUserId != nil && entityOwnerUserId == user.userId
                
                if isCurrentUser || isEnityOwner {
                    continue
                }
                
                var isSelected = false
                
                if let id = user.userId, usersIdsSet.contains(id) {
                    isSelected = true
                }
                
                let firstName = user.firstName ?? ""
                let lastName = user.lastName ?? ""
                let fullName = "\(lastName) \(firstName)".trimmed
                
                let viewModel = ASCSharingRightHolderViewModel(
                    id: user.userId ?? "",
                    avatarUrl: user.avatar,
                    name: fullName,
                    department: user.department,
                    isOwner: false,
                    rightHolderType: .user,
                    access: nil)
                
                viewModels.append((viewModel, isSelected))
                
            }
            viewController?.displayData(viewModelType: .displayUsers(.init(users: viewModels)))
        case .presentGroups(response: let response):
            var viewModels: [(ASCSharingRightHolderViewModel, IsSelected)] = []
            let groups = response.groups.sorted(by: { $0.name ?? "" < $1.name ?? "" })
            let groupIdsSet = Set(response.sharedEntities.map({ $0.group?.id }).compactMap({ $0 }))
            for group in groups {
                var isSelected = false
                
                if let id = group.id, groupIdsSet.contains(id) {
                    isSelected = true
                }
                
                let viewModel = ASCSharingRightHolderViewModel(
                    id: group.id ?? "",
                    name: group.name ?? "",
                    isOwner: false,
                    rightHolderType: .group,
                    access: nil)
                
                viewModels.append((viewModel, isSelected))

            }
            viewController?.displayData(viewModelType: .displayGroups(.init(groups: viewModels)))
        case .presentSelected(response: let response):
            viewController?.displayData(viewModelType: .displaySelected(.init(selectedModel: response.selectedModel,
                                                                              isSelect: response.isSelect,
                                                                              type: response.type)))
        }
    }
    
}
