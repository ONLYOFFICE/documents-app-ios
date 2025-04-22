//
//  ASCVersionHistoryViewModel.swift
//  Documents
//
//  Created by Lolita Chernysheva on 21.04.2025.
//  Copyright © 2025 Ascensio System SIA. All rights reserved.
//

import Combine
import SwiftUI

final class ASCVersionHistoryViewModel: ObservableObject {
    
    @Published var versions: [VersionViewModel] = []
    
    var provider: ASCFileProviderProtocol
    var file: ASCFile
    
    private var networkService = OnlyofficeApiClient.shared
    
    init(provider: ASCFileProviderProtocol, file: ASCFile) {
        self.provider = provider
        self.file = file
        
    }
    
    func fetchVersions() {
    }

    
    func restoreVersion() {
        
    }
    
    func editComment(comment: String) {
        
    }
    
    func deleteVersion() {
        
    }
}

//MARK: - private methods

private extension ASCVersionHistoryViewModel {
    
    func mapToVersionViewModel(version: ASCFile) -> VersionViewModel {
        return VersionViewModel(
            id: UUID(),
            versionNumber: version.version,
            dateDescription: version.updated ?? Date(), //TODO: -
            author: version.createdBy?.displayName ?? "",
            comment: version.comment ?? "")
    }
}

struct VersionViewModel: Identifiable {
    var id: UUID
    let versionNumber: Int
    let dateDescription: Date
    let author: String
    let comment: String
}
