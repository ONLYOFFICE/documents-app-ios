//
//  ASCSharingAddRightHoldersUserTableViewCell.swift
//  Documents
//
//  Created by Павел Чернышев on 15.06.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import UIKit

class ASCSharingAddRightHoldersUserTableViewCell: UITableViewCell, ASCReusedIdentifierProtocol, ASCViewModelSetter {
    
    static var reuseId: String = "UserRightHolderCell"
    
    var viewModel: ASCSharingAddRightHolderUserModel? {
        didSet {
            
        }
    }

}
