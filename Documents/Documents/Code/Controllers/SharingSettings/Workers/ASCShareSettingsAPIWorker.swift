//
//  ShareSettingsAPIWorker.swift
//  Documents
//
//  Created by Павел Чернышев on 19.07.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import Foundation

class ASCShareSettingsAPIWorker: ASCShareSettingsAPIWorkerProtocol {
    func convertToParams(shareItems: [OnlyofficeShare]) -> [OnlyofficeShareItemRequestModel] {
        var shares: [OnlyofficeShareItemRequestModel] = []
        
        for share in shareItems {
            if let itemId = share.user?.userId ?? share.group?.id {
                shares.append(OnlyofficeShareItemRequestModel(shareTo: itemId, access: share.access))
            }
        }
        
        return shares
    }
    
    func convertToParams(items: [(rightHolderId: String, access: ASCShareAccess)]) -> [OnlyofficeShareItemRequestModel] {
        var shares: [OnlyofficeShareItemRequestModel] = []
        for item in items {
            shares.append(OnlyofficeShareItemRequestModel(shareTo: item.rightHolderId, access: item.access))
        }
        return shares
    }
    
    func makeApiRequest(entity: ASCEntity) -> Endpoint<OnlyofficeResponseArray<OnlyofficeShare>>? {
        var request: Endpoint<OnlyofficeResponseArray<OnlyofficeShare>>? = nil
        
        if let file = entity as? ASCFile {
            request = OnlyofficeAPI.Endpoints.Sharing.file(file: file)
        } else if let folder = entity as? ASCFolder {
            request = OnlyofficeAPI.Endpoints.Sharing.folder(folder: folder)
        }
        
        return request
    }
}
