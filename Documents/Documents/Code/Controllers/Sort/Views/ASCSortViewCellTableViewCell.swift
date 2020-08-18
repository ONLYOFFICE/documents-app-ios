//
//  ASCSortViewCellTableViewCell.swift
//  Documents
//
//  Created by Alexander Yuzhin on 31/05/2018.
//  Copyright © 2018 Ascensio System SIA. All rights reserved.
//

import UIKit

class ASCSortViewCell: UITableViewCell {

    // MARK: - Properties

    @IBOutlet weak var ascendingSwitch: UISwitch!
    var onAscendingChange: ((Bool) -> Void)?

    // MARK: - Lifecycle Methods

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        selectedBackgroundView = UIView()
        selectedBackgroundView?.backgroundColor = UIColor(named: "table-cell-selected")
    }

    // MARK: - Actions

    @IBAction func onAscendingSwitch(_ sender: UISwitch) {
        onAscendingChange?(sender.isOn)
    }
}
