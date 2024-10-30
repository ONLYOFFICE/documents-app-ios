//
//  ASCUserWithEmailRowView.swift
//  Documents
//
//  Created by Lolita Chernysheva on 09.09.2024.
//  Copyright © 2024 Ascensio System SIA. All rights reserved.
//

import SwiftUI

struct ASCUserWithEmailRowViewModel {
    var image: ImageSourceType
    var userName: String
    var email: String
    var onEmailAction: () -> Void

    enum ImageSourceType {
        case url(String)
        case asset(ImageAsset)
        case uiImage(UIImage)
    }
}

struct ASCUserWithEmailRowView: View {
    var model: ASCUserWithEmailRowViewModel

    var body: some View {
        HStack(alignment: .center) {
            imageView(for: model.image)

            VStack(alignment: .leading) {
                Text(model.userName)
                    .lineLimit(1)
                    .font(.callout)
                Text(model.email)
                    .lineLimit(1)
                    .foregroundColor(.secondaryLabel)
                    .font(.caption)
            }

            Spacer()

            Asset.Images.barEnvelope.swiftUIImage
                .onTapGesture {
                    model.onEmailAction()
                }
        }
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private func imageView(for imageType: ASCUserWithEmailRowViewModel.ImageSourceType) -> some View {
        switch imageType {
        case let .url(string):
            if let portal = OnlyofficeApiClient.shared.baseURL?.absoluteString.trimmed,
               !string.contains(String.defaultUserPhotoSize),
               let url = URL(string: portal + string)
            {
                KFImageView(url: url)
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
        case let .uiImage(image):
            Image(uiImage: image)
                .resizable()
                .frame(width: Constants.imageWidth, height: Constants.imageHeight)
                .cornerRadius(Constants.imageCornerRadius)
                .clipped()
        }
    }
}

private enum Constants {
    static let imageWidth: CGFloat = 40
    static let imageHeight: CGFloat = 40
    static let imageCornerRadius: CGFloat = 20
}
