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
                print(": \(error.localizedDescription)")
            }
            
            isLoading = false
            dataModel.isInitalFetchCompleted = true
        }
    }
    
    func save() {
        let isPublic = dataModel.isTemplateAvailableForEveryone
        
        Task {
            await withTaskGroup(of: Void.self) { group in
                group.addTask {
                    do {
                        try await self.makeRoomTemplatePublic(isPublic: isPublic)
                    } catch {
                        print("Failed to update public status: \(error.localizedDescription)")
                    }
                }
                
                if self.isAccessListModified() {
                    group.addTask {
                        do {
                            try await self.setAccess()
                        } catch {
                            print("Failed to set access: \(error.localizedDescription)")
                        }
                    }
                }
            }
        }
    }

    func setAccess() async throws {
        let invitations: [ASCRoomTemplateInviteItemRequestModel] = dataModel.accessModels
            .filter { !$0.isOwner }
            .map {
                ASCRoomTemplateInviteItemRequestModel(id: $0.sharedTo?.userId, access: $0.access ?? .none)
            }
        try await roomTemplatesNetworkService.setAccess(template: template, invitations: invitations)
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
        dataModel.chooseFromListScreenDisplaying = true
    }
    
    func didToggleTemplateAvailableForEveryone(_ value: Bool) {
        dataModel.isTemplateAvailableForEveryone = value
    }
    
    func removeAccess(at offsets: IndexSet) {
        offsets
            .map { accessRowModels[$0].id }
            .forEach { userId in
                if let index = dataModel.accessModels.firstIndex(where: { $0.sharedTo?.userId == userId }) {
                    dataModel.accessModels[index].access = .none
                }
            }
    }
}

// MARK: - Mapper

private extension ASCTemplateAccessSettingsViewModel {
    
    var accessRowModels: [ASCAccessRowModel] {
        dataModel.accessModels
            .filter { $0.access != .none }
            .map {
                ASCAccessRowModel(
                    id: $0.sharedTo?.userId ?? "",
                    name: $0.sharedTo?.displayName ?? "",
                    image: .url($0.sharedTo?.avatar ?? "")
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
    
    private func isAccessListModified() -> Bool {
        dataModel.accessModels != dataModel.initialAccessModels
    }
}

// MARK: - Models

extension ASCTemplateAccessSettingsViewModel {
    struct DataModel {
        var isInitalFetchCompleted = false
        var isTemplateAvailableForEveryone = false
        var chooseFromListScreenDisplaying = false
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
        lhs.sharedTo?.userId == rhs.sharedTo?.userId
    }
}
