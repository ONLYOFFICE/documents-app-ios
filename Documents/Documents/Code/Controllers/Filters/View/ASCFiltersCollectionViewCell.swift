//
//  ASCFiltersCollectionViewCell.swift
//  Documents
//
//  Created by Lolita Chernysheva on 30.03.2022.
//  Copyright © 2022 Ascensio System SIA. All rights reserved.
//

import UIKit

class ASCFiltersCollectionViewCell: UICollectionViewCell {
    static let identifier = String(describing: ASCFiltersCollectionViewCell.self)

    static let pillHeight: CGFloat = 32.0
    var labelText = UILabel()
    var deselectFilterBtn = UIButton()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        setupView()
        labelText.text = ""
    }

    func setLabel(_ text: String?) {
        labelText.text = text
    }

    func addDeselectFilterBtnToView() {
        addSubview(deselectFilterBtn)
        setFilterResetBtn()
        labelText.anchor(
            top: topAnchor,
            leading: leadingAnchor,
            bottom: bottomAnchor,
            trailing: deselectFilterBtn.leadingAnchor,
            padding: UIEdgeInsets(
                top: 0,
                left: 9,
                bottom: 0,
                right: 0)
        )
    }
}

private extension ASCFiltersCollectionViewCell {
    func setupView() {
        addSubview(labelText)
        backgroundColor = Asset.Colors.filterCapsule.color
        layer.cornerRadius = ASCFiltersCollectionViewCell.pillHeight / 2
        labelText.frame = bounds
        labelText.textAlignment = .center
    }

    func setFilterResetBtn() {
        deselectFilterBtn.anchor(
            top: topAnchor,
            bottom: bottomAnchor,
            trailing: trailingAnchor,
            padding: UIEdgeInsets(
                top: 8,
                left: 0,
                bottom: 8,
                right: 8),
            size: CGSize(width: 16, height: 16)
        )
        deselectFilterBtn.setImage(Asset.Images.tagClose.image, for: .normal)
    }
}
