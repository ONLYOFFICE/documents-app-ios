//
//  ASCFileCell.swift
//  Documents
//
//  Created by Alexander Yuzhin on 21/08/2019.
//  Copyright © 2019 Ascensio System SIA. All rights reserved.
//

import UIKit
import MGSwipeTableCell
import Kingfisher

class ASCFileCell: MGSwipeTableCell {

    // MARK: - Properties

    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var date: UILabel!
    @IBOutlet weak var owner: UILabel!
    @IBOutlet weak var sizeLabel: UILabel!
    @IBOutlet weak var separaterLabel: UILabel!
    @IBOutlet weak var icon: UIImageView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var file: ASCFile? = nil {
        didSet {
            updateData()
        }
    }
    var provider: ASCBaseFileProvider?

    fileprivate lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()

    // MARK: - Lifecycle Methods
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code

        contentView.clipsToBounds = false
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        selectedBackgroundView = UIView()
        selectedBackgroundView?.backgroundColor = UIColor(named: "table-cell-selected")
    }

    func updateData() {
        guard let fileInfo = file else {
            title?.text = NSLocalizedString("Unknown", comment: "Invalid entity name")
            owner?.text = NSLocalizedString("none", comment: "Invalid entity owner")
            date?.text  = NSLocalizedString("none", comment: "Invalid entity date")
            return
        }

        title?.text = fileInfo.title
        owner?.text = fileInfo.updatedBy?.displayName ?? NSLocalizedString("Unknown", comment: "Invalid entity name")
        date?.text = (fileInfo.updated != nil)
            ? dateFormatter.string(from: fileInfo.updated!)
            : NSLocalizedString("Unknown", comment: "Invalid entity name")
        
        if fileInfo.pureContentLength < 1 {
            if fileInfo.device {
                separaterLabel?.text = "•"
                sizeLabel?.text = fileInfo.displayContentLength
            } else {
                separaterLabel?.text = ""
                sizeLabel?.text = ""
            }
        } else {
            separaterLabel?.text = "•"
            sizeLabel?.text = fileInfo.displayContentLength
        }
        
        /// Status info
        
        if #available(iOS 13.0, *) {
            if fileInfo.isEditing {
                let editImage = UIImage(
                    systemName: "pencil",
                    withConfiguration: UIImage.SymbolConfiguration(font: UIFont.systemFont(ofSize: 13, weight: .black))
                )?.withTintColor(ASCConstants.Colors.brend, renderingMode: .alwaysOriginal) ?? UIImage()
                
                title?.addTrailing(image: editImage)
            }
            
            if fileInfo.isFavorite {
                let favoriteImage = UIImage(
                    systemName: "star.fill",
                    withConfiguration: UIImage.SymbolConfiguration(font: UIFont.systemFont(ofSize: 13, weight: .medium))
                )?.withTintColor(ASCConstants.Colors.brend, renderingMode: .alwaysOriginal) ?? UIImage()
                
                title?.addTrailing(image: favoriteImage)
            }
        }
        
        /// Thumb view
        let fileExt = fileInfo.title.fileExtension().lowercased()

        icon?.contentMode = .center
        icon?.alpha = 1
        activityIndicator?.isHidden = true
        
        if ASCConstants.FileExtensions.images.contains(fileExt) {
            if UserDefaults.standard.bool(forKey: ASCConstants.SettingsKeys.previewFiles) {
                activityIndicator?.isHidden = false
                icon?.alpha = 0
                
                guard let provider = provider else {
                    icon?.image = UIImage(named: "list-format-image")
                    return
                }

                icon?.kf.setProviderImage(
                    with: provider.absoluteUrl(from: fileInfo.viewUrl),
                    for: provider,
                    placeholder: UIImage(named: "list-format-image"),
                    completionHandler: { [weak self] result in
                        switch result {
                        case .success(_):
                            self?.icon?.contentMode = .scaleAspectFit
                        default:
                            self?.icon?.contentMode = .center
                        }
                        
                        self?.activityIndicator?.isHidden = true
                        UIView.animate(withDuration: 0.2) { [weak self] in
                            self?.icon?.alpha = 1
                        }
                    }
                )
            } else {
                icon?.image = UIImage(named: "list-format-image")
            }
        } else if ASCConstants.FileExtensions.documents.contains(fileExt) {
            icon?.image = UIImage(named: "list-format-document")
        } else if ASCConstants.FileExtensions.spreadsheets.contains(fileExt) {
            icon?.image = UIImage(named: "list-format-spreadsheet")
        } else if ASCConstants.FileExtensions.presentations.contains(fileExt) {
            icon?.image = UIImage(named: "list-format-presentation")
        } else if ASCConstants.FileExtensions.videos.contains(fileExt) {
            icon?.image = UIImage(named: "list-format-video")
        } else if fileExt == "pdf" {
            icon?.image = UIImage(named: "list-format-pdf")
        } else {
            icon?.image = UIImage(named: "list-format-unknown")
        }
    }
}
