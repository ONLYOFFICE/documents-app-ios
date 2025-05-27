//
//  VDRFillingStatusView.swift
//  Documents
//
//  Created by Pavel Chernyshev on 10.05.2025.
//  Copyright © 2025 Ascensio System SIA. All rights reserved.
//

import SwiftUI

/// Main view for Filling Status screen
struct VDRFillingStatusView: View {
    @StateObject var viewModel = VDRFillingStatusViewModel()

    var body: some View {
        ZStack {
            Color(UIColor.systemGray6).ignoresSafeArea()

            VStack(spacing: 0) {
                VDRFillingStatusHeaderView(
                    title: "Filling status",
                    onCancel: viewModel.loadStatus
                )

                if let app = viewModel.state.application {
                    VDRFillingStatusCardView(application: app)
                        .padding(.horizontal)
                        .padding(.top, 8)

                    VDRFillingStatusTimelineView(events: viewModel.state.events)
                        .padding(.horizontal)
                } else if viewModel.state.isInitialLoading {
                    Spacer()
                } else if let error = viewModel.state.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .padding()
                    Spacer()
                }

                VDRFillingStatusFooterView(
                    status: viewModel.state.application?.status,
                    isLoading: viewModel.state.isActionLoading,
                    onStop: viewModel.stopFilling,
                    onStart: viewModel.startFilling
                )
            }

            if viewModel.state.isInitialLoading {
                FullScreenLoader()
            }

            if viewModel.state.isActionLoading && !viewModel.state.isInitialLoading {
                OverlayLoader()
            }
        }
    }
}
