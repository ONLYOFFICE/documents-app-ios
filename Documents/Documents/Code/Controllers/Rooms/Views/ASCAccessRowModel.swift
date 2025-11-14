//
//  ASCAccessRowModel.swift
//  Documents
//
//  Created by Lolita Chernysheva on 06.06.2025.
//  Copyright © 2025 Ascensio System SIA. All rights reserved.
//

import Kingfisher
import SwiftUI

struct ASCAccessRowModel: Identifiable {
    var id: String
    var name: String
    var image: ImageSourceType
    var onTapAction: (() -> Void)?

    enum ImageSourceType {
        case url(String)
        case asset(ImageAsset)
    }
}

struct ASCAccessRow: View {
    var model: ASCAccessRowModel
    var body: some View {
        HStack(alignment: .center) {
            imageView(for: model.image)
            Text(verbatim: model.name)
                .lineLimit(1)
                .font(.callout)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            model.onTapAction?()
        }
    }

    @ViewBuilder
    private func imageView(for imageType: ASCAccessRowModel.ImageSourceType) -> some View {
        switch imageType {
        case let .url(string):
            if let portal = OnlyofficeApiClient.shared.baseURL?.absoluteString.trimmed,
               !string.contains(String.defaultUserPhotoSize),
               let url = URL(string: portal)?.appendingSafePath(string)
            {
                KFOnlyOfficeProviderImageView(url: url)
                    .resizable()
                    .frame(width: Constants.imageWidth, height: Constants.imageHeight)
                    .cornerRadius(Constants.imageCornerRadius)
                    .clipped()
            } else {
                Image(asset: Asset.Images.avatarDefault)
                    .resizable()
                    .frame(width: Constants.imageWidth, height: Constants.imageHeight)
            }
        case let .asset(asset):
            Image(asset: asset)
                .resizable()
                .frame(width: Constants.imageWidth, height: Constants.imageHeight)
        }
    }
}

private enum Constants {
    static let imageWidth: CGFloat = 40
    static let imageHeight: CGFloat = 40
    static let imageCornerRadius: CGFloat = 20
}
