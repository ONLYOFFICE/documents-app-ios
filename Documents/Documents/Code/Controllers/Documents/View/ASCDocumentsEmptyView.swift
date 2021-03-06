//
//  ASCDocumentsEmptyView.swift
//  Documents
//
//  Created by Alexander Yuzhin on 22/03/2019.
//  Copyright © 2019 Ascensio System SIA. All rights reserved.
//

import UIKit

class ASCDocumentsEmptyView: UIView {

    enum EmptyViewState {
        case `default`, local, trash, cloud, cloudNoPermissions, search, error, networkError
    }

    // MARK: - Properties

    public var onAction: (() -> Void)?
    public var type: EmptyViewState = .default {
        didSet {
            updateType()
        }
    }

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var actionButton: UIButton!
    @IBOutlet weak var centerYConstraint: NSLayoutConstraint!

    private lazy var effectGroup: UIMotionEffectGroup = {
        let horizontalEffect = UIInterpolatingMotionEffect(
            keyPath: "center.x",
            type: .tiltAlongHorizontalAxis)
        horizontalEffect.minimumRelativeValue = -16
        horizontalEffect.maximumRelativeValue = 16

        let verticalEffect = UIInterpolatingMotionEffect(
            keyPath: "center.y",
            type: .tiltAlongVerticalAxis)
        verticalEffect.minimumRelativeValue = -16
        verticalEffect.maximumRelativeValue = 16

        $0.motionEffects = [horizontalEffect, verticalEffect]

        return $0
    }(UIMotionEffectGroup())

    // MARK: - Lifecycle Methods

    override func willMove(toWindow newWindow: UIWindow?) {
        super.willMove(toWindow: newWindow)

        if newWindow == nil {
            // UIView disappear
        } else {
            // UIView appear

            isUserInteractionEnabled = true
            actionButton?.backgroundColor = ASCConstants.Colors.brendAction
            actionButton?.layer.cornerRadius = 5

            actionButton?.layer.shadowOpacity = 1
            actionButton?.layer.shadowColor = UIColor.lightGray.cgColor
            actionButton?.layer.shadowOffset = CGSize(width: 0, height: 1)
//            actionButton?.layer.shouldRasterize = true
            actionButton?.layer.shadowRadius = 1

            actionButton?.setTitleColor(.white, for: .normal)
            actionButton?.addTarget(self, action: #selector(onActionButton), for: .touchUpInside)
            actionButton?.addTarget(self, action: #selector(onButtonTouchDown), for: .touchDown)
            actionButton?.addTarget(self, action: #selector(onButtonTouchUpOutside), for: .touchUpOutside)

            // Logo motion

//            if type == .local || type == .cloud {
//                imageView?.addMotionEffect(effectGroup)
//            }
        }
    }

    @objc func onActionButton() {
        onAction?()
        actionButton?.layer
            .animate()
            .shadowOpacity(shadowOpacity: 1)
            .start()

        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }

    @objc func onButtonTouchDown() {
        actionButton?.layer
            .animate()
            .shadowOpacity(shadowOpacity: 0)
            .start()
    }

    @objc func onButtonTouchUpOutside() {
        actionButton?.layer
            .animate()
            .shadowOpacity(shadowOpacity: 1)
            .start()
    }

    private func updateType() {
        centerYConstraint?.constant = 0
        switch type {
        case .local, .cloud:
            imageView?.image = UIImage(named: "empty-folder")
            titleLabel?.text = NSLocalizedString("This folder is empty", comment: "")
            subtitleLabel?.text = NSLocalizedString("Create new documents, spreadsheets or presentations. Create new folders to organize your files.", comment: "")
            actionButton?.setTitle(NSLocalizedString("Create", comment: ""), for: .normal)
        case .trash:
            imageView?.image = UIImage(named: "empty-trash")
            titleLabel?.text = NSLocalizedString("The trash is empty", comment: "")
            subtitleLabel?.text = NSLocalizedString("The deleted files go to the trash. You can either restore or delete them forever.", comment: "")
            actionButton?.removeFromSuperview()
        case .cloudNoPermissions:
            imageView?.image = UIImage(named: "empty-folder")
            titleLabel?.text = NSLocalizedString("This folder is empty", comment: "")
            subtitleLabel?.text = NSLocalizedString("You have read-only access to this folder. You cannot create files or folders here.", comment: "")
            actionButton?.removeFromSuperview()
        case .search:
            centerYConstraint?.constant = -150
            imageView?.image = UIImage(named: "empty-search-result")
            titleLabel?.text = NSLocalizedString("No search result", comment: "")
            subtitleLabel?.text = NSLocalizedString("No results matching your search could be found. Please try another phrase.", comment: "")
            actionButton?.removeFromSuperview()
        case .error:
            imageView?.image = UIImage(named: "empty-common-error")
            titleLabel?.text = NSLocalizedString("Oops!", comment: "")
            subtitleLabel?.text = NSLocalizedString("An unexpected error has occurred. Please try again later. Sorry for inconvenience.", comment: "")
            actionButton?.setTitle(NSLocalizedString("Try again", comment: ""), for: .normal)
        case .networkError:
            imageView?.image = UIImage(named: "empty-no-connection")
            titleLabel?.text = NSLocalizedString("No connection", comment: "")
            subtitleLabel?.text = NSLocalizedString("No network connection can be found. Please check the connection and reload the page.", comment: "")
            actionButton?.setTitle(NSLocalizedString("Reload", comment: ""), for: .normal)
        default:
            imageView?.image = UIImage(named: "empty-folder")
            titleLabel?.text = NSLocalizedString("This folder is empty", comment: "")
            subtitleLabel?.text = NSLocalizedString("Create new documents, spreadsheets or presentations. Create new folders to organize your files.", comment: "")
            actionButton?.removeFromSuperview()
        }
    }

}
