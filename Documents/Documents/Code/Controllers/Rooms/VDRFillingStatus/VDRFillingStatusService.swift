//
//  VDRFillingStatusService.swift
//  Documents-
//
//  Created by Pavel Chernyshev on 19.05.2025.
//  Copyright © 2025 Ascensio System SIA. All rights reserved.
//

import MBProgressHUD

actor VDRFillingStatusService {
    private let networkService = OnlyofficeApiClient.shared

    func fetchStatus(file: ASCFile) async throws -> [VDRFillingStatusResponceModel]? {
        try await OnlyofficeApiClient.request(OnlyofficeAPI.Endpoints.Files.getFillingStatus(file: file))?.result
    }

    func stopFilling(file: ASCFile) async throws {
        let statusCode = try await OnlyofficeApiClient.request(
            OnlyofficeAPI.Endpoints.Files.manageFormFilling(file: file),
            ManageFormFillingRequestModel(
                formId: Int(file.id) ?? .zero,
                action: .stop
            ).dictionary
        )?.statusCode
        if let statusCode, !(200 ..< 300).contains(statusCode) {
            throw NetworkingError.statusCode(statusCode)
        }
    }

    func setupRoomsQuota(model: ASCPaymentQuotaSettings) async -> ASCPaymentQuotaSettings? {
        try? await OnlyofficeApiClient.request(
            OnlyofficeAPI.Endpoints.Rooms.roomQuotaSettings,
            model.toJSON()
        )?.result
    }

    func startFilling() async throws {}

    @MainActor
    func copyLink(file: ASCFile) {
        let hud = MBProgressHUD.showTopMost()
        if let urlString = file.viewUrl,
           let link = URL(string: urlString)
        {
            UIPasteboard.general.string = link.absoluteString
            hud?.setState(result: .success(NSLocalizedString("Link successfully\ncopied to clipboard", comment: "")))
        } else {
            hud?.setState(result: .failure(nil))
        }
        hud?.hide(animated: true, afterDelay: .standardDelay)
    }
}

extension VDRFillingStatusService {
    enum Errors: Error {
        case emptyResponse
    }
}

extension VDRFillingStatusService {
    struct ManageFormFillingRequestModel: Codable {
        var formId: Int
        var action: ManageFormFillingAction
    }

    enum ManageFormFillingAction: Int, Codable {
        case stop = 0
        case resume = 1
    }
}
