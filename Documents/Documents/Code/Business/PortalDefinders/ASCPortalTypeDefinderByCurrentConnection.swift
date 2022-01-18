//
//  ASCPortalTypeDefinderByCurrentConnection.swift
//  Documents
//
//  Created by Павел Чернышев on 25.11.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import Foundation

class ASCPortalTypeDefinderByCurrentConnection: ASCPortalTypeDefinderProtocol {
    func definePortalType() -> ASCPortalType {
        let url: URL? = ASCFileManager.onlyofficeProvider?.apiClient.baseURL
        let definderByUrl = ASCPortalTypeDefinderByUrl(url: url)
        return definderByUrl.definePortalType()
    }
}
