//
//  InviteUsersViewModel.swift
//  Documents-opensource
//
//  Created by Pavel Chernyshev on 18.05.2024.
//  Copyright © 2024 Ascensio System SIA. All rights reserved.
//

import Combine
import Foundation
import SwiftUI

final class InviteUsersViewModel: ObservableObject {
    
    @Published var isLinkEnabled: Bool = true
    @Published var selectedAccessRight: ASCShareAccess
    @Published var link: String = ""
    @Published var isLoading: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    
    init(isLinkEnabled: Bool, selectedAccessRight: ASCShareAccess, link: String, isLoading: Bool, cancellables: Set<AnyCancellable> = Set<AnyCancellable>()) {
        self.isLinkEnabled = isLinkEnabled
        self.selectedAccessRight = selectedAccessRight
        self.link = link
        self.isLoading = isLoading
        self.cancellables = cancellables
    }

    func fetchData() {
        
    }
}
