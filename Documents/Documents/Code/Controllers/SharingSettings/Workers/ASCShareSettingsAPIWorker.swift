//
//  ShareSettingsAPIWorker.swift
//  Documents
//
//  Created by Павел Чернышев on 19.07.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import Foundation

class ASCShareSettingsAPIWorker: ASCShareSettingsAPIWorkerProtocol {
    func convertToParams(shareItems: [ASCShareInfo]) -> [String : Any] {
        var shares: [[String: Any]] = []
        
        for share in shareItems {
            if let itemId = share.user?.userId ?? share.group?.id {
                shares.append([
                    "ShareTo": itemId,
                    "Access": share.access.rawValue
                ])
            }
        }
        
        return sharesToParams(shares: shares)
    }
    
    func convertToParams(items: [(rightHolderId: String, access: ASCShareAccess)]) -> [String: Any] {
        var shares: [[String: Any]] = []
        for item in items {
            shares.append([
                "ShareTo": item.rightHolderId,
                "Access": item.access.rawValue
            ])
        }
        return sharesToParams(shares: shares)
    }
    
    private func sharesToParams(shares: [[String: Any]]) -> [String: Any] {
        var params: [String: Any] = [:]
        
        for (index, dictinory) in shares.enumerated() {
            for (key, value) in dictinory {
                params["share[\(index)].\(key)"] = value
            }
        }
        return params
    }
    
    func makeApiRequest(entity: ASCEntity) -> String? {
        var request: String? = nil
        
        if let file = entity as? ASCFile {
            request = String(format: ASCOnlyOfficeApi.apiShareFile, file.id)
        } else if let folder = entity as? ASCFolder {
            request = String(format: ASCOnlyOfficeApi.apiShareFolder, folder.id)
        }
        
        return request
    }
}
