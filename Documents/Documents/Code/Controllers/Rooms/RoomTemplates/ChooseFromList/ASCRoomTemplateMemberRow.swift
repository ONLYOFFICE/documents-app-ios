//
//  ASCRoomTemplateMemberRow.swift
//  Documents
//
//  Created by Lolita Chernysheva on 09.06.2025.
//  Copyright © 2025 Ascensio System SIA. All rights reserved.
//
import SwiftUI
import Kingfisher

struct ASCRoomTemplateUserMemberRowModel {
    var id: String
    var image: ImageSourceType
    var userName: String
    var accessString: String
    var emailString: String
    var isOwner: Bool
    var isSelected: Bool
    var onTapAction: (() -> Void)?
    
    enum ImageSourceType {
        case url(String)
        case asset(ImageAsset)
    }
}

struct ASCRoomTemplateGroupMemberRowModel {
    var id: String
    var name: String
    var isSelected: Bool
    var onTapAction: (() -> Void)?
}

struct ASCRoomTemplateMemberRow: View {
    var model: ASCRoomTemplateMemberRowModel

    var body: some View {
        HStack(alignment: .center) {
            switch model {
            case .user(let userModel):
                userRow(userModel)

            case .group(let groupModel):
                groupRow(groupModel)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            switch model {
            case .user(let userModel):
                userModel.onTapAction?()
            case .group(let groupModel):
                groupModel.onTapAction?()
            }
        }
    }

    @ViewBuilder
    private func userRow(_ model: ASCRoomTemplateUserMemberRowModel) -> some View {
        Image(systemName: model.isSelected ? "checkmark.circle.fill" : "circle")
            .resizable()
            .frame(width: 24, height: 24)
            .foregroundColor(model.isSelected ? Color.accentColor : Color.secondaryLabel)
        
        imageView(for: model.image)
        
        VStack(alignment: .leading) {
            Text(verbatim: model.userName)
                .lineLimit(1)
                .font(.callout)
            Text(verbatim: [model.accessString, model.emailString].joined(separator: " | "))
                .lineLimit(1)
                .foregroundColor(.secondaryLabel)
                .font(.caption)
        }
    }

    @ViewBuilder
    private func groupRow(_ model: ASCRoomTemplateGroupMemberRowModel) -> some View {
        Image(systemName: model.isSelected ? "checkmark.circle.fill" : "circle")
            .resizable()
            .frame(width: 24, height: 24)
            .foregroundColor(model.isSelected ? Color.accentColor : Color.secondaryLabel)
        
        Asset.Images.avatarDefaultGroup.swiftUIImage
            .resizable()
            .frame(width: Constants.imageWidth, height: Constants.imageHeight)
            .cornerRadius(Constants.imageCornerRadius)

        Text(model.name)
            .font(.subheadline)
    }

    @ViewBuilder
    private func imageView(for imageType: ASCRoomTemplateUserMemberRowModel.ImageSourceType) -> some View {
        switch imageType {
        case let .url(string):
            if let portal = OnlyofficeApiClient.shared.baseURL?.absoluteString.trimmed,
               !string.contains(String.defaultUserPhotoSize),
               let url = URL(string: portal + string)
            {
                KFImage(url)
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
    static let horizontalAlignment: CGFloat = 16
    static let descriptionTopPadding: CGFloat = 20
    static let imageWidth: CGFloat = 40
    static let imageHeight: CGFloat = 40
    static let imageCornerRadius: CGFloat = 20
}
