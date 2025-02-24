//
//  SharedSettingsLinkRow.swift
//  Documents
//
//  Created by Lolita Chernysheva on 01.06.2024.
//  Copyright © 2024 Ascensio System SIA. All rights reserved.
//

import SwiftUI

enum LinkAccess: String {
    case anyoneWithLink = "Anyone with the link"
    case docspaceUserOnly = "Docspace user only"

    var isInternal: Bool {
        self == .docspaceUserOnly
    }
}

struct SharedSettingsLinkRowModel: Identifiable {
    var id: String
    var linkAccess: LinkAccess
    var expiredTo: String
    var rights: String
    var rightsImage: Image
    var isExpired: Bool
    var isTimeLimited: Bool
    var onTapAction: () -> Void
    var onShareAction: () -> Void

    static var empty: SharedSettingsLinkRowModel = SharedSettingsLinkRowModel(
        id: "",
        linkAccess: .anyoneWithLink,
        expiredTo: "", rights: "",
        rightsImage: Image(""),
        isExpired: false,
        isTimeLimited: false,
        onTapAction: {},
        onShareAction: {}
    )
}

struct SharedSettingsLinkRow: View {
    var model: SharedSettingsLinkRowModel

    var body: some View {
        HStack {
            linkImageIcon
            textVStack
            Spacer()
            rightActionIcons
        }
        .contentShape(Rectangle())
        .onTapGesture {
            model.onTapAction()
        }
    }

    @ViewBuilder
    private var rightActionIcons: some View {
        HStack(spacing: .hStackSpacing) {
            Image(systemName: "square.and.arrow.up")
                .foregroundColor(.timeLimitedIconColor)
                .onTapGesture {
                    model.onShareAction()
                }
            model.rightsImage
                .renderingMode(.template)
                .foregroundColor(.rightsImageColor)
            ChevronRightView()
        }
    }

    @ViewBuilder
    private var textVStack: some View {
        VStack(alignment: .leading, spacing: .vStackSpacing) {
            linkAccessTypeText
            timeLimitedView
        }
        .padding(.leading, .vStackLeadingPadding)
    }

    @ViewBuilder
    private var linkAccessTypeText: some View {
        Text(model.linkAccess.rawValue)
            .font(.subheadlineFont)
    }

    @ViewBuilder
    private var timeLimitedView: some View {
        if model.isExpired {
            Text(NSLocalizedString("The link has expired", comment: ""))
                .foregroundColor(.expirationTextColor)
                .font(.footnoteFont)
        } else if model.isTimeLimited {
            Image(systemName: "clock.fill")
                .renderingMode(.template)
                .foregroundColor(.timeLimitedIconColor)
        }
    }

    @ViewBuilder
    private var linkImageIcon: some View {
        Image(systemName: "link")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: .linkImageWidthHeight, height: .linkImageWidthHeight)
            .foregroundColor(.linkIconColor)
            .padding(.linkImagePadding)
            .background(Color(asset: Asset.Colors.tableCellSelected))
            .cornerRadius(.cornerRadius)
    }
}

private extension CGFloat {
    // Icon sizes and appearance
    static let cornerRadius: CGFloat = 40
    static let linkImageWidthHeight: CGFloat = 21
    static let linkImagePadding: CGFloat = 10

    // Spacing
    static let vStackSpacing: CGFloat = 2
    static let hStackSpacing: CGFloat = 12
    static let vStackLeadingPadding: CGFloat = 16
}

private extension Font {
    static let subheadlineFont = Font.subheadline
    static let footnoteFont = Font.footnote
}

private extension Color {
    static let linkIconColor = Color.gray
    static let expirationTextColor = Color.red
    static let timeLimitedIconColor = Asset.Colors.brend.swiftUIColor
    static let rightsImageColor = Color.secondary
}
