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
        HStack {
            roomImageView(for: room)
                .padding(.vertical, 4)

            VStack(alignment: .leading) {
                Text(room.name)
                    .font(.headline)
                Text(room.description)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
    }

    private func roomImageView(for room: Room) -> some View {
        Image(systemName: room.icon)
            .foregroundColor(.accentColor)
            .frame(width: 36, height: 36)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
    }
}
