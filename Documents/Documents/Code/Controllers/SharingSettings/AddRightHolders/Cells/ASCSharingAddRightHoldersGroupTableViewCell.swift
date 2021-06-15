//
//  ASCSharingAddRightHoldersGroupTableViewCell.swift
//  Documents
//
//  Created by Павел Чернышев on 15.06.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import UIKit

class ASCSharingAddRightHoldersGroupTableViewCell: UITableViewCell, ASCReusedIdentifierProtocol, ASCViewModelSetter {

    static var reuseId: String = "GroupRightHolderCell"
    
    var viewModel: ASCSharingAddRightHoldersGroupModel? {
        didSet {
            
        }
    }
}

