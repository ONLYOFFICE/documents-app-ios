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
        dataModel.isTemplateAvailableForEveryone
        ? makeRoomTemplatePublic()
        : setAccess()
       
    }
    
    func setAccess() {
        let invitations: [ASCRoomTemplateInviteItemRequestModel] = dataModel.accessModels
            .filter { !$0.isOwner }
            .map {
            ASCRoomTemplateInviteItemRequestModel(id: $0.sharedTo?.userId, access: $0.access ?? .none)
        }
        Task {
            do {
                let result = try await roomTemplatesNetworkService.setAccess(template: template, invitations: invitations)
            } catch {
                print("Failed to set access settings: \(error.localizedDescription)")
            }
        }
    }
    
    func makeRoomTemplatePublic() {
        guard let templateId = Int(template.id) else { return }
        Task {
            do {
                let result = try await roomTemplatesNetworkService.setRoomTemplateAsPublic(templateId: templateId, isPublic: true)
            }
        }
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
}

// MARK: - Models

extension ASCTemplateAccessSettingsViewModel {
    struct DataModel {
        var isInitalFetchCompleted = false
        var isTemplateAvailableForEveryone = false
        var chooseFromListScreenDisplaying = false
        fileprivate var accessModels: [ASCTemplateAccessModel]
        
        static let empty = DataModel(accessModels: [])
    }
    
    struct ScreenModel {
        let accessRowModels: [ASCAccessRowModel]
    }
}
