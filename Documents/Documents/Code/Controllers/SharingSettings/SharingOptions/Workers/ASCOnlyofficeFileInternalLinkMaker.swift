//
//  ASCOnlyofficeFileInternalLinkMaker.swift
//  Documents
//
//  Created by Павел Чернышев on 06.07.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import Foundation

class ASCOnlyofficeFileInternalLinkMaker: ASCEntityLinkMakerProtocol {
    
    fileprivate var relativeLink = "Products/Files/DocEditor.aspx?fileid="
    
    func make(entity: ASCEntity) -> String? {
        guard let file = entity as? ASCFile else { return nil }
        guard let baseUrl = cutBaseUrl(from: file) else { return nil }
        let link = baseUrl.appending(relativeLink).appending(file.id)
        return link
    }
    
    private func cutBaseUrl(from file: ASCFile) -> String? {
        guard let viewUrl = file.viewUrl else { return nil }
        return viewUrl.matches(for: "https://([\\w.]+)/").first
    }
}
