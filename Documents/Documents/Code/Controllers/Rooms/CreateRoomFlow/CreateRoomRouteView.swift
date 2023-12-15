//
//  CreateRoomRouteView.swift
//  Documents
//
//  Created by Pavel Chernyshev on 04.12.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import SwiftUI

struct CreateRoomRouteView: View {
    @Environment(\.presentationMode) var presentationMode

    @State var selectedRoom: Room?
    var onCreate: (ASCFolder) -> Void

    private var isRoomSelected: Binding<Bool> {
        Binding<Bool>(get: { self.selectedRoom != nil },
                      set: { isSelected in
                          if !isSelected {
                              self.selectedRoom = nil
                          }
                      })
    }

    var body: some View {
        NavigationView {
            RoomSelectionView(selectedRoom: $selectedRoom)
                .navigation(item: $selectedRoom) { room in
                    CreateRoomView(
                        viewModel: CreateRoomViewModel(selectedRoom: room) { room in
                            presentationMode.wrappedValue.dismiss()
                            onCreate(room)
                        }
                    )
                }
        }
    }
}

#Preview {
    CreateRoomRouteView { _ in }
}
