//
//  RoomUsersAccessNetworkService.swift
//  Documents
//
//  Created by Pavel Chernyshev on 28/12/23.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import Foundation

protocol RoomUsersAccessNetworkService {
    func changeUserAccess(room: ASCFolder, userId: String, newAccess: ASCShareAccess, completion: @escaping (Error?) -> Void)
}

final class RoomUsersAccessNetworkServiceImp: RoomUsersAccessNetworkService {
    private var networkService = OnlyofficeApiClient.shared

    func changeUserAccess(room: ASCFolder, userId: String, newAccess: ASCShareAccess, completion: @escaping (Error?) -> Void) {
        let inviteRequestModel = OnlyofficeInviteRequestModel()
        inviteRequestModel.notify = false
        inviteRequestModel.invitations = [.init(id: userId, access: newAccess)]

        networkService.request(OnlyofficeAPI.Endpoints.Sharing.inviteRequest(folder: room), inviteRequestModel.toJSON()) {
            result, error in
            completion(error)
        }
    }
}
