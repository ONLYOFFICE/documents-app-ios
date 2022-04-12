//
//  ASCFiltersCollectionViewHeader.swift
//  Documents
//
//  Created by Лолита Чернышева on 31.03.2022.
//  Copyright © 2022 Ascensio System SIA. All rights reserved.
//

import UIKit

class ASCFiltersCollectionViewHeader: UICollectionReusableView {
    static let identifier = String(describing: ASCFiltersCollectionViewHeader.self)

    private let headerLabel: UILabel = {
        let label = UILabel()
        label.textStyle = .headline
        return label
    }()

    func setupLabel(_ text: String) {
        headerLabel.text = text
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        addSubview(headerLabel)
        headerLabel.frame = bounds
    }
}
