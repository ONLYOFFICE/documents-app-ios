//
//  CreatingRoomViewRow.swift
//  Documents-opensource
//
//  Created by Pavel Chernyshev on 02.12.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import SwiftUI

struct CreatingRoomViewRow: View {
    let room: Room

    var body: some View {
        HStack(spacing: 14) {
            roomImageView(for: room)
                .frame(width: 36, height: 36)
                .padding(.vertical, 4)

            VStack(alignment: .leading, spacing: 2) {
                Text(room.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(room.description)
                    .font(.footnote)
                    .foregroundColor(.gray)
            }
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

struct CreatingRoomViewRow_Previews: PreviewProvider {
    static var previews: some View {
        CreatingRoomViewRow(
            room: CreatingRoomType.publicRoom.toRoom()
        )
    }
}
