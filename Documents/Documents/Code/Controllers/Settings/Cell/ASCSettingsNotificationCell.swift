//
//  ASCSettingsNotificationCell.swift
//  Documents-develop
//
//  Created by Alexander Yuzhin on 24.05.2022.
//  Copyright © 2022 Ascensio System SIA. All rights reserved.
//

import UIKit

class ASCSettingsNotificationCell: UITableViewCell {
    static let identifier = String(describing: ASCSettingsNotificationCell.self)

    // MARK: - Properties

    private lazy var errorIconView: UIImageView = {
        if #available(iOS 13.0, *) {
            $0.image = UIImage(systemName: "info.circle.fill")?
                .withTintColor(.systemPink, renderingMode: .alwaysOriginal)
            $0.contentMode = .center
        }
        return $0
    }(UIImageView(frame: CGRect(x: 0, y: 0, width: 18, height: 18)))

    var displayError: Bool = false {
        didSet {
            updateView()
        }
    }

    // MARK: - Lifecycle Methods

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    private func updateView() {
        if displayError {
            if errorIconView.superview == nil {
                contentView.addSubview(errorIconView)
                errorIconView.translatesAutoresizingMaskIntoConstraints = false
                
                let top = errorIconView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 0)
                let bottom = errorIconView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: 0)
                let right = errorIconView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10)
                
                NSLayoutConstraint.activate([top, bottom, right])
            }
        } else {
            errorIconView.removeFromSuperview()
        }
    }
}
