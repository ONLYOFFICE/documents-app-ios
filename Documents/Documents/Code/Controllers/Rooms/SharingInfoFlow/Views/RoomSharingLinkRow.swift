//
//  RoomSharingLinkRow.swift
//  Documents
//
//  Created by Lolita Chernysheva on 20.12.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import SwiftUI

struct RoomSharingLinkRowModel: Identifiable {
    var id: String

    var titleString: String
    var subtitle: String
    var imagesNames: [String] = []
    var isExpired: Bool
    var isGeneral: Bool
    var isSharingPossible: Bool
    var isEditAccessPossible: Bool
    var accessRight: ASCShareAccess
    var onTapAction: () -> Void
    var onShareAction: () -> Void

    static var empty = RoomSharingLinkRowModel(
        id: "",
        titleString: "",
        subtitle: "",
        imagesNames: [],
        isExpired: false,
        isGeneral: false,
        isSharingPossible: true,
        isEditAccessPossible: false,
        accessRight: .none,
        onTapAction: {},
        onShareAction: {}
    )
}

struct RoomSharingLinkRow: View {
    var model: RoomSharingLinkRowModel

    var body: some View {
        HStack {
            linkImage
            VStack(alignment: .leading, spacing: .linkInfoStackSpacing) {
                linkTitle
                linkInfoView
            }
            Spacer()

            HStack(spacing: .linkActionsStackSpacing) {
                linkActionsView
                ChevronRightView()
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            model.onTapAction()
        }
    }
}

private extension RoomSharingLinkRow {
    var linkImage: some View {
        Image(systemName: "link")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: .linkImageSize, height: .linkImageSize)
            .foregroundColor(.gray)
            .padding(.imagePadding)
            .background(Color(asset: Asset.Colors.tableCellSelected))
            .cornerRadius(.cornerRadius)
    }

    var linkTitle: some View {
        Text(verbatim: model.titleString)
            .font(.subheadline)
    }

    @ViewBuilder
    var linkInfoView: some View {
        HStack {
            if !model.imagesNames.isEmpty && !model.isExpired {
                HStack {
                    ForEach(model.imagesNames) { imageName in
                        Image(systemName: imageName)
                            .resizable()
                            .foregroundColor(Asset.Colors.brend.swiftUIColor)
                            .frame(width: .linkInfoImageSize, height: .linkInfoImageSize)
                    }
                }
            } else if model.isExpired {
                Text("The link has expired")
                    .foregroundColor(.red)
                    .font(.subheadline)
            }
            Text(verbatim: model.subtitle)
                .font(.caption2)
                .foregroundColor(.secondaryLabel)
        }
    }

    @ViewBuilder
    var linkActionsView: some View {
        HStack(spacing: .spacing) {
            if !model.isExpired, model.isSharingPossible {
                Image(systemName: "square.and.arrow.up")
                    .foregroundColor(Asset.Colors.brend.swiftUIColor)
                    .onTapGesture {
                        model.onShareAction()
                    }
                model.accessRight.swiftUIImage?
                    .renderingMode(.template)
                    .foregroundColor(.secondary)
            }
        }
    }
}

private extension CGFloat {
    static let spacing: CGFloat = 20
    static let linkImageSize: CGFloat = 21
    static let imagePadding: CGFloat = 10
    static let cornerRadius: CGFloat = 40
    static let linkInfoImageSize: CGFloat = 13
    static let linkInfoStackSpacing: CGFloat = 3
    static let linkActionsStackSpacing: CGFloat = 6
}
