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
    let titleLabel: UILabel = {
        let label = UILabel()
        label.font = label.font.withSize(15)
        return label
    }()

    let detailLabel: UILabel = {
        let label = UILabel()
        label.font = label.font.withSize(13)
        label.textColor = .systemGray
        return label
    }()

    let image: UIImageView = {
        let image = UIImageView()
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
        stack.addArrangedSubview(titleLabel)
        stack.addArrangedSubview(detailLabel)

        image.translatesAutoresizingMaskIntoConstraints = false
        stack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            image.centerYAnchor.constraint(equalTo: centerYAnchor),
            image.leadingAnchor.constraint(equalTo: leadingAnchor, constant: metrics.insets),
            image.widthAnchor.constraint(equalToConstant: height - metrics.insets / 2),
            image.heightAnchor.constraint(equalToConstant: height - metrics.insets / 2),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
            stack.heightAnchor.constraint(equalToConstant: height),
            stack.leadingAnchor.constraint(equalTo: image.trailingAnchor, constant: metrics.insets),
        ])

        image.layer.cornerRadius = (height - metrics.insets / 2) / 2
        image.clipsToBounds = true
    }
}

extension DetailImageStyleTabelViewCell {
    struct Metrics {
        let insets: CGFloat

        init(insets: CGFloat = 20) {
            self.insets = insets
        }
    }
}

extension DetailImageStyleTabelViewCell {
    func setup(model: AccountCellModel?) {
        guard let model = model else { return }
        titleLabel.text = model.name
        detailLabel.text = model.email
        titleLabel.font = model.style.nameFont
        detailLabel.font = model.style.emailFont

        if let avatarUrlString = model.avatarUrlString,
           !avatarUrlString.contains("/skins/default/images/default_user_photo_size_"),
           let avatarUrl = OnlyofficeApiClient.absoluteUrl(from: URL(string: avatarUrlString))
        {
            image.kf.indicatorType = .activity
            image.kf.apiSetImage(with: avatarUrl,
                                 placeholder: Asset.Images.avatarDefault.image)
        } else {
            image.image = Asset.Images.avatarDefault.image
        }
    }
}
