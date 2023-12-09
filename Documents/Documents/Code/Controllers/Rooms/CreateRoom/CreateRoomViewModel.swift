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
    lazy var menuItems: [MenuViewItem] = makeImageMenuItems()

    private var networkService = OnlyofficeApiClient.shared

    init(selectedRoom: Room) {
        self.selectedRoom = selectedRoom
    }

    func createRoom() {
        errorMessage = ""
        let params: [String: Any] = [
            "roomType": selectedRoom.type.id,
            "title": roomName,
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

    func makeImageMenuItems() -> [MenuViewItem] {
        [
            .init(text: NSLocalizedString("Photo Library", comment: ""), systemImageName: "photo", action: imageFromLibraryAction),
            .init(text: NSLocalizedString("Take Photo", comment: ""), systemImageName: "camera", action: imageFromCameraAction),
            .init(text: NSLocalizedString("Choose Files", comment: ""), systemImageName: "folder", action: imageFromFilesAction),
        ]
    }

    func imageFromLibraryAction() {
        print(#function)
    }

    func imageFromCameraAction() {
        print(#function)
    }

    func imageFromFilesAction() {
        print(#function)
    }
}
