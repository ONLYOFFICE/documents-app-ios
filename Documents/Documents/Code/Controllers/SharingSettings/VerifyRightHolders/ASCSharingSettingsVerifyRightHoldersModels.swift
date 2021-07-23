//
//  ASCSharingSettingsVerifyRightHoldersModels.swift
//  Documents
//
//  Created by Pavel Chernyshev on 14.07.2021.
//  Copyright (c) 2021 Ascensio System SIA. All rights reserved.
//

import UIKit

enum ASCSharingSettingsVerifyRightHolders {
    
    enum Model {
        struct Request {
            enum RequestType {
                case loadShareItems
                case loadAccessProvider
                case applyShareSettings(_ request: ApplyShareSettingsRequest)
                case accessChange(_ request: AccessChangeRequest)
                case accessRemove(_ request: AccessRemoveRequest)
            }
            
            struct ApplyShareSettingsRequest {
                var notify: Bool
                var notifyMessage: String?
            }
            
            struct AccessChangeRequest {
                var model: ASCSharingRightHolderViewModel
                var newAccess: ASCShareAccess
            }
            
            struct AccessRemoveRequest {
                var model: ASCSharingRightHolderViewModel
                var indexPath: IndexPath
            }
        }
        struct Response {
            enum ResponseType {
                case presentShareItems(_ response: ShareItemsResponse)
                case presentAccessProvider(_ provider: ASCSharingSettingsAccessProvider)
                case presentApplyingShareSettings(_ response: ApplyingShareSettingsResponse)
                case presentAccessChange(_ response: AccessChangeResponse)
                case presentAccessRemove(_ response: AccessRemoveResponse)
            }
            
            struct ShareItemsResponse {
                var items: [ASCShareInfo]
            }
            
            struct ApplyingShareSettingsResponse {
                var error: ErrorMessage?
            }
            
            struct AccessChangeResponse {
                var model: ASCSharingRightHolderViewModel
                var errorMessage: ErrorMessage?
            }
            
            struct AccessRemoveResponse {
                var indexPath: IndexPath
                var errorMessage: ErrorMessage?
            }
        }
        struct ViewModel {
            enum ViewModelData {
                case displayShareItems(_ viewModel: ShareItemsViewModel)
                case displayAccessProvider(_ provider: ASCSharingSettingsAccessProvider)
                case displayApplyShareSettings(_ viewModel: ApplyingShareSettingsViewModel)
                case displayAccessChange(_ viewModel: AccessChangeViewModel)
                case displayAccessRemove(_ viewModel: AccessRemoveViewModel)
            }
            
            struct ShareItemsViewModel {
                var users: [ASCSharingRightHolderViewModel]
                var groups: [ASCSharingRightHolderViewModel]
            }
            
            struct ApplyingShareSettingsViewModel {
                var error: ErrorMessage?
            }
            
            struct AccessChangeViewModel {
                var model: ASCSharingRightHolderViewModel
                var errorMessage: ErrorMessage?
            }
            
            struct AccessRemoveViewModel {
                var indexPath: IndexPath
                var errorMessage: ErrorMessage?
            }
        }
    }
}
