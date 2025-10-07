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
        case `default`
        case local
        case trash
        case cloud
        case cloudNoPermissions
        case publicRoom
        case publicRoomNoPermissions
        case collaborationRoom
        case collaborationRoomNoPermissions
        case customRoom
        case customRoomNoPermissions
        case formFillingRoom
        case formFillingNoPermissions
        case virtualDataRoom
        case virtualDataRoomNoPermissions
        case docspaceNoPermissions
        case search
        case usersNotFound
        case guestsNotFound
        case usersNotFoundForDocSpaceRoomOwner
        case error
        case networkError
        case paymentRequired
        case docspaceArchive
        case recentlyAccessibleViaLink
        case formFillingRoomSubfolder
        case roomTemplates
        case docspaceEmptyRooms
        case docspaceEmptyRoomsNoPermissions
    }

    // MARK: - Properties

    var onAction: (() -> Void)?
    var menuForType: [EmptyViewState: UIMenu] = [:]
    var type: EmptyViewState = .default {
        didSet {
            updateType()
        }
    }

    @IBOutlet var imageView: UIImageView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var subtitleLabel: UILabel!
    @IBOutlet var actionButton: ASCButtonStyle!
    @IBOutlet var centerYConstraint: NSLayoutConstraint!

    private lazy var effectGroup: UIMotionEffectGroup = {
        let horizontalEffect = UIInterpolatingMotionEffect(
            keyPath: "center.x",
            type: .tiltAlongHorizontalAxis
        )
        horizontalEffect.minimumRelativeValue = -16
        horizontalEffect.maximumRelativeValue = 16

        let verticalEffect = UIInterpolatingMotionEffect(
            keyPath: "center.y",
            type: .tiltAlongVerticalAxis
        )
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

            actionButton?.styleType = type.actionButtonStyleType
            actionButton?.addTarget(self, action: #selector(onActionButton), for: .touchUpInside)
            actionButton?.addTarget(self, action: #selector(onButtonTouchDown), for: .touchDown)
            actionButton?.addTarget(self, action: #selector(onButtonTouchUpOutside), for: .touchUpOutside)
            customizeButtonTitle()

            subtitleLabel?.numberOfLines = 8
        }
    }

    @objc func onActionButton() {
        onAction?()
        if actionButton?.styleType == .action {
            actionButton?.layer
                .animate()
                .shadowOpacity(shadowOpacity: 1)
                .start()

            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.prepare()
            generator.impactOccurred()
        }
    }

    @objc func onButtonTouchDown() {
        if actionButton?.styleType == .action {
            actionButton?.layer
                .animate()
                .shadowOpacity(shadowOpacity: 0)
                .start()
        }
    }

    @objc func onButtonTouchUpOutside() {
        if actionButton?.styleType == .action {
            actionButton?.layer
                .animate()
                .shadowOpacity(shadowOpacity: 1)
                .start()
        }
    }

    private func customizeButtonTitle() {
        if actionButton?.styleType == .action {
            actionButton?.setTitleColor(.white, for: .normal)
        }
    }

    private func updateType() {
        centerYConstraint?.constant = -50

        switch type {
        case .local, .cloud:
            imageView?.image = Asset.Images.emptyFolder.image
            titleLabel?.text = NSLocalizedString("This folder is empty", comment: "")
            subtitleLabel?.text = NSLocalizedString("Create new documents, spreadsheets or presentations. Create new folders to organize your files.", comment: "")
            actionButton?.setTitle(NSLocalizedString("Create", comment: ""), for: .normal)
        case .trash:
            imageView?.image = Asset.Images.emptyTrash.image
            titleLabel?.text = NSLocalizedString("The trash is empty", comment: "")
            subtitleLabel?.text = NSLocalizedString("The deleted files go to the trash. You can either restore or delete them forever.", comment: "")
            actionButton?.removeFromSuperview()
        case .cloudNoPermissions:
            imageView?.image = Asset.Images.emptyFolder.image
            titleLabel?.text = NSLocalizedString("This folder is empty", comment: "")
            subtitleLabel?.text = NSLocalizedString("You have read-only access to this folder. You cannot create files or folders here.", comment: "")
            actionButton?.removeFromSuperview()
        case .docspaceNoPermissions:
            imageView?.image = Asset.Images.emptyFolder.image
            titleLabel?.text = NSLocalizedString("No docs here yet", comment: "")
            subtitleLabel?.text = NSLocalizedString("Files and folders uploaded by admins will appear here.", comment: "")
            actionButton?.removeFromSuperview()
        case .search:
            centerYConstraint?.constant = -150
            imageView?.image = Asset.Images.emptySearchResult.image
            titleLabel?.text = NSLocalizedString("No search result", comment: "")
            subtitleLabel?.text = NSLocalizedString("No results matching your search could be found. Please try another phrase.", comment: "")
            actionButton?.removeFromSuperview()
        case .usersNotFound:
            centerYConstraint?.constant = -150
            imageView?.image = Asset.Images.emptySearchResult.image
            titleLabel?.text = NSLocalizedString("No users found", comment: "")
            subtitleLabel?.text = NSLocalizedString("The list of users previously invited to DocSpace or separate rooms will appear here.", comment: "")
            actionButton?.removeFromSuperview()
        case .guestsNotFound:
            centerYConstraint?.constant = -150
            imageView?.image = Asset.Images.emptySearchResult.image
            titleLabel?.text = NSLocalizedString("No added guests yet", comment: "")
            subtitleLabel?.text = NSLocalizedString("New guests will be added here once you invite them to the room. You can share your guests and add guests invited by others to your list.", comment: "")
            actionButton?.removeFromSuperview()
        case .usersNotFoundForDocSpaceRoomOwner:
            centerYConstraint?.constant = -150
            imageView?.image = Asset.Images.emptySearchResult.image
            titleLabel?.text = NSLocalizedString("No users found", comment: "")
            subtitleLabel?.text = NSLocalizedString("Only a room administrator or a DocSpace administrator can become the room owner.", comment: "")
            actionButton?.removeFromSuperview()
        case .error:
            imageView?.image = Asset.Images.emptyCommonError.image
            titleLabel?.text = NSLocalizedString("Oops!", comment: "")
            subtitleLabel?.text = NSLocalizedString("An unexpected error has occurred. Please try again later. Sorry for inconvenience.", comment: "")
            actionButton?.setTitle(NSLocalizedString("Try again", comment: ""), for: .normal)
        case .networkError:
            imageView?.image = Asset.Images.emptyNoConnection.image
            titleLabel?.text = NSLocalizedString("No connection", comment: "")
            subtitleLabel?.text = NSLocalizedString("No network connection can be found. Please check the connection and reload the page.", comment: "")
            actionButton?.setTitle(NSLocalizedString("Reload", comment: ""), for: .normal)
        case .paymentRequired:
            imageView?.image = Asset.Images.bussinesSubscriptionExpired.image
            titleLabel?.text = NSLocalizedString("Business subscription expired", comment: "")
            subtitleLabel?.text = NSLocalizedString("Your current tariff plan Business expired. Please renew your subscription in the account settings to be able to use your DocSpace. If you have any questions, please contact support.", comment: "")
            actionButton?.setTitle(NSLocalizedString("Renew Business plan", comment: ""), for: .normal)
        case .docspaceArchive:
            imageView?.image = Asset.Images.noFindingArchive.image
            titleLabel.text = NSLocalizedString("No archived rooms here yet", comment: "")
            subtitleLabel.text = NSLocalizedString("You can archive rooms you don’t use and restore them in your DocSpace at any moment or delete them permanently. These rooms will appear here.", comment: "")
            actionButton?.removeFromSuperview()
        case .recentlyAccessibleViaLink:
            imageView?.image = Asset.Images.emptyFolder.image
            titleLabel?.text = NSLocalizedString("No files here yet", comment: "")
            subtitleLabel?.text = NSLocalizedString("Here you will find a list of the recently opened files shared with you via an external link.", comment: "")
            actionButton?.removeFromSuperview()
        case .publicRoom:
            imageView.image = Asset.Images.welcomePublicRoom.image
            titleLabel.text = NSLocalizedString("Welcome to the Public room", comment: "")
            subtitleLabel.text = NSLocalizedString("Create or upload new files or folders to get started.", comment: "")
            actionButton.setTitle(NSLocalizedString("Create a new file", comment: ""), for: .normal)
        case .publicRoomNoPermissions:
            imageView.image = Asset.Images.emptyPublicRoom.image
            titleLabel.text = NSLocalizedString("The room is empty", comment: "")
            subtitleLabel.text = NSLocalizedString("Files and folders created or uploaded by admins will show up here.", comment: "")
            actionButton.removeFromSuperview()
        case .collaborationRoom:
            imageView.image = Asset.Images.welcomeCollaborationRoom.image
            titleLabel.text = NSLocalizedString("Welcome to the Collaboration room", comment: "")
            subtitleLabel.text = NSLocalizedString("Create or upload new files or folders to get started.", comment: "")
            actionButton.setTitle(NSLocalizedString("Create a new file", comment: ""), for: .normal)
        case .collaborationRoomNoPermissions:
            imageView.image = Asset.Images.emptyCollaborationRoom.image
            titleLabel.text = NSLocalizedString("The room is empty", comment: "")
            subtitleLabel.text = NSLocalizedString("Files and folders created or uploaded by admins will show up here.", comment: "")
            actionButton.removeFromSuperview()
        case .customRoom:
            imageView.image = Asset.Images.welcomeCustomRoom.image
            titleLabel.text = NSLocalizedString("Welcome to the Custom room", comment: "")
            subtitleLabel.text = NSLocalizedString("Create or upload new files or folders to get started.", comment: "")
            actionButton.setTitle(NSLocalizedString("Create a new file", comment: ""), for: .normal)
        case .customRoomNoPermissions:
            imageView.image = Asset.Images.emptyCustomRoom.image
            titleLabel.text = NSLocalizedString("The room is empty", comment: "")
            subtitleLabel.text = NSLocalizedString("Files and folders created or uploaded by admins will show up here.", comment: "")
            actionButton.removeFromSuperview()
        case .formFillingRoom:
            imageView.image = Asset.Images.welcomeFormFillingRoom.image
            titleLabel.text = NSLocalizedString("Welcome to the Form filling room ", comment: "")
            subtitleLabel.text = NSLocalizedString("Get started with quick actions: ", comment: "")
            actionButton.setTitle(NSLocalizedString("Upload a ready PDF form", comment: ""), for: .normal)
        case .formFillingNoPermissions:
            imageView.image = Asset.Images.emptyFormRoom.image
            titleLabel.text = NSLocalizedString("The room is empty", comment: "")
            subtitleLabel.text = NSLocalizedString("PDF forms uploaded by admins will show up here.", comment: "")
            actionButton.removeFromSuperview()
        case .formFillingRoomSubfolder:
            imageView.image = Asset.Images.emptyForms.image
            titleLabel.text = NSLocalizedString("No forms here yet", comment: "")
            subtitleLabel.text = NSLocalizedString("Upload PDF forms from DocSpace or device.", comment: "")
            actionButton.setTitle(NSLocalizedString("Upload a ready PDF form", comment: ""), for: .normal)
        case .virtualDataRoom:
            imageView.image = Asset.Images.welcomeVdr.image
            titleLabel.text = NSLocalizedString("Welcome to the Virtual Data Room", comment: "")
            subtitleLabel.text = NSLocalizedString("Get started with quick actions: ", comment: "")
            actionButton.setTitle(NSLocalizedString("Create a new file", comment: ""), for: .normal)
        case .virtualDataRoomNoPermissions:
            imageView.image = Asset.Images.emptyVdr.image
            titleLabel.text = NSLocalizedString("The room is empty", comment: "")
            subtitleLabel.text = NSLocalizedString("Files and folders created or uploaded by admins will show up here.", comment: "")
            actionButton.removeFromSuperview()
        case .roomTemplates:
            imageView.image = Asset.Images.emptyDocspace.image
            titleLabel.text = NSLocalizedString("No templates here yet", comment: "")
            subtitleLabel.text = NSLocalizedString("You can create a template from a room in the Room section", comment: "")
            actionButton?.removeFromSuperview()
        case .docspaceEmptyRooms:
            imageView.image = Asset.Images.welcomeDocspace.image
            titleLabel.text = NSLocalizedString("Welcome to DocSpace!", comment: "")
            subtitleLabel.text = NSLocalizedString("Create your first room to get started.", comment: "")
            actionButton.setTitle(NSLocalizedString("Create room", comment: ""), for: .normal)
        case .docspaceEmptyRoomsNoPermissions:
            imageView.image = Asset.Images.emptyDocspace.image
            titleLabel.text = NSLocalizedString("There are no rooms here yet", comment: "")
            subtitleLabel.text = NSLocalizedString("The shared rooms will appear here.", comment: "")
            actionButton?.removeFromSuperview()
        default:
            imageView?.image = Asset.Images.emptyFolder.image
            titleLabel?.text = NSLocalizedString("This folder is empty", comment: "")
            subtitleLabel?.text = NSLocalizedString("Create new documents, spreadsheets or presentations. Create new folders to organize your files.", comment: "")
            actionButton?.removeFromSuperview()
        }

        let menu = menuForType[type]
        actionButton.menu = menu
        actionButton.showsMenuAsPrimaryAction = menu != nil

        actionButton.styleType = type.actionButtonStyleType
    }
}

private extension ASCDocumentsEmptyView.EmptyViewState {
    var actionButtonStyleType: ASCButtonStyleType {
        switch self {
        default:
            .action
        }
    }
}
