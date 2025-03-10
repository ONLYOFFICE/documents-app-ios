//
//  RoomTypeViewRow.swift
//  Documents
//
//  Created by Pavel Chernyshev on 02.12.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import SwiftUI

struct RoomTypeViewRow: View {
    let roomTypeModel: RoomTypeModel

    var subtitleFont: Font {
        if #available(iOS 14.0, *) {
            .caption2
        } else {
            .footnote
        }
    }

    var body: some View {
        HStack(spacing: 14) {
            roomImageView(for: roomTypeModel)
                .frame(width: 36, height: 36)
                .padding(.vertical, 4)

            VStack(alignment: .leading, spacing: 4) {
                Text(verbatim: roomTypeModel.name)
                    .font(.subheadline) // TODO: Look at design
                    .fontWeight(.semibold)
                Text(verbatim: roomTypeModel.description)
                    .font(subtitleFont)
                    .foregroundColor(Color.secondaryLabel)
            }

            Spacer()
            if roomTypeModel.showDisclosureIndicator {
                ChevronRightView()
            }
        }
    }

    private func roomImageView(for roomTypeModel: RoomTypeModel) -> some View {
        Image(uiImage: roomTypeModel.icon)
            .foregroundColor(.accentColor)
            .frame(width: 36, height: 36)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
    }
}

#Preview {
    RoomTypeViewRow(
        roomTypeModel: CreatingRoomType.publicRoom.toRoomTypeModel(showDisclosureIndicator: true)
    )
}
