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
    
    init(file: ASCFile, networkService: ASCVersionHistoryNetworkServiceProtocol) {
        self.file = file
        self.networkService = networkService
    }
    
    func fetchVersions() {
        networkService.loadData(file: file) { result in
            switch result {
            case let .success(versions):
                let mapped = versions.map { self.mapToVersionViewModel(version: $0) }
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
            case let .success(version):
               print()
            case let .failure(error):
                print(error.localizedDescription)
            }
        }
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
            dateDescription: version.updated ?? Date(),
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
