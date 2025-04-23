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
    
    private var file: ASCFile
    private var networkService: ASCVersionHistoryNetworkServiceProtocol
    
    var fileTitle: String {
        file.title
    }
    
    var latestVersionNumber: Int {
        versions.first?.versionNumber ?? 1
    }
        
    init(file: ASCFile, networkService: ASCVersionHistoryNetworkServiceProtocol) {
        self.file = file
        self.networkService = networkService
    }
    
    func fetchVersions() {
        networkService.loadData(file: file) { result in
            switch result {
            case let .success(files):
                let mapped = files.map {
                    self.mapToVersionViewModel(
                        version: $0,
                        latestVersionNumber: files.first?.version ?? 1
                    )
                }
                DispatchQueue.main.async {
                    self.versions = mapped
                }
            case let .failure(error):
                print(error.localizedDescription)
            }
        }
    }

    
    func restoreVersion(version: VersionViewModel) {
        networkService.restoreVersion(file: file, versionNumber: version.versionNumber) { result in
            switch result {
            case .success:
                DispatchQueue.main.async {
                    self.fetchVersions()
                }
            case let .failure(error):
                print(error.localizedDescription)
            }
        }
    }
    
    func editComment(comment: String) {
        
    }
    
    func deleteVersion(version: VersionViewModel) {
        
    }
}

//MARK: - private methods

private extension ASCVersionHistoryViewModel {
    
    func mapToVersionViewModel(version: ASCFile, latestVersionNumber: Int) -> VersionViewModel {
        VersionViewModel(
            id: UUID(),
            versionNumber: version.version,
            dateDescription: version.updated ?? Date(),
            author: version.createdBy?.displayName ?? "",
            comment: version.comment ?? "",
            canRestore: version.version < latestVersionNumber,
            canDelete: version.version < latestVersionNumber
        )
    }
}

struct VersionViewModel: Identifiable {
    var id: UUID
    let versionNumber: Int
    let dateDescription: Date
    let author: String
    let comment: String
    var canRestore: Bool
    var canDelete: Bool
}
