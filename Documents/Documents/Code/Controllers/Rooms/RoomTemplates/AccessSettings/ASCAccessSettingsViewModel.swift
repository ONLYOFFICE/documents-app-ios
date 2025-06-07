//
//  ASCAccessSettingsViewModel.swift
//  Documents
//
//  Created by Lolita Chernysheva on 06.06.2025.
//  Copyright © 2025 Ascensio System SIA. All rights reserved.
//

import Combine
import Foundation

final class ASCAccessSettingsViewModel: ObservableObject {
    
    @Published var template: ASCFolder
    @Published var isTemplateAvailableForEveryone: Bool = false
    @Published var chooseFromListScreenDisplaying: Bool = false
    @Published var accessToTemplate: [ASCAccessRowModel] = []
    
    private lazy var roomTemplatesNetworkService = ServicesProvider.shared.roomTemplatesNetworkService
    
    init(template: ASCFolder) {
        self.template = template
    }
    
    func fetchAccessList() {
        Task {
            do {
                let result = try await roomTemplatesNetworkService.getAccessList(template: template)

                await MainActor.run {
                    accessToTemplate = result.map {
                        ASCAccessRowModel(
                            name: $0.sharedTo?.displayName ?? "",
                            image: .url($0.sharedTo?.avatar ?? "")
                        )
                    }
                }
            } catch {
                print("Failed to fetch template access: \(error.localizedDescription)")
            }
        }
    }
    
    func save() {
        
    }
    
    func setRoomTemplateAccess() {
        let inviteRequestModel = OnlyofficeInviteRequestModel()
        inviteRequestModel.notify = false
        
    
    }
    
    func removeAccess(at offsets: IndexSet) {
        accessToTemplate.remove(atOffsets: offsets)
    }
}
