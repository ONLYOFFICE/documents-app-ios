//
//  ASCFolderViewCell.swift
//  Documents
//
//  Created by Alexander Yuzhin on 25.06.2024.
//  Copyright © 2024 Ascensio System SIA. All rights reserved.
//

import UIKit

final class ASCFolderViewCell: UICollectionViewCell & ASCEntityViewCellProtocol {
    static let identifier = String(describing: ASCFolderViewCell.self)

    // MARK: - Properties

    var entity: ASCEntity? {
        didSet {
            updateData()
        }
    }

    var provider: ASCFileProviderProtocol?

    var layoutType: ASCEntityViewLayoutType = .list {
        didSet {
            buildView()
        }
    }

    private lazy var titleLabel: UILabel = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        return $0
    }(UILabel())

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
//        backgroundColor = .red

        for view in contentView.subviews {
            view.removeFromSuperview()
        }

        contentView.addSubview(titleLabel)
        titleLabel.fillToSuperview()
    }

    private func updateData() {
        guard let folder = entity as? ASCFolder else { return }
        titleLabel.text = folder.title
    }
}
