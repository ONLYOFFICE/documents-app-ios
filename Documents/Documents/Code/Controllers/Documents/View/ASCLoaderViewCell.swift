//
//  ASCLoaderViewCell.swift
//  Documents
//
//  Created by Alexander Yuzhin on 28.06.2024.
//  Copyright © 2024 Ascensio System SIA. All rights reserved.
//

import UIKit

final class ASCLoaderViewCell: UICollectionViewCell {
    static let identifier = String(describing: ASCLoaderViewCell.self)

    // MARK: - Parameters

    private lazy var indicator: UIActivityIndicatorView = {
        $0
    }(UIActivityIndicatorView(style: .medium))

    // MARK: - Lifecycle Methods

    override init(frame: CGRect) {
        super.init(frame: frame)
        buildView()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func buildView() {
        for view in contentView.subviews {
            view.removeFromSuperview()
        }

        contentView.addSubview(indicator)
        indicator.anchorCenterYToSuperview()
        indicator.centerXAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.centerXAnchor, constant: 0).isActive = true
    }

    func startActivity() {
        indicator.startAnimating()
    }
}
