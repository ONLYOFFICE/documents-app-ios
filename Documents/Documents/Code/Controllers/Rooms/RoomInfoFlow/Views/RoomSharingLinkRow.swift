//
//  RoomSharingLinkRow.swift
//  Documents
//
//  Created by Lolita Chernysheva on 20.12.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import SwiftUI

struct RoomSharingLinkRowModel: Identifiable {
    var id = UUID()
    
    var titleString: String
    var imagesNames: [String] = []
    var isExpired: Bool
    var onTapAction: () -> Void
    var onShareAction: () -> Void
    
    static var empty = RoomSharingLinkRowModel(
        titleString: "",
        imagesNames: [],
        isExpired: false,
        onTapAction: {},
        onShareAction: {}
    )
}

struct RoomSharingLinkRow: View {
    var model: RoomSharingLinkRowModel
    
    var body: some View {
        HStack {
            Image(systemName: "link")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 21, height: 21)
                .foregroundColor(.gray)
                .padding(10)
                .background(Color(asset: Asset.Colors.tableCellSelected))
                .cornerRadius(40)
            VStack(alignment: .leading) {
                Text(model.titleString)
                if !model.imagesNames.isEmpty && !model.isExpired {
                    HStack {
                        ForEach(model.imagesNames) { imageName in
                            Image(systemName: imageName)
                                .foregroundColor(Asset.Colors.brend.swiftUIColor)
                        }
                    }
                } else if model.isExpired {
                    Text(NSLocalizedString("The link has expired", comment: ""))
                        .foregroundColor(.red)
                        .font(.subheadline)
                }
            }
            
            Spacer()

            HStack {
                if !model.isExpired {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(Asset.Colors.brend.swiftUIColor)
                        .onTapGesture {
                            model.onShareAction()
                        }
                }
                Image(systemName: "chevron.right")
                    .font(.subheadline)
                    .foregroundColor(Color.separator)
                    .flipsForRightToLeftLayoutDirection(true)
            }
        }
        .onTapGesture {
            model.onTapAction()
        }
    }
}
