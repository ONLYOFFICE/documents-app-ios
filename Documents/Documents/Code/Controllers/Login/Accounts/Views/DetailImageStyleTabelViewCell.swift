//
//  DetailImageStyleTabelViewCell.swift
//  Documents-opensource
//
//  Created by Лолита Чернышева on 31.03.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import Kingfisher
import UIKit

class DetailImageStyleTabelViewCell: UITableViewCell {
    static let reuseIdentifier = String(describing: DetailImageStyleTabelViewCell.self)

    let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .body)
        return label
    }()

    let detailLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .footnote)
        label.textColor = .systemGray
        return label
    }()

    let image: UIImageView = {
        let image = UIImageView()
        return image
    }()

    let selectedMark: UIImageView = {
        let image = UIImageView()
        image.image = Asset.Images.checkmarkGreen.image
        return image
    }()

    let stack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .leading
        stack.distribution = .fillEqually
        return stack
    }()

    let metrics = Metrics()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupView()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        addSubview(image)
        addSubview(stack)
        addSubview(selectedMark)
        stack.addArrangedSubview(titleLabel)
        stack.addArrangedSubview(detailLabel)

        image.translatesAutoresizingMaskIntoConstraints = false
        stack.translatesAutoresizingMaskIntoConstraints = false
        selectedMark.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            image.centerYAnchor.constraint(equalTo: centerYAnchor),
            image.leadingAnchor.constraint(equalTo: leadingAnchor, constant: metrics.insets),
            image.widthAnchor.constraint(equalToConstant: height),
            image.heightAnchor.constraint(equalToConstant: height),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
            stack.heightAnchor.constraint(equalToConstant: height),
            stack.leadingAnchor.constraint(equalTo: image.trailingAnchor, constant: metrics.insets),
            selectedMark.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -metrics.markInsets),
            selectedMark.trailingAnchor.constraint(equalTo: image.trailingAnchor, constant: metrics.markInsets),
            selectedMark.widthAnchor.constraint(equalToConstant: height / 2),
            selectedMark.heightAnchor.constraint(equalToConstant: height / 2),
        ])

        image.layer.cornerRadius = height / 2
        image.clipsToBounds = true
    }
}

extension DetailImageStyleTabelViewCell {
    struct Metrics {
        let insets: CGFloat
        let markInsets: CGFloat

        init(insets: CGFloat = 20, markInsets: CGFloat = 5) {
            self.insets = insets
            self.markInsets = markInsets
        }
    }
}

extension DetailImageStyleTabelViewCell {
    func setup(model: AccountCellModel?) {
        guard let model else { return }
        titleLabel.text = model.name
        detailLabel.text = model.portal
        titleLabel.font = model.style.nameFont
        detailLabel.font = model.style.portalFont
        selectedMark.isHidden = !model.isActiveUser

        if let avatarUrl = model.avatarUrl {
            image.kf.indicatorType = .activity
            image.kf.apiSetImage(with: avatarUrl,
                                 placeholder: Asset.Images.avatarDefault.image)
        } else {
            image.image = Asset.Images.avatarDefault.image
        }
    }
}
