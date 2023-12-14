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

extension Room: Equatable {}

struct RoomSelectionView: View {
    @Environment(\.presentationMode) var presentationMode

    @ObservedObject var viewModel = RoomSelectionViewModel()

    @Binding var selectedRoom: Room?
    @State var dismissOnSelection = false
    @State private var isPresenting = true

    var body: some View {
        List(viewModel.rooms, id: \.name) { room in
            CreatingRoomViewRow(room: room)
                .onTapGesture {
                    selectedRoom = room
                    if dismissOnSelection {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
        }
        .navigationBarTitle(Text(NSLocalizedString("Choose room type", comment: "")), displayMode: .inline)
        .navigationBarItems(
            trailing: Button(NSLocalizedString("Cancel", comment: "")) {
                presentationMode.wrappedValue.dismiss()
            }
        )
    }
}

struct RoomSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        let view = RoomSelectionView(selectedRoom: .constant(nil))
        return view
    }
}
