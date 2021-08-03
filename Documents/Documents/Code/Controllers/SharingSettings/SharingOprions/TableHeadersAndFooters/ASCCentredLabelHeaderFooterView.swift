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
    
    let centredTextLabel = UILabel()

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        configureContents()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configureContents() {
        centredTextLabel.textAlignment = .center
        centredTextLabel.numberOfLines = 0
        centredTextLabel.translatesAutoresizingMaskIntoConstraints = false
        centredTextLabel.textColor = .lightGray

        contentView.addSubview(centredTextLabel)
        NSLayoutConstraint.activate([
            centredTextLabel.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            centredTextLabel.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            centredTextLabel.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor),
            centredTextLabel.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor)
        ])
    }
}
