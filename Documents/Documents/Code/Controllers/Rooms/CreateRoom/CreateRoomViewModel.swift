//
//  CreateRoomViewModel.swift
//  Documents-opensource
//
//  Created by Pavel Chernyshev on 23.11.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import Foundation
import Combine

class CreateRoomViewModel: ObservableObject {
    @Published var roomName: String = ""
    @Published var isCreatingRoom = false
    @Published var errorMessage = ""
    @Published var dismissNavStack = false
    @Published var selectedRoom: Room!
    @Published var tags: Set<String> = []
    
    lazy var menuItems: [MenuViewItem] = makeImageMenuItems()

    private var networkService = OnlyofficeApiClient.shared
    
    private var tagsDispatchGroup = DispatchGroup()

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
           
            guard let room = response?.result, error == nil else {
                self.errorMessage = error!.localizedDescription
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    self.errorMessage = ""
                    self.isCreatingRoom = false
                }
                return
            }
            
            if !tags.isEmpty {
                createTags() { [weak self] in
                    guard let self else { return }
                    addTagsToRoom(room: room) { [weak self] in
                        guard let self else { return }
                        self.isCreatingRoom = false
                        self.dismissNavStack = true
                    }
                }
            } else {
                self.isCreatingRoom = false
                self.dismissNavStack = true
            }
        }
    }
    
    private func createTags(completion: @escaping () -> Void) {
        for tag in tags {
            tagsDispatchGroup.enter()
            networkService.request(OnlyofficeAPI.Endpoints.Tags.create(), ["name": tag]) { [tagsDispatchGroup] _, _ in
                tagsDispatchGroup.leave()
            }
        }
        tagsDispatchGroup.notify(queue: .global()) {
            completion()
        }
    }
    
    private func addTagsToRoom(room: ASCFolder, completion: @escaping () -> Void) {
        let tags: [String] = self.tags.map { $0 }
        networkService.request(OnlyofficeAPI.Endpoints.Tags.addToRoom(folder: room), ["names": tags]) { _, _ in
            completion()
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
