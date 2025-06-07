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
    
    var screenModel: ScreenModel {
        ScreenModel(
            accessRowModels: accessRowModels
        )
    }
    
    private var template: ASCTemplate
    
    private lazy var roomTemplatesNetworkService = ServicesProvider.shared.roomTemplatesNetworkService
    
    init(template: ASCTemplate) {
        self.template = template
    }
}

// MARK: - Public methods

extension ASCTemplateAccessSettingsViewModel {
    
    func fetchAccessList() {
        Task {
            do {
                let result = try await roomTemplatesNetworkService.getAccessList(template: template)
                dataModel.accessModels = result
            } catch {
                print("Failed to fetch template access: \(error.localizedDescription)")
            }
        }
    }
    
    func save() {
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

// MARK: - Models

extension ASCTemplateAccessSettingsViewModel {
    struct DataModel {
        var isTemplateAvailableForEveryone = false
        fileprivate(set) var chooseFromListScreenDisplaying = false
        fileprivate var accessModels: [ASCTemplateAccessModel]
        
        static let empty = DataModel(accessModels: [])
    }
    
    struct ScreenModel {
        let accessRowModels: [ASCAccessRowModel]
    }
}
