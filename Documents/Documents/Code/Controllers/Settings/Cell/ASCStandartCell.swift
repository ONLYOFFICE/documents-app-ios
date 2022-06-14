//
//  ASCStandartCell.swift
//  Documents
//
//  Created by Alexander Yuzhin on 13.06.2022.
//  Copyright © 2022 Ascensio System SIA. All rights reserved.
//

import UIKit

class ASCStandartCellViewModel {
    var title: String?
    var accessoryType: UITableViewCell.AccessoryType?
    var action: ASCStandartCell.ActionClousure?

    convenience init(title: String?, action: ASCStandartCell.ActionClousure?, accessoryType: UITableViewCell.AccessoryType? = nil) {
        self.init()
        self.title = title
        self.accessoryType = accessoryType
        self.action = action
    }
}

class ASCStandartCell: UITableViewCell {
    typealias ActionClousure = () -> Void

    // MARK: - Properties

    private var action: ActionClousure?

    var viewModel: ASCStandartCellViewModel? {
        didSet {
            textLabel?.text = viewModel?.title ?? ""
            accessoryType = viewModel?.accessoryType ?? .none
            action = viewModel?.action
        }
    }

    // MARK: - Lifecycle Methods

    override func awakeFromNib() {
        super.awakeFromNib()
    }
}
