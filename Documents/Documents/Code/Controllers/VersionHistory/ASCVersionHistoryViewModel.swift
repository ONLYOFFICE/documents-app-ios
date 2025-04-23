//
//  ASCVersionHistoryViewModel.swift
//  Documents
//
//  Created by Lolita Chernysheva on 21.04.2025.
//  Copyright © 2025 Ascensio System SIA. All rights reserved.
//

import Combine
import SwiftUI
import MBProgressHUD

final class ASCVersionHistoryViewModel: ObservableObject {
    
    @Published var versions: [VersionViewModel] = []
    @Published var isActivityIndicatorVisible = false
    @Published var resultModalModel: ResultViewModel?
    
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
        isActivityIndicatorVisible = true

        networkService.restoreVersion(file: file, versionNumber: version.versionNumber) { result in
            DispatchQueue.main.async {
                self.isActivityIndicatorVisible = false
                switch result {
                case .success:
                    self.resultModalModel = .init(
                        result: .success,
                        message: NSLocalizedString("Version restored", comment: "")
                    )
                    self.fetchVersions()
                case let .failure(error):
                    self.resultModalModel = .init(
                        result: .failure,
                        message: error.localizedDescription
                    )
                }
            }
        }
    }
    
    func editComment(comment: String, versionNumber: Int) {
        isActivityIndicatorVisible = true
        networkService.editComment(file: file, comment: comment, versionNumber: versionNumber) { result in
            DispatchQueue.main.async {
                self.isActivityIndicatorVisible = false
                switch result {
                case let .success(comment):
                    self.resultModalModel = .init(
                        result: .success,
                        message: NSLocalizedString("", comment: "")
                    )
                    self.fetchVersions()
                case let .failure(error):
                    self.resultModalModel = .init(
                        result: .failure,
                        message: error.localizedDescription
                    )
                }
            }
        }
    }
    
    func deleteVersion(version: VersionViewModel) {
        isActivityIndicatorVisible = true

        networkService.deleteVersion(file: file, versionNember: version.versionNumber) { [weak self] status, progress, result, error, cancel in
            guard let self else { return }

            switch status {
            case .begin:
                break
            case .progress:
                DispatchQueue.main.async {
                    MBProgressHUD.currentHUD?.progress = progress
                }

            case .error:
                DispatchQueue.main.async {
                    self.resultModalModel = .init(
                        result: .failure,
                        message: error?.localizedDescription ?? NSLocalizedString("Could not delete the version.", comment: "")
                    )
                    self.isActivityIndicatorVisible = false
                }

            case .end:
                DispatchQueue.main.async {
                    self.resultModalModel = .init(
                        result: .success,
                        message: NSLocalizedString("Version deleted", comment: "")
                    )
                    self.isActivityIndicatorVisible = false
                    self.fetchVersions()
                }
            }
        }
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
