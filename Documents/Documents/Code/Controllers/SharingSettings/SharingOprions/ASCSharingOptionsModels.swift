//
//  ASCSharingOptionsModels.swift
//  Documents
//
//  Created by Pavel Chernyshev on 28.06.2021.
//  Copyright (c) 2021 Ascensio System SIA. All rights reserved.
//

import UIKit

enum ASCSharingOptions {
    
    enum Model {
        struct Request {
            enum RequestType {
                case loadRightHolders(entity: ASCEntity?)
            }
        }
        struct Response {
            enum ResponseType {
                case presentRightHolders(sharedInfoItems: [ASCShareInfo])
            }
        }
        struct ViewModel {
            enum ViewModelData {
                case displayRightHolders(importantRightHolders: [ASCSharingRightHolderViewModel],
                                         otherRightHolders: [ASCSharingRightHolderViewModel])
            }
        }
    }
    
}
