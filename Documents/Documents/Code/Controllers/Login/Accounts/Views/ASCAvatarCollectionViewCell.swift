//
//  ASCAvatarCollectionViewCell.swift
//  Documents
//
//  Created by Alexander Yuzhin on 10/23/17.
//  Copyright © 2017 Ascensio System SIA. All rights reserved.
//

import UIKit

class ASCAvatarCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var imageView: UIImageView!
    static let identifier = "ASCAvatarCollectionViewCell"

    private var observerContext = 0

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.layer.cornerRadius = max(frame.size.width, frame.size.height) / 2
        self.layer.borderWidth = 5
        self.layer.borderColor = ASCConstants.Colors.brend.cgColor

        addObserver(self, forKeyPath: "alpha", options: .new, context: &observerContext)
    }

    deinit {
        removeObserver(self, forKeyPath: "alpha", context: &observerContext)
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard context == &observerContext else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            return
        }

        layer.borderWidth = alpha * 5
        layer.borderColor = ASCConstants.Colors.brend.saturate(alpha).cgColor
    }
}
