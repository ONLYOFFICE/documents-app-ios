//
//  RoomSelectionView.swift
//  Documents-opensource
//
//  Created by Pavel Chernyshev on 16.11.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import SwiftUI

struct Room {
    var type: CreatingRoomType
    var name: String
    var description: String
    var icon: UIImage
}

struct RoomSelectionView: View {
    @ObservedObject var viewModel = RoomSelectionViewModel()
    @State private var isCreateRoomPresenting = false

    var body: some View {
        List(viewModel.rooms, id: \.name) { room in
            CreatingRoomViewRow(room: room)
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
        return view
    }
}
