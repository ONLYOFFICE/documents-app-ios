//
//  ShareSettingsAPIWorker.swift
//  Documents
//
//  Created by Павел Чернышев on 19.07.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import Foundation

class ASCShareSettingsAPIWorker: ASCShareSettingsAPIWorkerProtocol {
    func makeApiRequest(entity: ASCEntity) -> Endpoint<OnlyofficeResponseArray<OnlyofficeShare>>? {
        var request: Endpoint<OnlyofficeResponseArray<OnlyofficeShare>>?

        if let file = entity as? ASCFile {
            request = OnlyofficeAPI.Endpoints.Sharing.file(file: file)
        } else if let folder = entity as? ASCFolder {
            request = OnlyofficeAPI.Endpoints.Sharing.folder(folder: folder)
        }
        return request
    }

    func convertToParams(entities: [ASCEntity]) -> [String: [ASCEntityId]]? {
        nil
    }
}
