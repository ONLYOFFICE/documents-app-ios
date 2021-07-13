//
//  ASCSharingAddRightHoldersModels.swift
//  Documents
//
//  Created by Павел Чернышев on 09.07.2021.
//  Copyright (c) 2021 Ascensio System SIA. All rights reserved.
//

import UIKit

typealias IsSelected = Bool
enum ASCSharingAddRightHolders {
    
    enum Model {
        struct Request {
            enum RequestType {
                case loadUsers
                case loadGroups
                case selectViewModel(_ request: ViewModelSelectedRequest)
                case deselectViewModel(_ request: ViewModelDeselectedRequest)
            }
            
            struct ViewModelSelectedRequest {
                let selectedViewModel: ASCSharingRightHolderViewModel
                let access: ASCShareAccess
            }
            
            struct ViewModelDeselectedRequest {
                let deselectedViewModel: ASCSharingRightHolderViewModel
            }
        }
        struct Response {
            enum ResponseType {
                case presentUsers(_ response: UsersResponse)
                case presentGroups(_ response: GroupsResponse)
                case presentSelected(_ response: SelectedReponse)
            }
            
            struct UsersResponse {
                var users: [ASCUser]
                var sharedEntities: [ASCShareInfo]
            }
            
            struct GroupsResponse {
                var groups: [ASCGroup]
                var sharedEntities: [ASCShareInfo]
            }
            
            struct SelectedReponse {
                var selectedModel: ASCSharingRightHolderViewModel
                var isSelect: Bool
                var type: RightHoldersTableType
            }
        }
        struct ViewModel {
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
