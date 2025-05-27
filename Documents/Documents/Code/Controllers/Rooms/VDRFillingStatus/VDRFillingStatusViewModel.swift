//
//  VDRFillingStatusViewModel.swift
//  Documents
//
//  Created by Pavel Chernyshev on 10.05.2025.
//  Copyright © 2025 Ascensio System SIA. All rights reserved.
//

import SwiftUI

// MARK: - Screen model

struct VDRFillingStatusState {
    var isInitialLoading = false
    var isContentLoading = false
    var isActionLoading = false
    var formInfo: VDRFillingStatusFormInfoModel?
    var stopEnable = false
    var fillEnable: Bool {
        formInfo?.status == .yourTurn
    }

    var events: [VDRFillingStatusEventRowViewModel] = []

    var errorMessage: String?
}

// MARK: - ViewModel

@MainActor
final class VDRFillingStatusViewModel: ObservableObject {
    @Published private(set) var state = VDRFillingStatusState()
    var file: ASCFile

    private let shortSlashDateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "dd/MM/yy"
        return df
    }()

    private let service: VDRFillingStatusService
    private let onStoppedSuccess: () -> Void

    init(
        service: VDRFillingStatusService = .init(),
        file: ASCFile,
        onStoppedSuccess: @escaping () -> Void
    ) {
        self.service = service
        self.file = file
        self.onStoppedSuccess = onStoppedSuccess
        loadStatus()
        setupFormInfo()
        setupActions()
    }

    // MARK: Setup

    private func setupFormInfo() {
        state.formInfo = VDRFillingStatusFormInfoModel(
            id: UUID(uuidString: file.id) ?? UUID(),
            title: file.title,
            subtitle: file.createdBy?.displayName ?? "",
            detail: file.created.map { shortSlashDateFormatter.string(from: $0) } ?? "",
            status: file.formFillingStatus
        )
    }

    private func setupActions() {
        state.stopEnable = file.security.stopFilling
    }

    // MARK: Requests

    private func loadStatus() {
        Task {
            do {
                state.isContentLoading = true
                if let statuses = try await service.fetchStatus(file: file) {
                    self.state.events = statuses.mapToVDRFillingStatusEventRowViewModel()
                }
            } catch {
                state.errorMessage = error.localizedDescription
            }
            state.isContentLoading = false
        }
    }

    func stopFilling() {
        let actionLoadingTask = getDelayedActionLoadingTask()

        Task {
            do {
                try await service.stopFilling(file: file)
                if let statuses = try await service.fetchStatus(file: file) {
                    self.state.events = statuses.mapToVDRFillingStatusEventRowViewModel()
                }
                file.formFillingStatus = .stopped
                setupFormInfo()
                state.stopEnable = false
                onStoppedSuccess()
            } catch {
                state.errorMessage = error.localizedDescription
            }
            actionLoadingTask?.cancel()
            state.isActionLoading = false
        }
    }
}
