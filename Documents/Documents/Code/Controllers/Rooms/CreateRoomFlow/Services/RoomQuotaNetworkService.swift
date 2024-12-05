//
//  RoomQuotaNetworkService.swift
//  Documents-opensource
//
//  Created by Pavel Chernyshev on 05.12.2024.
//  Copyright © 2024 Ascensio System SIA. All rights reserved.
//

import Foundation

final class RoomQuotaNetworkService {
    private var networkService = OnlyofficeApiClient.shared

    func loadPaymentQouta() async -> Bool {
        return await withCheckedContinuation { continuation in
            OnlyofficeApiClient.request(OnlyofficeAPI.Endpoints.Rooms.paymentQuota) { response, error in
                guard let statisticQouta = response?.result?.features.first(where: { $0.id == ASCPaymentQuotaFeatures.statistic }) else {
                    continuation.resume(returning: false)
                    return
                }
                continuation.resume(returning: statisticQouta.value == 1)
            }
        }
    }
}
