//
//  UINavigationItem+Extensions.swift
//  Documents
//
//  Created by Pavel Chernyshev on 21.07.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import Foundation
import UIKit

extension UINavigationItem {
    func setTitle(_ title: String, subtitle: String?) {
        let titleLabel = UILabel()
        let appearance = UINavigationBar.appearance()
        var color: UIColor = .white
        if #available(iOS 13.0, *) {
            color = .label
        } else {
            color = .white
        }

        let textColor = appearance.titleTextAttributes?[NSAttributedString.Key.foregroundColor] as? UIColor ?? color

        titleLabel.text = title
        titleLabel.font = .preferredFont(forTextStyle: UIFont.TextStyle.headline)
        titleLabel.textColor = textColor

        let subtitleLabel = UILabel()
        subtitleLabel.text = subtitle
        subtitleLabel.font = .preferredFont(forTextStyle: UIFont.TextStyle.footnote)
        subtitleLabel.textColor = textColor.withAlphaComponent(0.60)

        let stackView = UIStackView(arrangedSubviews: [titleLabel] + ((subtitle != nil) ? [subtitleLabel] : []))
        stackView.distribution = .equalCentering
        stackView.alignment = .center
        stackView.axis = .vertical

        titleView = stackView
    }
}
