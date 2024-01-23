//
//  KFImageView.swift
//  Documents
//
//  Created by Pavel Chernyshev on 22.01.2024.
//  Copyright © 2024 Ascensio System SIA. All rights reserved.
//

import Kingfisher
import SwiftUI

struct KFImageView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> UIImageView {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        return imageView
    }

    func updateUIView(_ uiView: UIImageView, context: Context) {
        uiView.contentMode = .scaleAspectFill
        uiView.kf.indicatorType = .activity
        uiView.kf.apiSetImage(with: url)
    }
}
