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
            }
        }
        struct Response {
            enum ResponseType {
                case presentShareItems(_ response: ShareSettingsResponse)
                case presentAccessProvider(_ provider: ASCSharingSettingsAccessProvider)
                case presentShareSettings(_ response: ShareSettingsResponse)
            }
            
            struct ShareSettingsResponse {
                var items: [ASCShareInfo]
            }
            
            struct ShareItemsResponse {
                
            }
        }
        struct ViewModel {
            enum ViewModelData {
                case displayShareItems(_ viewModel: ShareItemsViewModel)
                case displayAccessProvider(_ provider: ASCSharingSettingsAccessProvider)
                case displayShareSettings(_ viewModel: ShareSettingsViewModel)
            }
            
            struct ShareItemsViewModel {
                var users: [ASCSharingRightHolderViewModel]
                var groups: [ASCSharingRightHolderViewModel]
            }
            
            struct ShareSettingsViewModel {
                
            }
        }
    }
}
