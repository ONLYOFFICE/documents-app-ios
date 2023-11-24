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
}

struct RoomSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        let view = RoomSelectionView()
        view.viewModel.rooms = [
            Room(name: "Collaboration room",
                 description: "Collaborate on one or multiple documents with your team",
                 icon: "bolt.fill"),
            Room(name: "Public room",
                 description: "Invite users via shared links to view documents without registration. You can also embed this room into any web interface.",
                 icon: "person.crop.circle.fill"),
            Room(name: "Custom room",
                 description: "Apply your own settings to use this room for any custom purpose",
                 icon: "star.fill"),
        ]
        return view
    }
}
