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
                case loadRightHolders(entity: ASCEntity?)
                case changeRightHolderAccess(entity: ASCEntity, rightHolder: ASCSharingRightHolderViewModel, access: ASCShareAccess)
                case clearData
            }
        }
        struct Response {
            enum ResponseType {
                case presentRightHolders(sharedInfoItems: [ASCShareInfo],
                                         currentUser: ASCUser?)
                case presentChangeRightHolderAccess(rightHolder: ASCSharingRightHolderViewModel, error: ErrorMessage?)
            }
        }
        struct ViewModel {
            enum ViewModelData {
                case displayRightHolders(importantRightHolders: [ASCSharingRightHolderViewModel],
                                         otherRightHolders: [ASCSharingRightHolderViewModel])
                case displayChangeRightHolderAccess(rightHolder: ASCSharingRightHolderViewModel, error: ErrorMessage?)
            }
        }
    }
    
}
