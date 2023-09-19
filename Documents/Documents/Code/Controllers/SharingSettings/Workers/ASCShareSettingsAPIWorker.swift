//
//  ASCShareSettingsAPIWorker.swift
//  Documents
//
//  Created by Pavel Chernyshev on 19.07.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import Alamofire
import Foundation

class ASCShareSettingsAPIWorker: ASCShareSettingsAPIWorkerProtocol {
    func makeApiRequest(entity: ASCEntity, for reason: ShareSettingsAPIWorkerReason) -> Endpoint<OnlyofficeResponseArray<OnlyofficeShare>>? {
        var request: Endpoint<OnlyofficeResponseArray<OnlyofficeShare>>?

        if let file = entity as? ASCFile {
            request = OnlyofficeAPI.Endpoints.Sharing.file(file: file, method: reason.httpMethod)
        } else if let folder = entity as? ASCFolder {
            request = OnlyofficeAPI.Endpoints.Sharing.folder(folder: folder, method: reason.httpMethod)
        }
        return request
    }

    func convertToParams(entities: [ASCEntity]) -> [String: [ASCEntityId]]? {
        nil
    }
}
