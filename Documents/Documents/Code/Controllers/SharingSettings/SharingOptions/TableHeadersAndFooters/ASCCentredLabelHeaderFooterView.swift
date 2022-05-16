//
//  ASCCentredLabelHeaderFooterView.swift
//  Documents
//
//  Created by Павел Чернышев on 29.07.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import UIKit

class ASCCentredLabelHeaderFooterView: UITableViewHeaderFooterView, ASCReusedIdentifierProtocol {
    static var reuseId: String = "ASCCentredLabelHeaderFooterView"

    lazy var centredTextLabel: UILabel = {
        $0.textStyle = .placeholderRegular
        $0.textAlignment = .center
        $0.numberOfLines = 0
        return $0
    }(UILabel())

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        configureContents()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configureContents() {
        centredTextLabel.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(centredTextLabel)
        NSLayoutConstraint.activate([
            centredTextLabel.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            centredTextLabel.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            centredTextLabel.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor),
            centredTextLabel.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor),
        ])
    }
}
