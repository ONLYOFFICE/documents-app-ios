//
//  ShareSettingsAPIWorkerProtocol.swift
//  Documents
//
//  Created by Павел Чернышев on 19.07.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import Foundation

protocol ASCShareSettingsAPIWorkerProtocol {
    func convertToParams(shareItems: [ASCShareInfo]) -> [String: Any]
    func convertToParams(items: [(rightHolderId: String, access: ASCShareAccess)]) -> [String: Any]
    func makeApiRequest(entity: ASCEntity) -> String?
}
