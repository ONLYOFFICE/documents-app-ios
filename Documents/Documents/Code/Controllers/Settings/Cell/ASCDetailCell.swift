//
//  ASCDetailCell.swift
//  Documents
//
//  Created by Alexander Yuzhin on 29.05.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import UIKit

class ASCDetailTabelViewCellViewModel {
    var title: String?
    var detail: String?
    var detailColor: UIColor?
    var accessoryType: UITableViewCell.AccessoryType?
    var action: ASCDetailCell.ActionClousure?

    convenience init(
        title: String?,
        detail: String?,
        detailColor: UIColor = .secondaryLabel,
        accessoryType: UITableViewCell.AccessoryType? = nil,
        action: ASCDetailCell.ActionClousure?
    ) {
        self.init()
        self.title = title
        self.detail = detail
        self.detailColor = detailColor
        self.accessoryType = accessoryType
        self.action = action
    }
}

class ASCDetailCell: UITableViewCell {
    typealias ActionClousure = () -> Void

    // MARK: - Outlets

    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var detailLabel: UILabel!

    // MARK: - Properties

    private var action: ActionClousure?

    var viewModel: ASCDetailTabelViewCellViewModel? {
        didSet {
            titleLabel?.text = viewModel?.title ?? ""
            detailLabel?.text = viewModel?.detail ?? ""
            detailLabel?.textColor = viewModel?.detailColor ?? .secondaryLabel
            accessoryType = viewModel?.accessoryType ?? .none
            action = viewModel?.action
        }
    }

    // MARK: - Lifecycle Methods

    override func awakeFromNib() {
        super.awakeFromNib()
    }
}
