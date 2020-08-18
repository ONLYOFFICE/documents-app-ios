//
//  ASCLoaderCell.swift
//  Documents
//
//  Created by Alexander Yuzhin on 21/08/2019.
//  Copyright © 2019 Ascensio System SIA. All rights reserved.
//

import UIKit

class ASCLoaderCell: UITableViewCell {

    // MARK: - Properties

    @IBOutlet weak var indicator: UIActivityIndicatorView!

    // MARK: - Lifecycle Methods
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    func startActivity() {
        indicator.startAnimating()
    }

}
