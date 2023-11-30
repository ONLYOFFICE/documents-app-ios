//
//  RoomSelectionView.swift
//  Documents-opensource
//
//  Created by Pavel Chernyshev on 16.11.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import SwiftUI

struct Room {
    var name: String
    var description: String
    var icon: String
}

struct RoomSelectionView: View {
    @ObservedObject var viewModel = RoomSelectionViewModel()
    @State private var isCreateRoomPresenting = false

    var body: some View {
        List(viewModel.rooms, id: \.name) { room in
            roomView(room)
                .padding(.vertical, 4)
                .onTapGesture {
                    viewModel.selectRoom(room)
                    isCreateRoomPresenting = true
                }
        }
        .navigation(isActive: $isCreateRoomPresenting) {
            CreateRoomView()
        }
    }

    private func roomView(_ room: Room) -> some View {
        HStack {
            Image(systemName: room.icon)
                .foregroundColor(.accentColor)
                .frame(width: 36, height: 36)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)

            VStack(alignment: .leading) {
                Text(room.name)
                    .font(.headline)
                Text(room.description)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
    }
}

struct RoomSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        let view = RoomSelectionView()
        return view
    }
}
