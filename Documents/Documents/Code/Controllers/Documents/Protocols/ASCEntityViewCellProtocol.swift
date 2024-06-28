//
//  ASCEntityViewCellProtocol.swift
//  Documents
//
//  Created by Alexander Yuzhin on 25.06.2024.
//  Copyright © 2024 Ascensio System SIA. All rights reserved.
//

import UIKit

protocol ASCEntityViewCellProtocol: UICollectionViewCell {
    var entity: ASCEntity? { get set }
    var provider: ASCFileProviderProtocol? { get set }
}
