//
//  ASCSharingSettingsVerifyRightHoldersPresenter.swift
//  Documents
//
//  Created by Pavel Chernyshev on 14.07.2021.
//  Copyright (c) 2021 Ascensio System SIA. All rights reserved.
//

import UIKit

protocol ASCSharingSettingsVerifyRightHoldersPresentationLogic {
    func presentData(responseType: ASCSharingSettingsVerifyRightHolders.Model.Response.ResponseType)
}

class ASCSharingSettingsVerifyRightHoldersPresenter: ASCSharingSettingsVerifyRightHoldersPresentationLogic {
    weak var viewController: ASCSharingSettingsVerifyRightHoldersDisplayLogic?

    func presentData(responseType: ASCSharingSettingsVerifyRightHolders.Model.Response.ResponseType) {
        switch responseType {
        case let .presentShareItems(response: resopnse):
            var users: [ASCSharingRightHolderViewModel] = []
            var groups: [ASCSharingRightHolderViewModel] = []

            for sharedInfo in resopnse.items {
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
                } else if let email = sharedInfo.email {
                    id = email
                    name = email
                    rightHolderType = .email
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
                    switch rightHolderType {
                    case .user:
                        users.append(viewModel)
                    case .group:
                        groups.append(viewModel)
                    case .email:
                        users.append(viewModel)
                    default:
                        _ = viewModel
                    }
                }
            }

            viewController?.displayData(viewModelType: .displayShareItems(.init(users: users, groups: groups)))

        case let .presentAccessProvider(provider: provider):
            viewController?.displayData(viewModelType: .displayAccessProvider(provider))
        case let .presentApplyingShareSettings(response: response):
            viewController?.displayData(viewModelType: .displayApplyShareSettings(.init(error: response.error)))
        case let .presentAccessChange(response: response):
            viewController?.displayData(viewModelType: .displayAccessChange(.init(model: response.model, errorMessage: response.errorMessage)))
        case let .presentAccessRemove(response: response):
            viewController?.displayData(viewModelType: .displayAccessRemove(.init(indexPath: response.indexPath, errorMessage: response.errorMessage)))
        }
    }
}
