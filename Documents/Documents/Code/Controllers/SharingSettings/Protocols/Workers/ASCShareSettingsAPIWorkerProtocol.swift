//
//  ShareSettingsAPIWorkerProtocol.swift
//  Documents
//
//  Created by Pavel Chernyshev on 19.07.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import Alamofire
import Foundation

enum ShareSettingsAPIWorkerReason {
    case get
    case set

    var httpMethod: HTTPMethod {
        switch self {
        case .get: return .get
        case .set: return .put
        }
    }
}

protocol ASCShareSettingsAPIWorkerProtocol {
    typealias ASCEntityId = String

    func convertToParams(shareItems: [OnlyofficeShare]) -> [OnlyofficeShareItemRequestModel]
    func convertToParams(items: [(rightHolderId: String, access: ASCShareAccess)]) -> [OnlyofficeShareItemRequestModel]
    func convertToParams(entities: [ASCEntity]) -> [String: [ASCEntityId]]?
    func makeApiRequest(entity: ASCEntity, for reason: ShareSettingsAPIWorkerReason) -> Endpoint<OnlyofficeResponseArray<OnlyofficeShare>>?
}

extension ASCShareSettingsAPIWorkerProtocol {
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
}
