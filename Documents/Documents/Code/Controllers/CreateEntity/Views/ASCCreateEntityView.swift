//
//  ASCCreateEntityView.swift
//  Documents
//
//  Created by Alexander Yuzhin on 20/06/2019.
//  Copyright © 2019 Ascensio System SIA. All rights reserved.
//

import UIKit
import SwiftMessages

class ASCCreateEntityView: MessageView {

    // MARK: - Properties

    @IBOutlet weak var documentButton: UIButton!
    @IBOutlet weak var spreadsheetButton: UIButton!
    @IBOutlet weak var presentationButton: UIButton!
    @IBOutlet weak var otherStackView: UIStackView!
    @IBOutlet weak var cloudButtonContainerView: UIView!

    var onCreate: ((String) -> Void)?
    var allowConnectClouds: Bool = true {
        didSet {
            hideCloudItemIfNeeded()
        }
    }

    // MARK: - Lifecycle Methods

    override func willMove(toWindow newWindow: UIWindow?) {
        super.willMove(toWindow: newWindow)

        if newWindow == nil {
            // UIView disappear
        } else {
            // UIView appear

//            [documentButton, spreadsheetButton, presentationButton].forEach { button in
//                button?.layer.cornerRadius = 10
//            }
            
            if UIDevice.phone || ASCViewControllerManager.shared.currentSizeClass == .compact {
                if #available(iOS 13.0, *) {
                    backgroundView.backgroundColor = .tertiarySystemBackground
                } else {
                    backgroundView.backgroundColor = .white
                }
            }

            documentButton.set(
                image: Asset.Images.createDocument.image,
                title: NSLocalizedString("Document", comment: ""),
                titlePosition: .bottom,
                additionalSpacing: 20,
                state: .normal)

            spreadsheetButton.set(
                image: Asset.Images.createSpreadsheet.image,
                title: NSLocalizedString("Spreadsheet", comment: ""),
                titlePosition: .bottom,
                additionalSpacing: 20,
                state: .normal)

            presentationButton.set(
                image: Asset.Images.createPresentation.image,
                title: NSLocalizedString("Presentation", comment: ""),
                titlePosition: .bottom,
                additionalSpacing: 20,
                state: .normal)
        }
    }

    private func hideCloudItemIfNeeded() {
        if !allowConnectClouds {
            // Remove it from the stack view
            otherStackView.removeArrangedSubview(cloudButtonContainerView)

            // now remove it from the view hierarchy – this is important!
            cloudButtonContainerView.removeFromSuperview()

            frame = CGRect(
                x: frame.minX,
                y: frame.minY,
                width: frame.width,
                height: frame.height - cloudButtonContainerView.frame.height
            )
        }
    }

    // MARK: - Actions

    @IBAction func onCreateButton(_ sender: UIButton) {
        if let restorationIdentifier = sender.restorationIdentifier {
            onCreate?(restorationIdentifier)
        }
    }

}
