//
//  ASCSharingOptionsModels.swift
//  Documents
//
//  Created by Pavel Chernyshev on 28.06.2021.
//  Copyright (c) 2021 Ascensio System SIA. All rights reserved.
//

import UIKit

typealias ErrorMessage = String

enum ASCSharingOptions {
    
    enum Model {
        struct Request {
            enum RequestType {
                case loadRightHolders(_ request: LoadRightHoldersRequest)
                case changeRightHolderAccess(_ request: ChangeRightHolderAccessRequest)
                case clearData
            }
            
            struct LoadRightHoldersRequest {
                var entity: ASCEntity?
            }
            
            struct ChangeRightHolderAccessRequest {
                var entity: ASCEntity
                var rightHolder: ASCSharingRightHolder
                var access: ASCShareAccess
            }
            
        }
        struct Response {
            enum ResponseType {
                case presentRightHolders(_ response: RightHoldersResponse)
                case presentChangeRightHolderAccess(_ response: ChangeRightHolderAccessResponse)
            }
            
            struct RightHoldersResponse {
                var sharedInfoItems: [ASCShareInfo]
                var currentUser: ASCUser?
                var internalLink: String?
                var externalLink: ASCSharingOprionsExternalLink?
            }
            
            struct ChangeRightHolderAccessResponse {
                var rightHolder: ASCSharingRightHolder
                var error: ErrorMessage?
            }
            
        }
        struct ViewModel {
            enum ViewModelData {
                case displayRightHolders(_ viewModel: RightHoldersViewModel)
                case displayChangeRightHolderAccess(_ viewModel: ChangeRightHolderAccessViewModel)
            }
            
            struct RightHoldersViewModel {
                var internalLink: String?
                var externalLink: ASCSharingOprionsExternalLink?
                var importantRightHolders: [ASCSharingRightHolderViewModel]
                var otherRightHolders: [ASCSharingRightHolderViewModel]
            }
            
            struct ChangeRightHolderAccessViewModel {
                var rightHolder: ASCSharingRightHolder
                var error: ErrorMessage?
            }
        }
    }
}
