//
//  ASCSharingAddRightHoldersModels.swift
//  Documents
//
//  Created by Павел Чернышев on 09.07.2021.
//  Copyright (c) 2021 Ascensio System SIA. All rights reserved.
//

import UIKit

enum ASCSharingAddRightHolders {
    
    enum Model {
        struct Request {
            enum RequestType {
                case loadUsers
                case loadGroups
            }
        }
        struct Response {
            enum ResponseType {
                case presentUsers(_ response: UsersResponse)
                case presentGroups(_ response: GroupsResponse)
            }
            
            struct UsersResponse {
                var users: [ASCUser]
                var sharedEntities: [ASCShareInfo]
            }
            
            struct GroupsResponse {
                var groups: [ASCGroup]
                var sharedEntities: [ASCShareInfo]
            }
        }
        struct ViewModel {
            enum ViewModelData {
                case displayUsers(_ viewModel: UsersViewModel)
                case displayGroups(_ viewModel: GroupsViewModel)
            }
            
            struct UsersViewModel {
                var users: [ASCSharingRightHolderViewModel]
                var selectedIndexes: [Int]
            }
            
            struct GroupsViewModel {
                var groups: [ASCSharingRightHolderViewModel]
                var selectedIndexes: [Int]
            }
        }
    }
}
