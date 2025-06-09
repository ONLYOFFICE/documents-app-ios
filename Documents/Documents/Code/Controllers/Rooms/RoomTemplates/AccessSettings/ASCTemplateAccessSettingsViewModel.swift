//
//  ASCAccessSettingsViewModel.swift
//  Documents
//
//  Created by Lolita Chernysheva on 06.06.2025.
//  Copyright © 2025 Ascensio System SIA. All rights reserved.
//

import Combine
import Foundation
import SwiftUI

@MainActor
final class ASCTemplateAccessSettingsViewModel: ObservableObject {
    
    typealias ASCTemplate = ASCFolder
    
    @Published var dataModel: DataModel = .empty
    @Published var isLoading = true
    
    var screenModel: ScreenModel {
        ScreenModel(
            accessRowModels: accessRowModels
        )
    }
    
    var template: ASCTemplate
    var templateAdmin: ASCUser?
    
    private lazy var roomTemplatesNetworkService = ServicesProvider.shared.roomTemplatesNetworkService
    
    init(template: ASCTemplate) {
        self.template = template
        self.templateAdmin = template.createdBy
    }
}

// MARK: - Public methods

extension ASCTemplateAccessSettingsViewModel {
    
    func loadData() {
        guard dataModel.isInitalFetchCompleted == false else { return }
        isLoading = true
        Task {
            async let accessList = fetchAccessList()
            async let isPublic = isRoomTemplatePublic()
            
            do {
                let (list, isPublic) = try await (accessList, isPublic)
                self.dataModel.initialAccessModels = list
                self.dataModel.accessModels = list
                self.dataModel.isTemplateAvailableForEveryone = isPublic
            } catch {
                log.error(": \(error.localizedDescription)")
            }
            
            isLoading = false
            dataModel.isInitalFetchCompleted = true
        }
    }
    
    func save() async {
        isLoading = true
        dataModel.saveButtonIsEnabled = false
        let isPublic = dataModel.isTemplateAvailableForEveryone
        do {
            try await self.makeRoomTemplatePublic(isPublic: isPublic)
            try await self.setAccess()
        } catch {
            log.error("Failed to update template: \(error.localizedDescription)")
        }
        isLoading = false
        dataModel.dissmiss = true
    }

    func setAccess() async throws {
        let invitations: [ASCRoomTemplateInviteItemRequestModel] = dataModel.accessModels
            .filter { !$0.isOwner }
            .compactMap {
                guard let id = $0.sharedTo?.id else { return nil }
                return ASCRoomTemplateInviteItemRequestModel(
                    id: id,
                    access: $0.access ?? .none
                )
            }
        _ = try await roomTemplatesNetworkService.setAccess(
            template: template,
            invitations: invitations
        )
    }

    func makeRoomTemplatePublic(isPublic: Bool) async throws {
        guard let templateId = Int(template.id) else { return }
        try await roomTemplatesNetworkService.setRoomTemplateAsPublic(templateId: templateId, isPublic: isPublic)
    }
    
    func setRoomTemplateAccess() {
        let inviteRequestModel = OnlyofficeInviteRequestModel()
        inviteRequestModel.notify = false
    }
    
    func didTapChooseFromList() {
        dataModel.isChooseFromListScreenDisplaying = true
    }
    
    func didToggleTemplateAvailableForEveryone(_ value: Bool) {
        dataModel.isTemplateAvailableForEveryone = value
    }
    
    func removeAccess(at offsets: IndexSet) {
        offsets
            .map { accessRowModels[$0].id }
            .forEach { id in
                if let index = dataModel.accessModels.firstIndex(where: { $0.sharedTo?.id == id }) {
                    dataModel.accessModels[index].access = ASCShareAccess.none
                }
            }
    }
    
    func onChooseMembersAdd(model: ASCChooseRoomTemplateMembersViewModel.SelectedMembers) {
        dataModel.isChooseFromListScreenDisplaying = false
        dataModel.accessModels.append(contentsOf:
            model.users.map { user in
                return ASCTemplateAccessModel(
                    access: .read,
                    sharedTo: ASCTemplateAccessSharedToModel(
                        id: user.userId,
                        name: user.displayName,
                        avatar: user.avatar
                    ),
                    subjectType: .user
                )
            }
        )
        dataModel.accessModels.append(contentsOf:
            model.groups.map { group in
                ASCTemplateAccessModel(
                    access: .read,
                    sharedTo: ASCTemplateAccessSharedToModel(
                        id: group.id,
                        name: group.name
                    ),
                    subjectType: .group
                )
            }
        )
    }
}

// MARK: - Mapper

private extension ASCTemplateAccessSettingsViewModel {
    
    var accessRowModels: [ASCAccessRowModel] {
        dataModel.accessModels
            .filter { $0.access != ASCShareAccess.none }
            .map {
                ASCAccessRowModel(
                    id: $0.sharedTo?.id ?? "",
                    name: $0.sharedTo?.name ?? "",
                    image: {
                        switch $0.subjectType {
                        case .user:
                                .url($0.sharedTo?.avatar ?? "")
                        case .group:
                                .asset(Asset.Images.avatarDefaultGroup)
                        case .none:
                                .asset(Asset.Images.avatarDefault)
                        }
                    }($0)
                )
            }
    }
}

//MARK: - Private methods

private extension ASCTemplateAccessSettingsViewModel {
   func fetchAccessList() async throws ->  [ASCTemplateAccessModel] {
        try await roomTemplatesNetworkService.getAccessList(template: template)
   }

    func isRoomTemplatePublic() async throws -> Bool {
       try await roomTemplatesNetworkService.getIsRoomTemplateAvailableForEveryone(template: template)
    }
}

// MARK: - Models

extension ASCTemplateAccessSettingsViewModel {
    struct DataModel {
        var dissmiss = false
        var isInitalFetchCompleted = false
        var saveButtonIsEnabled: Bool = true
        var isTemplateAvailableForEveryone = false
        var isChooseFromListScreenDisplaying = false
        fileprivate var initialAccessModels: [ASCTemplateAccessModel] = []
        fileprivate var accessModels: [ASCTemplateAccessModel]
        
        static let empty = DataModel(accessModels: [])
    }
    
    struct ScreenModel {
        let accessRowModels: [ASCAccessRowModel]
    }
}

extension ASCTemplateAccessModel: Equatable {
    static func == (lhs: ASCTemplateAccessModel, rhs: ASCTemplateAccessModel) -> Bool {
        lhs.sharedTo?.id == rhs.sharedTo?.id
    }
}
