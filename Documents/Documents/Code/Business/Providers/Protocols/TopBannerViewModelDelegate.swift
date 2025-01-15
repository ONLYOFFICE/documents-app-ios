//
//  TopBannerViewModelDelegate.swift
//  Documents-opensource
//
//  Created by Lolita Chernysheva on 15.01.2025.
//  Copyright © 2025 Ascensio System SIA. All rights reserved.
//

protocol TopBannerViewModelDelegate {
    func topBannerViewModel(for folder: ASCFolder?) -> TopBannerViewModel?
}
