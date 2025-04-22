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
        loadData { result in
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
    
    func loadData(completion: @escaping (Result<[ASCFile], Error>) -> Void) {
        networkService.request(OnlyofficeAPI.Endpoints.Files.getVersionHistory(file: file)) { result, error in
            guard let versions = result?.result else {
                if let error {
                    completion(.failure(error))
                } else {
                    completion(.failure(RoomSharingNetworkService.Errors.emptyResponse))//MARK: - TODO
                }
                return
            }
            completion(.success(versions))
            
        }
        
        
    }
}

struct VersionViewModel: Identifiable {
    var id: UUID
    let versionNumber: Int
    let dateDescription: Date
    let author: String
    let comment: String
}
