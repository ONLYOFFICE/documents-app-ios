//
//  ASCCloudCategoryCell.swift
//  Documents
//
//  Created by Alexander Yuzhin on 05/12/2018.
//  Copyright © 2018 Ascensio System SIA. All rights reserved.
//

import UIKit

class ASCCloudCategoryCell: UITableViewCell {
    static let identifier = String(describing: ASCCloudCategoryCell.self)

    struct ASCCloudCategoryCellType: OptionSet {
        let rawValue: Int

        static let top = ASCCloudCategoryCellType(rawValue: 1 << 0)
        static let bottom = ASCCloudCategoryCellType(rawValue: 1 << 1)
    }

    // MARK: - Properties

    @IBOutlet var logo: UIImageView!
    @IBOutlet var title: UILabel!
    @IBOutlet var subtitle: UILabel!

    @IBOutlet var topSeparator: UIView!
    @IBOutlet var bottomSeparator: UIView!
    @IBOutlet var leftConstarintOfBottomSeparator: NSLayoutConstraint!

    var cellType: ASCCloudCategoryCellType = [] {
        didSet {
            topSeparator?.isHidden = true
            leftConstarintOfBottomSeparator?.constant = 0

            if cellType.contains(.top) {
                topSeparator?.isHidden = false
            }

            if cellType.contains(.bottom) {
                leftConstarintOfBottomSeparator?.constant = -150
            }
        }
    }

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
//        selectedBackgroundView?.backgroundColor = UIColor(white: 0.75, alpha: 1)
    }

    func updateData() {
        guard let category = category else { return }

        title?.text = category.title
        subtitle?.text = category.subtitle
        logo?.image = category.image
    }
}
