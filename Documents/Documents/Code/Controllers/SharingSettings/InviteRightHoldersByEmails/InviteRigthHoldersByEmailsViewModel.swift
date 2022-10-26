//
//  InviteRigthHoldersByEmailsViewModel.swift
//  Documents
//
//  Created by Pavel Chernyshev on 25/10/22.
//  Copyright © 2022 Ascensio System SIA. All rights reserved.
//

import Foundation

typealias Email = String

protocol InviteRigthHoldersByEmailsViewModel: AnyObject {
    func invite(emails: [Email], access: ASCShareAccess, completion: @escaping (Error?) -> Void)
}

class InviteRigthHoldersByEmailsViewModelImp: InviteRigthHoldersByEmailsViewModel {
    private var entity: ASCEntity
    private var apiWorker: ASCShareSettingsAPIWorkerProtocol

    init(entity: ASCEntity, apiWorker: ASCShareSettingsAPIWorkerProtocol) {
        self.apiWorker = apiWorker
        self.entity = entity
    }

    func invite(emails: [Email], access: ASCShareAccess, completion: @escaping (Error?) -> Void) {
        guard let apiRequest = apiWorker.makeApiRequest(entity: entity, for: .set) else {
            log.error("Couldn't make an api request on entity")
            completion(NetworkingError.invalidData)
            return
        }

        let json = makeJsonParams(emails: emails, access: access)

        OnlyofficeApiClient.request(apiRequest, json) { _, error in
            if error != nil {
                log.error(error?.localizedDescription ?? "")
            }
            completion(error)
        }
    }
    
    private func makeJsonParams(emails: [Email], access: ASCShareAccess) -> [String: Any] {

        let inviteRequestModel = OnlyofficeInviteRequestModel()
        inviteRequestModel.notify = false
        inviteRequestModel.inviteMessage = nil
        inviteRequestModel.invitations = emails.compactMap {
            return .init(email: $0, access: access)
        }
        return inviteRequestModel.toJSON()
    }
}
