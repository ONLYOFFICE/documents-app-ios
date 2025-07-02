//
//  ASCVersionHistoryViewModel.swift
//  Documents
//
//  Created by Lolita Chernysheva on 21.04.2025.
//  Copyright © 2025 Ascensio System SIA. All rights reserved.
//

import Combine
import MBProgressHUD
import SwiftUI

final class ASCVersionHistoryViewModel: ObservableObject {
    @Published var screenModel = ASCVersionHistoryScreenModel()
    @Published var versions: [VersionViewModel] = []
    @Published var isActivityIndicatorVisible = false
    @Published var resultModalModel: ResultViewModel?

    private var openFile: (ASCFile) -> Void
    private var downloadFile: (ASCFile) -> Void

    private var file: ASCFile
    private var networkService: ASCVersionHistoryNetworkServiceProtocol

    var fileTitle: String {
        file.title
    }

    var latestVersionNumber: Int {
        versions.first?.versionNumber ?? 1
    }

    init(file: ASCFile,
         networkService: ASCVersionHistoryNetworkServiceProtocol,
         completion: @escaping (ASCFile) -> Void,
         download: @escaping (ASCFile) -> Void)
    {
        self.file = file
        self.networkService = networkService
        openFile = completion
        downloadFile = download
    }

    func onAppear() {
        fetchVersions()
    }

    func triggerRestoreAlert(for version: VersionViewModel) {
        screenModel.activeAlert = .restore(version)
    }

    func triggerDeleteAlert(for version: VersionViewModel) {
        screenModel.activeAlert = .delete(version)
    }

    func triggerEditComment(for version: VersionViewModel) {
        screenModel.versionToEdit = version
        screenModel.showEditCommentAlert = true
    }

    func triggerOpenVersion(_ version: VersionViewModel, dismiss: @escaping () -> Void) {
        let file = version.versionFile
        openVersion(file: file, dismiss: dismiss)
    }

    func triggerDownloadVersion(_ version: VersionViewModel, dismiss: @escaping () -> Void) {
        let file = version.versionFile
        downloadVersion(file: file, dismiss: dismiss)
    }

    func clearEditCommentState() {
        screenModel.versionToEdit = nil
        screenModel.showEditCommentAlert = false
    }

    func triggerMoreSheet(version: VersionViewModel) {
        screenModel.versionForBottomSheet = version
        screenModel.isShowingBottomSheet = true
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
                        message: NSLocalizedString("Restored", comment: "")
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
                        message: NSLocalizedString("Deleted", comment: "")
                    )
                    self.isActivityIndicatorVisible = false
                    self.fetchVersions()
                }
            }
        }
    }
}

// MARK: - private methods

private extension ASCVersionHistoryViewModel {
    func mapToVersionViewModel(version: ASCFile, latestVersionNumber: Int) -> VersionViewModel {
        VersionViewModel(
            id: UUID(),
            versionFile: version,
            versionNumber: version.version,
            dateDescription: version.updated ?? Date(),
            author: version.updatedBy?.displayName ?? "",
            comment: version.comment ?? "",
            canRestore: version.version < latestVersionNumber,
            canDelete: (version.version < latestVersionNumber) && version.security.editHistory
        )
    }

    func openVersion(file: ASCFile, dismiss: @escaping () -> Void) {
        dismiss()
        openFile(file)
    }

    func downloadVersion(file: ASCFile, dismiss: @escaping () -> Void) {
        dismiss()
        downloadFile(file)
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
}

struct VersionViewModel: Identifiable {
    var id: UUID
    let versionFile: ASCFile
    let versionNumber: Int
    let dateDescription: Date
    let author: String
    let comment: String
    var canRestore: Bool
    var canDelete: Bool
}
