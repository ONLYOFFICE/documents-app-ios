//
//  ASCDeviceCategoryCell.swift
//  Documents
//
//  Created by Alexander Yuzhin on 13/12/2018.
//  Copyright © 2018 Ascensio System SIA. All rights reserved.
//

import UIKit

class ASCDeviceCategoryCell: UITableViewCell {
    static let identifier = String(describing: ASCDeviceCategoryCell.self)

    // MARK: - Properties

    @IBOutlet var caption: UILabel!
    @IBOutlet var categoryImage: UIImageView!

    var category: ASCCategory? {
        didSet {
            updateData()
        }
    }

    // MARK: - Lifecycle Methods

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
//
//        selectedBackgroundView = UIView()
//        selectedBackgroundView?.backgroundColor = UIColor(white: 0.95, alpha: 1)
    }

    func updateData() {
        guard let category = category else { return }

        caption?.text = category.title
        categoryImage?.image = category.image
    }
}
