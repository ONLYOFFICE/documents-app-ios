//
//  ASCRoomTemplatesViewModel.swift
//  Documents
//
//  Created by Lolita Chernysheva on 03.06.2025.
//  Copyright © 2025 Ascensio System SIA. All rights reserved.
//

import Foundation
import SwiftUI

final class ASCRoomTemplatesViewModel: ObservableObject {
    @Published var templates: [ASCFolder] = []
    
    private lazy var roomTemplatesNetworkService = ServicesProvider.shared.roomTemplatesNetworkService
    
    func fetchTemplates() {
        roomTemplatesNetworkService.fetchTemplates { [weak self] result in
            guard let self else { return }
            switch result {
            case let .success(templates):
                self.templates = templates
            case let .failure(error):
                print(error.localizedDescription)
            }
        }
    }
}
