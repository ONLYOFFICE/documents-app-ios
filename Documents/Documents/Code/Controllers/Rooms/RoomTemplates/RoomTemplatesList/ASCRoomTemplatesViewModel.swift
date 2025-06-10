//
//  ASCRoomTemplatesViewModel.swift
//  Documents
//
//  Created by Lolita Chernysheva on 03.06.2025.
//  Copyright © 2025 Ascensio System SIA. All rights reserved.
//

import Foundation
import SwiftUI

@MainActor
final class ASCRoomTemplatesViewModel: ObservableObject {
    @Published var templates: [ASCFolder] = []

    private lazy var roomTemplatesNetworkService = ServicesProvider.shared.roomTemplatesNetworkService

    func fetchTemplates() {
        Task {
            do {
                let result = try await roomTemplatesNetworkService.fetchTemplates()
                self.templates = result
            } catch {
                print("Failed to fetch templates: \(error.localizedDescription)")
            }
        }
    }
}
