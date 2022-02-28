//
//  ASCAvatarCollectionViewCell.swift
//  Documents
//
//  Created by Alexander Yuzhin on 10/23/17.
//  Copyright © 2017 Ascensio System SIA. All rights reserved.
//

import UIKit

class ASCAvatarCollectionViewCell: UICollectionViewCell {
    @IBOutlet var imageView: UIImageView!
    static let identifier = "ASCAvatarCollectionViewCell"

    private var observerContext = 0

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        layer.cornerRadius = max(frame.size.width, frame.size.height) / 2
        layer.borderWidth = 5
        layer.borderColor = Asset.Colors.brend.color.cgColor

        addObserver(self, forKeyPath: "alpha", options: .new, context: &observerContext)
    }

    deinit {
        removeObserver(self, forKeyPath: "alpha", context: &observerContext)
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        guard context == &observerContext else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            return
        }

        layer.borderWidth = alpha * 5
        layer.borderColor = Asset.Colors.brend.color.saturate(alpha).cgColor
    }
}
