//
//  RoomSharingLinkRow.swift
//  Documents
//
//  Created by Lolita Chernysheva on 20.12.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import SwiftUI

struct RoomSharingLinkRowModel {
    var titleString: String
    var imagesNames: [String] = []
    var onTapAction: () -> Void
    var onShareAction: () -> Void
    
    static var empty = RoomSharingLinkRowModel(
        titleString: "",
        imagesNames: [],
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
                    .font(Font.subheadline)
                if !model.imagesNames.isEmpty {
                    HStack {
                        ForEach(model.imagesNames) { imageName in
                            Image(systemName: imageName)
                        }
                    }
                }
                
            }
            
            Spacer()

            HStack {
                Image(systemName: "square.and.arrow.up")
                    .foregroundColor(Asset.Colors.brend.swiftUIColor)
                    .onTapGesture {
                        model.onShareAction()
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
