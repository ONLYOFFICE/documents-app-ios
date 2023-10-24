//
//  ASCPersonalShareSettingsAPIWorker.swift
//  Documents
//
//  Created by Pavel Chernyshev on 24.11.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import Foundation

class ASCPersonalShareSettingsAPIWorker: ASCShareSettingsAPIWorkerProtocol {
    func makeApiRequest(entity: ASCEntity, for reason: ShareSettingsAPIWorkerReason) -> Endpoint<OnlyofficeResponseArray<OnlyofficeShare>>? {
        OnlyofficeAPI.Endpoints.Sharing.entitiesShare()
    }

    func convertToParams(entities: [ASCEntity]) -> [String: [ASCEntityId]]? {
        guard !entities.isEmpty else { return nil }
        let filesIds: [String] = entities.compactMap { ($0 as? ASCFile)?.id }
        let foldersIds: [String] = entities.compactMap { ($0 as? ASCFolder)?.id }

        guard !filesIds.isEmpty || !foldersIds.isEmpty else { return nil }

        var params: [String: [ASCEntityId]] = [:]

        if !filesIds.isEmpty {
            params["fileIds"] = filesIds
        }
        if !foldersIds.isEmpty {
            params["folderIds"] = foldersIds
        }

        return params
    }
}
