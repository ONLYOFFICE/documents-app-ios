//
//  ASCSwitchCell.swift
//  Documents
//
//  Created by Alexander Yuzhin on 25.05.2022.
//  Copyright © 2022 Ascensio System SIA. All rights reserved.
//

import UIKit

class ASCSwitchCellViewModel {
    var title: String?
    var isOn: Bool?
    var enabled: Bool?
    var valueChanged: ASCSwitchCell.SwitchClousure?

    convenience init(title: String?, isOn: Bool, enabled: Bool? = nil, valueChanged: ASCSwitchCell.SwitchClousure?) {
        self.init()
        self.title = title
        self.isOn = isOn
        self.enabled = enabled
        self.valueChanged = valueChanged
    }
}

class ASCSwitchCell: UITableViewCell {
    typealias SwitchClousure = (Bool) -> Void

    // MARK: - Outlets

    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var uiSwitch: UISwitch!

    // MARK: - Properties

    var viewModel: ASCSwitchCellViewModel? {
        didSet {
            titleLabel?.text = viewModel?.title ?? ""
            uiSwitch?.isOn = viewModel?.isOn ?? false
            uiSwitch?.isEnabled = viewModel?.enabled ?? true
            valueChanged = viewModel?.valueChanged
        }
    }

    private var valueChanged: SwitchClousure?

    // MARK: - Lifecycle Methods

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    @IBAction func onValueChanged(_ sender: UISwitch) {
        valueChanged?(sender.isOn)
    }
}
