//
//  UITableViewCell+Extensions.swift
//  Documents
//
//  Created by Alexander Yuzhin on 20/06/2019.
//  Copyright © 2019 Ascensio System SIA. All rights reserved.
//

import UIKit

// MARK: - Methods

extension UITableViewCell {
    static func createForTableView(_ tableView: UITableView) -> UITableViewCell? {
        let className = String(describing: self)

        var cell: UITableViewCell?

        cell = tableView.dequeueReusableCell(withIdentifier: className)

        if cell == nil {
            cell = Bundle.main.loadNibNamed(className, owner: self, options: nil)?.first as? UITableViewCell
            let cellNib = UINib(nibName: className, bundle: nil)
            tableView.register(cellNib, forCellReuseIdentifier: className)
        }

        return cell
    }

    @objc func debounce(delay: Double) {
        isUserInteractionEnabled = false

        let deadline = DispatchTime.now() + delay
        DispatchQueue.main.asyncAfter(deadline: deadline) {
            self.isUserInteractionEnabled = true
        }
    }
}
