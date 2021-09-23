//
//  ShareSettingsAPIWorkerProtocol.swift
//  Documents
//
//  Created by Павел Чернышев on 19.07.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import Foundation

protocol ASCShareSettingsAPIWorkerProtocol {
    func convertToParams(shareItems: [OnlyofficeShare]) -> [OnlyofficeShareItemRequestModel]
    func convertToParams(items: [(rightHolderId: String, access: ASCShareAccess)]) -> [OnlyofficeShareItemRequestModel]
    func makeApiRequest(entity: ASCEntity) -> Endpoint<OnlyofficeResponseArray<OnlyofficeShare>>?
}
