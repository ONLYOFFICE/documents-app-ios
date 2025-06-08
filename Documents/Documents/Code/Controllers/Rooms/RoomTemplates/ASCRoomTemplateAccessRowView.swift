//
//  ASCRoomTemplateAccessRowView.swift
//  Documents
//
//  Created by Lolita Chernysheva on 08.06.2025.
//  Copyright © 2025 Ascensio System SIA. All rights reserved.
//

import SwiftUI
import Kingfisher

struct ASCRoomTemplateAccessRowViewModel {
    var users: [ASCTemplateAccessModel]
    var isPublicTemplate: Bool
    
    var displayTitle: String {
        let userCount = users.count
        guard userCount > 0 else { return "" }

        let meName = "\(users.first?.sharedTo?.displayName ?? "") (Me)"
        
        switch userCount {
        case 1:
            return meName
        case 2:
            return "\(meName) and 1 User"
        default:
            return "\(meName) and \(userCount - 1) Users"
        }
    }
    
    var displayedAvatars: [ASCTemplateAccessModel] {
        Array(users.prefix(3))
    }
    
    enum ImageSourceType {
        case url(String)
        case asset(ImageAsset)
    }
}

struct ASCRoomTemplateAccessRowView: View {
    var model: ASCRoomTemplateAccessRowViewModel
    
    var body: some View {
        HStack(spacing: 12) {
            if !model.isPublicTemplate {
                HStack(spacing: -10) {
                    ForEach(model.displayedAvatars, id: \.sharedTo?.userId) { user in
                        imageView(for: .url(user.sharedTo?.avatar ?? ""))
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
