//
//  ASCSharingAddRightHoldersModels.swift
//  Documents
//
//  Created by Pavel Chernyshev on 09.07.2021.
//  Copyright (c) 2021 Ascensio System SIA. All rights reserved.
//

import UIKit

typealias IsSelected = Bool
enum ASCSharingAddRightHolders {
    enum Model {
        enum Request {
            enum RequestType {
                case loadUsers(preloadRightHolders: Bool, hideUsersWhoHasRights: Bool, showOnlyAdmins: Bool)
                case loadGroups
                case selectViewModel(_ request: ViewModelSelectedRequest)
                case deselectViewModel(_ request: ViewModelDeselectedRequest)
                case changeAccessForSelected(_ request: ASCShareAccess)
                case changeOwner(_ userId: String, _ handler: ASCEntityHandler?)
            }

            struct ViewModelSelectedRequest {
                let selectedViewModel: ASCSharingRightHolderViewModel
                let access: ASCShareAccess
            }

            struct ViewModelDeselectedRequest {
                let deselectedViewModel: ASCSharingRightHolderViewModel
            }
        }

        enum Response {
            enum ResponseType {
                case presentUsers(_ response: UsersResponse)
                case presentGroups(_ response: GroupsResponse)
                case presentSelected(_ response: SelectedReponse)
            }

            struct UsersResponse {
                var users: [ASCUser]
                var sharedEntities: [OnlyofficeShare]
                var entityOwner: ASCUser?
                var currentUser: ASCUser?
            }

            struct GroupsResponse {
                var groups: [ASCGroup]
                var sharedEntities: [OnlyofficeShare]
            }

            struct SelectedReponse {
                var selectedModel: ASCSharingRightHolderViewModel
                var isSelect: Bool
                var type: RightHoldersTableType
            }
        }

        enum ViewModel {
            enum ViewModelBase {
                case displayUsers(_ viewModel: UsersViewModel)
                case displaySelected(_ viewModel: SelectedViewModel)
            }

            enum ViewModelData {
                case displayUsers(_ viewModel: UsersViewModel)
                case displayGroups(_ viewModel: GroupsViewModel)
                case displaySelected(_ viewModel: SelectedViewModel)
            }

            struct UsersViewModel {
                var users: [(ASCSharingRightHolderViewModel, IsSelected)]
            }

            struct GroupsViewModel {
                var groups: [(ASCSharingRightHolderViewModel, IsSelected)]
            }

            struct SelectedViewModel {
                var selectedModel: ASCSharingRightHolderViewModel
                var isSelect: Bool
                var type: RightHoldersTableType
            }
        }
    }
}
