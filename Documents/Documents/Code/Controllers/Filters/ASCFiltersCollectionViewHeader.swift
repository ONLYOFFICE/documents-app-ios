//
//  ASCFiltersCollectionViewHeader.swift
//  Documents
//
//  Created by Лолита Чернышева on 31.03.2022.
//  Copyright © 2022 Ascensio System SIA. All rights reserved.
//

import UIKit

class ASCFiltersCollectionViewHeader: UICollectionReusableView {
    static let identifier = "ASCFiltersCollectionViewHeader"
    private let headerLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        label.textAlignment = .left
        label.textColor = .black
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
