//
//  ASCPasscodeLockSplashView.swift
//  Documents
//
//  Created by Alexander Yuzhin on 5/22/17.
//  Copyright © 2017 Ascensio System SIA. All rights reserved.
//

import UIKit

class ASCPasscodeLockSplashView: UIView {
    // MARK: - Properties

    fileprivate lazy var logo: UIImageView = {
        let image = Asset.Images.passcodeLockSplash.image
        let view = UIImageView(image: image)
        view.contentMode = UIView.ContentMode.center
        view.translatesAutoresizingMaskIntoConstraints = false

        return view
    }()

    fileprivate lazy var blur: UIVisualEffectView = {
        var view = UIVisualEffectView(effect: UIBlurEffect(style: .extraLight))
        view.frame = self.frame
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        return view
    }()

    // MARK: - Lifecycle Methods

    override init(frame: CGRect) {
        super.init(frame: frame)

        if false, !UIAccessibility.isReduceTransparencyEnabled {
            backgroundColor = .clear
            addSubview(blur)
        } else {
            if #available(iOS 13.0, *) {
                backgroundColor = .secondarySystemBackground
            } else {
                backgroundColor = .white
            }
        }

        addSubview(logo)

        setupLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
    }

    convenience init() {
        self.init(frame: UIScreen.main.bounds)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    fileprivate func setupLayout() {
        logo.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        logo.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
    }
}
