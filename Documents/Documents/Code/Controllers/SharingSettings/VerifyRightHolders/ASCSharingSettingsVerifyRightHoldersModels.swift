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
                case applyShareSettings
                case accessChange(_ request: AccessChangeRequest)
            }
            
            struct AccessChangeRequest {
                var model: ASCSharingRightHolderViewModel
                var newAccess: ASCShareAccess
            }
        }
        struct Response {
            enum ResponseType {
                case presentShareItems(_ response: ShareSettingsResponse)
                case presentAccessProvider(_ provider: ASCSharingSettingsAccessProvider)
                case presentShareSettings(_ response: ShareSettingsResponse)
                case presentAccessChange(_ response: AccessChangeResponse)
            }
            
            struct ShareSettingsResponse {
                var items: [ASCShareInfo]
            }
            
            struct ShareItemsResponse {
                
            }
            
            struct AccessChangeResponse {
                var model: ASCSharingRightHolderViewModel
                var errorMessage: ErrorMessage?
            }
        }
        struct ViewModel {
            enum ViewModelData {
                case displayShareItems(_ viewModel: ShareItemsViewModel)
                case displayAccessProvider(_ provider: ASCSharingSettingsAccessProvider)
                case displayApplyShareSettings(_ viewModel: ShareSettingsViewModel)
                case displayAccessChange(_ viewModel: AccessChangeViewModel)
            }
            
            struct ShareItemsViewModel {
                var users: [ASCSharingRightHolderViewModel]
                var groups: [ASCSharingRightHolderViewModel]
            }
            
            struct ShareSettingsViewModel {
                
            }
            
            struct AccessChangeViewModel {
                var model: ASCSharingRightHolderViewModel
                var errorMessage: ErrorMessage?
            }
        }
    }
}
