//
//  ASCRoomTemplateMemberRow.swift
//  Documents
//
//  Created by Lolita Chernysheva on 09.06.2025.
//  Copyright © 2025 Ascensio System SIA. All rights reserved.
//
import Kingfisher
import SwiftUI

struct ASCRoomTemplateUserMemberRowModel: Equatable {
    var id: String
    var image: ImageSourceType
    var userName: String
    var accessString: String
    var emailString: String
    var isOwner: Bool
    var isSelected: Bool
    var displayCircleMark: Bool = true
    var onTapAction: (() -> Void)?

    enum ImageSourceType: Equatable {
        case url(String)
        case asset(ImageAsset)

        static func == (lhs: ImageSourceType, rhs: ImageSourceType) -> Bool {
            switch (lhs, rhs) {
            case let (.url(l), .url(r)):
                return l == r
            case let (.asset(l), .asset(r)):
                return l.name == r.name
            default:
                return false
            }
        }
    }

    static func == (lhs: ASCRoomTemplateUserMemberRowModel, rhs: ASCRoomTemplateUserMemberRowModel) -> Bool {
        lhs.id == rhs.id &&
            lhs.image == rhs.image &&
            lhs.userName == rhs.userName &&
            lhs.accessString == rhs.accessString &&
            lhs.emailString == rhs.emailString &&
            lhs.isOwner == rhs.isOwner &&
            lhs.isSelected == rhs.isSelected &&
            lhs.displayCircleMark == rhs.displayCircleMark
    }
}

struct ASCRoomTemplateGroupMemberRowModel {
    var id: String
    var name: String
    var isSelected: Bool
    var displayCircleMark: Bool = true
    var onTapAction: (() -> Void)?
}

struct ASCRoomTemplateMemberRow: View {
    var model: ASCRoomTemplateMemberRowModel

    var body: some View {
        HStack(alignment: .center) {
            switch model {
            case let .user(userModel):
                userRow(userModel)

            case let .group(groupModel):
                groupRow(groupModel)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            switch model {
            case let .user(userModel):
                userModel.onTapAction?()
            case let .group(groupModel):
                groupModel.onTapAction?()
            }
        }
    }

    @ViewBuilder
    private func userRow(_ model: ASCRoomTemplateUserMemberRowModel) -> some View {
        if model.displayCircleMark {
            Image(systemName: model.isSelected ? "checkmark.circle.fill" : "circle")
                .resizable()
                .frame(width: 24, height: 24)
                .foregroundColor(model.isSelected ? Color.accentColor : Color.secondaryLabel)
        }

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
        if model.displayCircleMark {
            Image(systemName: model.isSelected ? "checkmark.circle.fill" : "circle")
                .resizable()
                .frame(width: 24, height: 24)
                .foregroundColor(model.isSelected ? Color.accentColor : Color.secondaryLabel)
        }

        Asset.Images.avatarDefaultGroup.swiftUIImage
            .resizable()
            .frame(width: Constants.imageWidth, height: Constants.imageHeight)
            .cornerRadius(Constants.imageCornerRadius)

        Text(verbatim: model.name)
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
