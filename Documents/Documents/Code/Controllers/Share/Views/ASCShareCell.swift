//
//  ASCShareCell.swift
//  Documents
//
//  Created by Alexander Yuzhin on 6/8/17.
//  Copyright © 2017 Ascensio System SIA. All rights reserved.
//

import UIKit
import Kingfisher

class ASCShareCell: UITableViewCell {

    // MARK: - Properties
    
    @IBOutlet weak var avatar: UIImageView!
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var access: UILabel!
    
    var share: OnlyofficeShare? = nil {
        didSet {
            updateData()
        }
    }
    
    // MARK: - Lifecycle Methods
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        if isEditing {
            selectedBackgroundView = UIView()
            selectedBackgroundView?.backgroundColor = .clear
        }
    }
    
    func updateData() {
        guard let shareInfo = share else {
            avatar?.image = UIImage()
            title?.text = NSLocalizedString("none", comment: "No information")
            access?.text = NSLocalizedString("none", comment: "No information")
            return
        }
        
        if let user = shareInfo.user {
            if let userAvatar = user.avatarRetina ?? user.avatar,
               let userAvatarUrl = OnlyofficeApiClient.absoluteUrl(from: URL(string: userAvatar))
            {
                avatar?.kf.indicatorType = .activity
                avatar?.kf.apiSetImage(with: userAvatarUrl,
                                       placeholder: Asset.Images.avatarDefault.image)
            }
            title?.text = user.displayName ?? NSLocalizedString("Unknown", comment: "")
        } else if let group = shareInfo.group {
            avatar?.image = Asset.Images.avatarDefaultGroup.image
            title?.text = group.name ?? NSLocalizedString("Unknown", comment: "")
        }
        
        if shareInfo.owner {
            access?.text = NSLocalizedString("Owner", comment: "")
        } else {
            switch shareInfo.access {
            case .none:
                access?.text = NSLocalizedString("None", comment: "Share status")
                break
            case .full:
                access?.text = NSLocalizedString("Full Access", comment: "Share status")
                break
            case .read:
                access?.text = NSLocalizedString("Read Only", comment: "Share status")
                break
            case .deny:
                access?.text = NSLocalizedString("Deny Access", comment: "Share status")
                break
            case .varies:
                access?.text = NSLocalizedString("Varies", comment: "Share status")
                break
            case .review:
                access?.text = NSLocalizedString("Review", comment: "Share status")
                break
            default:
                access?.text = ""
            }
        }
        
        accessoryType = shareInfo.locked ? .none : .disclosureIndicator
    }
}
