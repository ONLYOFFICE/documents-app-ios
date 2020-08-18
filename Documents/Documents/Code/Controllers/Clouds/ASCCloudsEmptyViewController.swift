//
//  ASCCloudsEmptyViewController.swift
//  Documents
//
//  Created by Alexander Yuzhin on 18/12/2018.
//  Copyright © 2018 Ascensio System SIA. All rights reserved.
//

import UIKit

class ASCCloudsEmptyViewController: ASCBaseViewController {
    static let identifier = String(describing: ASCCloudsEmptyViewController.self)

    // MARK: - Properties

    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet var cloudButtons: [UIButton]!


    var onAddService: ((_ type: ASCFileProviderType) -> Void)?

    // MARK: - Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        subtitleLabel?.text = NSLocalizedString("Select another cloud to connect to Nextcloud, ownCloud and others are supported.", comment: "")
        cloudButtons?.forEach { button in
            if let restorationId = button.restorationIdentifier {
                if !ASCConstants.Clouds.defaultConnectCloudProviders.contains(ASCFileProviderType(rawValue: restorationId) ?? .unknown) {
                    button.removeFromSuperview()
                }
            }
        }

    }

    @IBAction func onConnectService(_ sender: UIButton) {
        if let restorationIdentifier = sender.restorationIdentifier,
            let providerType = ASCFileProviderType(rawValue: restorationIdentifier)
        {
            onAddService?(providerType)
        }
    }
}
