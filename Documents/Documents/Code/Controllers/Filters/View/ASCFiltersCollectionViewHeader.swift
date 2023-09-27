//
//  ASCFiltersCollectionViewHeader.swift
//  Documents
//
//  Created by Lolita Chernysheva on 31.03.2022.
//  Copyright © 2022 Ascensio System SIA. All rights reserved.
//

import UIKit

class ASCFiltersCollectionViewHeader: UICollectionReusableView {
    static let identifier = String(describing: ASCFiltersCollectionViewHeader.self)

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = Asset.Colors.tableCategoryBackground.color
        addSubview(headerLabel)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private let headerLabel: UILabel = {
        let label = UILabel()
        label.textStyle = .headline
        label.textAlignment = .left
        return label
    }()

    func setupLabel(_ text: String) {
        headerLabel.text = text
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        headerLabel.frame = bounds
    }
}
