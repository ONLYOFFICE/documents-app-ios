//
//  ASCFiltersCollectionViewCell.swift
//  Documents
//
//  Created by Лолита Чернышева on 30.03.2022.
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
        labelText.anchor(top: topAnchor,
                         left: leftAnchor,
                         bottom: bottomAnchor,
                         right: deselectFilterBtn.leftAnchor,
                         leftConstant: 9)
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
        deselectFilterBtn.anchor(top: topAnchor,
                                 bottom: bottomAnchor,
                                 right: rightAnchor,
                                 topConstant: 8,
                                 bottomConstant: 8,
                                 rightConstant: 8,
                                 widthConstant: 16,
                                 heightConstant: 16)
        deselectFilterBtn.setImage(Asset.Images.closeButton.image, for: .normal)
    }
}
