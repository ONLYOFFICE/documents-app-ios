//
//  CreateRoomViewModel.swift
//  Documents-opensource
//
//  Created by Pavel Chernyshev on 23.11.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import Foundation

class CreateRoomViewModel: ObservableObject {
    @Published var roomName: String = ""
    @Published var tags: String = ""
    @Published var isCreatingRoom = false
    @Published var errorMessage = ""
    @Published var dismissNavStack = false
    @Published var selectedRoom: Room!

    private var networkService = OnlyofficeApiClient.shared

    init(selectedRoom: Room) {
        self.selectedRoom = selectedRoom
    }

    func createRoom() {
        errorMessage = ""
        let params: [String: Any] = [
            "roomType": selectedRoom.type.id,
            "title": roomName
        ]
        isCreatingRoom = true
        networkService.request(OnlyofficeAPI.Endpoints.Rooms.create(), params) { [weak self] response, error in
            guard let self = self else { return }
            self.isCreatingRoom = false
            guard error == nil else {
                self.errorMessage = error!.localizedDescription
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    self.errorMessage = ""
                }
                return
            }
            self.dismissNavStack = true
        }
    }
}
