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

    let entity: ASCEntity

    init(entity: ASCEntity) {
        self.entity = entity
    }

    func presentData(response: ASCSharingOptions.Model.Response.ResponseType) {
        switch response {
        case let .presentRightHolders(rightHoldersResponse: rightHoldersResult):
            switch rightHoldersResult {
            case let .success(rightHoldersResponse):
                let sharedInfoItems = rightHoldersResponse.sharedInfoItems
                let currentUser = rightHoldersResponse.currentUser
                let isImportant: (OnlyofficeShare) -> Bool = { shareInfo in
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

                for sharedInfo in sharedInfoItems {
                    var sharedInfo = sharedInfo
                    if !sharedInfo.locked, let folder = entity as? ASCFolder, folder.isRoom {
                        sharedInfo.locked = !folder.security.editAccess
                    }
                    if var viewModel = makeRightHolderViewModel(fromShareInfo: sharedInfo) {
                        if isImportant(sharedInfo) {
                            viewModel.isImportant = true
                            imprtantRightHolders.append(viewModel)
                        } else {
                            otherRightHolders.append(viewModel)
                        }
                    }
                }
                viewController?.display(viewModel: .displayRightHolders(.init(internalLink: rightHoldersResponse.internalLink,
                                                                              externalLink: rightHoldersResponse.externalLink,
                                                                              importantRightHolders: imprtantRightHolders,
                                                                              otherRightHolders: otherRightHolders)))
            case let .failure(error):
                viewController?.display(viewModel: .displayRightHolders(.init(internalLink: nil,
                                                                              externalLink: nil,
                                                                              importantRightHolders: [],
                                                                              otherRightHolders: [])))
                viewController?.display(viewModel: .displayError(error.localizedDescription))
            }
        case let .presentChangeRightHolderAccess(changeRightHolderResponse: changeRightHolderResponse):
            viewController?.display(viewModel: .displayChangeRightHolderAccess(.init(rightHolder: changeRightHolderResponse.rightHolder,
                                                                                     error: changeRightHolderResponse.error)))
        case let .presentRemoveRightHolderAccess(removeRightHolderResponse: removeRightHolderResponse):
            if removeRightHolderResponse.error == nil {
                viewController?.display(viewModel: .displayRemoveRightHolderAccess(.init(indexPath: removeRightHolderResponse.indexPath, rightHolderViewModel: nil, error: nil)))
            } else {
                let rightHolderViewModel = makeRightHolderViewModel(fromShareInfo: removeRightHolderResponse.rightHolderShareInfo)
                viewController?.display(viewModel: .displayRemoveRightHolderAccess(.init(indexPath: removeRightHolderResponse.indexPath,
                                                                                         rightHolderViewModel: rightHolderViewModel,
                                                                                         error: removeRightHolderResponse.error)))
            }
        }
    }

    private func makeRightHolderViewModel(fromShareInfo sharedInfo: OnlyofficeShare) -> ASCSharingRightHolderViewModel? {
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
        guard let unwrapedId = id else { return nil }
        return ASCSharingRightHolderViewModel(id: unwrapedId,
                                              avatarUrl: avatarUrl,
                                              name: name,
                                              department: sharedInfo.user?.department,
                                              isOwner: sharedInfo.owner,
                                              rightHolderType: rightHolderType ?? .user,
                                              access: access)
    }
}
