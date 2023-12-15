//
//  CreatingRoomViewRow.swift
//  Documents
//
//  Created by Pavel Chernyshev on 02.12.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import SwiftUI

struct CreatingRoomViewRow: View {
    let room: Room

    var subtitleFont: Font {
        if #available(iOS 14.0, *) {
            .caption2
        } else {
            .footnote
        }
    }

    var body: some View {
        HStack(spacing: 14) {
            roomImageView(for: room)
                .frame(width: 36, height: 36)
                .padding(.vertical, 4)

            VStack(alignment: .leading, spacing: 4) {
                Text(room.name)
                    .font(.subheadline) // TODO: Look at design
                    .fontWeight(.semibold)
                Text(room.description)
                    .font(subtitleFont)
                    .foregroundColor(Color.secondaryLabel)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.subheadline)
                .foregroundColor(Color.separator)
                .flipsForRightToLeftLayoutDirection(true)
        }
    }

    private func roomImageView(for room: Room) -> some View {
        Image(uiImage: room.icon)
            .foregroundColor(.accentColor)
            .frame(width: 36, height: 36)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
    }
}

#Preview {
    CreatingRoomViewRow(
        room: CreatingRoomType.publicRoom.toRoom()
    )
}
