//
//  ASCFiltersCollectionViewCell.swift
//  Documents
//
//  Created by Lolita Chernysheva on 30.03.2022.
//  Copyright © 2022 Ascensio System SIA. All rights reserved.
//

import UIKit

final class ASCFiltersCollectionViewCell: UICollectionViewCell {
    static let identifier = String(describing: ASCFiltersCollectionViewCell.self)
    static let pillHeight: CGFloat = 32.0

    // MARK: Subviews

    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 0
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private let label: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let button: UIButton = {
        let btn = UIButton()
        btn.setImage(Asset.Images.tagClose.image, for: .normal)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    var handlerConfiguration: HandlerConfiguration = .clean

    // MARK: Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Public

    func configure(model: FilterViewModel) {
        label.text = model.filterName
        label.textColor = model.isSelected ? .white : model.defaultTextColor
        contentView.backgroundColor = model.isSelected
            ? Asset.Colors.brend.color
            : Asset.Colors.filterCapsule.color
        button.isHidden = !model.isFilterResetBtnShowen
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        label.text = nil
        label.textColor = nil
        contentView.backgroundColor = .clear
        button.isHidden = true
        handlerConfiguration = .clean
    }

    // MARK: Setup

    private func setupView() {
        contentView.layer.cornerRadius = ASCFiltersCollectionViewCell.pillHeight / 2
        contentView.clipsToBounds = true
        contentView.addSubview(stackView)
        stackView.addArrangedSubview(label)
        stackView.addArrangedSubview(button)
        stackView.anchor(
            top: contentView.topAnchor,
            leading: contentView.leadingAnchor,
            bottom: contentView.bottomAnchor,
            trailing: contentView.trailingAnchor,
            padding: .init(top: 0, left: 8, bottom: 0, right: 8),
            size: .init(width: 0, height: Self.pillHeight)
        )
        button.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
        button.anchor(size: .init(width: 16, height: 16))
        let tap = UITapGestureRecognizer(target: self, action: #selector(cellTapped))
        contentView.addGestureRecognizer(tap)
    }

    // MARK: Actions

    @objc private func buttonTapped() {
        handlerConfiguration.onButtonTap?()
    }

    @objc private func cellTapped() {
        handlerConfiguration.onTap?()
    }
}

// MARK: - HandlerConfiguration

extension ASCFiltersCollectionViewCell {
    struct HandlerConfiguration {
        var onTap: (() -> Void)? = nil
        var onButtonTap: (() -> Void)? = nil

        static let clean = HandlerConfiguration()
    }
}
