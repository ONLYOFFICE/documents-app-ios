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
        
        labelText.translatesAutoresizingMaskIntoConstraints = false
        let top = labelText.topAnchor.constraint(equalTo: topAnchor)
        let left = labelText.leadingAnchor.constraint(equalTo: leadingAnchor)
        let bottom = labelText.bottomAnchor.constraint(equalTo: bottomAnchor)
        let right = labelText.trailingAnchor.constraint(equalTo: deselectFilterBtn.leadingAnchor, constant: -9)
        
        NSLayoutConstraint.activate([top, left, bottom, right])
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
        
        deselectFilterBtn.translatesAutoresizingMaskIntoConstraints = false
        
        let top = deselectFilterBtn.topAnchor.constraint(equalTo: topAnchor, constant: 8)
        let bottom = deselectFilterBtn.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8)
        let right = deselectFilterBtn.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8)
        let width = deselectFilterBtn.widthAnchor.constraint(equalToConstant: 16)
        let height = deselectFilterBtn.heightAnchor.constraint(equalToConstant: 16)
        
        NSLayoutConstraint.activate([top, bottom, right, width, height])
        deselectFilterBtn.setImage(Asset.Images.tagClose.image, for: .normal)
    }
}
