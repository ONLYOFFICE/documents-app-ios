//
//  ASCRoomTemplateAccessRowView.swift
//  Documents
//
//  Created by Lolita Chernysheva on 08.06.2025.
//  Copyright © 2025 Ascensio System SIA. All rights reserved.
//

import Kingfisher
import SwiftUI

struct ASCRoomTemplateAccessRowViewModel {
    var members: [ASCTemplateAccessModel]
    var isPublicTemplate: Bool

    var displayTitle: String {
        let groups = members.filter { $0.isGroup }
        let users = members.filter { $0.isUser }

        let groupCount = groups.count
        let userCount = users.count
        
        let stringSingleUser = NSLocalizedString("Me", comment: "")
        let stringSeveralUsers = String(format: NSLocalizedString("Me and %ld Users", comment: ""), userCount - 1)
        var components: [String] = []

        if userCount == 1 {
            components.append(stringSingleUser)
        } else if userCount > 1 {
            components.append(stringSeveralUsers)
        }

        if groupCount > 0 {
            components.append(String(format: NSLocalizedString("%ld Groups", comment: ""), groupCount))
        }

        return components.joined(separator: ", ")
    }

    var displayedAvatars: [ASCTemplateAccessModel] {
        Array(members.prefix(3))
    }

    enum ImageSourceType {
        case url(String)
        case asset(ImageAsset)
    }
}

private extension ASCTemplateAccessModel {
    var imageSourceType: ASCRoomTemplateAccessRowViewModel.ImageSourceType {
        guard let urlString = sharedTo?.avatar else {
            return .asset(
                isGroup
                    ? Asset.Images.avatarDefaultGroup
                    : Asset.Images.avatarDefault
            )
        }
        return .url(urlString)
    }
}

struct ASCRoomTemplateAccessRowView: View {
    var model: ASCRoomTemplateAccessRowViewModel

    var body: some View {
        HStack(spacing: 12) {
            if !model.isPublicTemplate {
                HStack(spacing: -10) {
                    ForEach(model.displayedAvatars, id: \.sharedTo?.id) { member in
                        imageView(for: member.imageSourceType)
                    }
                }
            }
            VStack(alignment: .leading, spacing: 4) {
                if model.isPublicTemplate {
                    Text("Template available to everyone")
                        .font(.subheadline)
                    Text("All DocSpace and Room admins will be able to create rooms using this template.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text(model.displayTitle)
                        .font(.subheadline)
                }
            }

            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private func imageView(for imageType: ASCRoomTemplateAccessRowViewModel.ImageSourceType) -> some View {
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
    static let imageWidth: CGFloat = 40
    static let imageHeight: CGFloat = 40
    static let imageCornerRadius: CGFloat = 20
}
