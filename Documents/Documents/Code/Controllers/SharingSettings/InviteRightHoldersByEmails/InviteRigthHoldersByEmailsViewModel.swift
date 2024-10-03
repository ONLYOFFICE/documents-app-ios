//
//  InviteRigthHoldersByEmailsViewModel.swift
//  Documents
//
//  Created by Pavel Chernyshev on 25/10/22.
//  Copyright © 2022 Ascensio System SIA. All rights reserved.
//

import Combine
import Foundation

typealias Email = String
typealias AllowedQouta = Int

protocol InviteRigthHoldersByEmailsViewModel: AnyObject {
    var managerQouta: ASCPaymentQuotaFeatures? { get }
    var currentAccessPubliser: Published<ASCShareAccess>.Publisher { get }
    var currentAccess: ASCShareAccess { get }
    var accessChangeHandler: (ASCShareAccess) -> Void { get }
    var accessProvides: () -> [ASCShareAccess] { get }
    var nextTapClosure: ([Email], ASCShareAccess) -> Void { get }

    func loadPaymentQouta(completion: @escaping () -> Void)
}

class InviteRigthHoldersByEmailsViewModelImp: InviteRigthHoldersByEmailsViewModel {
    var managerQouta: ASCPaymentQuotaFeatures?
    var currentAccessPubliser: Published<ASCShareAccess>.Publisher { $currentAccess }

    @Published var currentAccess: ASCShareAccess

    lazy var accessChangeHandler: (ASCShareAccess) -> Void = { [weak self] access in
        self?.currentAccess = access
    }

    let accessProvides: () -> [ASCShareAccess]
    let nextTapClosure: ([Email], ASCShareAccess) -> Void

    private var entity: ASCEntity
    private var apiWorker: ASCShareSettingsAPIWorkerProtocol

    init(entity: ASCEntity,
         currentAccess: ASCShareAccess,
         apiWorker: ASCShareSettingsAPIWorkerProtocol,
         accessProvider: ASCSharingSettingsAccessProvider,
         nextTapClosure: @escaping ([Email], ASCShareAccess) -> Void)
    {
        self.apiWorker = apiWorker
        self.currentAccess = currentAccess
        self.entity = entity
        self.nextTapClosure = nextTapClosure
        accessProvides = { accessProvider.get() }
        if !accessProvides().contains(currentAccess) {
            self.currentAccess = accessProvides().first ?? .read
        }
    }

    func loadPaymentQouta(completion: @escaping () -> Void) {
        OnlyofficeApiClient.request(OnlyofficeAPI.Endpoints.Rooms.paymentQuota) { [weak self] response, error in
            defer { completion() }
            guard let managerQouta = response?.result?.features.first(where: { $0.id == ASCPaymentQuotaFeatures.managerId }) else {
                return
            }
            self?.managerQouta = managerQouta
        }
    }

    private func makeJsonParams(emails: [Email], access: ASCShareAccess) -> [String: Any] {
        let inviteRequestModel = OnlyofficeInviteRequestModel()
        inviteRequestModel.notify = false
        inviteRequestModel.inviteMessage = nil
        inviteRequestModel.invitations = emails.compactMap {
            .init(email: $0, access: access)
        }
        return inviteRequestModel.toJSON()
    }
}
