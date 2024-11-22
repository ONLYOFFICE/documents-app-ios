//
//  ASCOnlyofficeEntityInternalLinkMaker.swift
//  Documents
//
//  Created by Pavel Chernyshev on 06.07.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import Foundation

class ASCOnlyofficeEntityInternalLinkMaker: ASCEntityLinkMakerProtocol {
    fileprivate var relativeLink = "Products/Files/DocEditor.aspx?fileid="

    func make(entity: ASCEntity) -> String? {
        guard let file = entity as? ASCFile else {
            return make(from: entity as? ASCFolder)
        }
        guard let baseUrl = cutBaseUrl(from: file) else { return nil }
        let link = baseUrl.appending(relativeLink).appending(file.id)
        return link
    }

    private func make(from folder: ASCFolder?) -> String? {
        guard let folder else { return nil }
        if let baseUrl = ASCFileManager.onlyofficeProvider?.apiClient.baseURL?.absoluteString {
            let path = "%@/Products/Files/#%@"
            let urlStr = String(format: path, baseUrl, folder.id)
            return urlStr
        }
        return nil
    }

    private func cutBaseUrl(from file: ASCFile) -> String? {
        guard let viewUrl = file.viewUrl else { return nil }
        return viewUrl.matches(for: "https://([\\w.]+)/").first
    }
}
