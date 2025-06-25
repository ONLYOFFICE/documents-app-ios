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
    @ObservedObject var viewModel: VDRFillingStatusViewModel
    @Environment(\.presentationMode) var presentationMode

    @State var onFillTapped: () -> Void

    var body: some View {
        NavigationView {
            ZStack {
                Color(.secondarySystemBackground).ignoresSafeArea()

                VStack(spacing: 0) {
                    header

                    if let formInfo = viewModel.state.formInfo {
                        VDRFillingStatusFormCardView(formModel: formInfo)
                            .padding(.horizontal)
                            .padding(.top, 8)

                        sectionHeader(NSLocalizedString("Process details", comment: ""))
                        VDRFillingStatusTimelineView(
                            rowViewModels: viewModel.state.events,
                            model: VDRFillingStatusTimelineViewModel(formFillingStatus: viewModel.file.formFillingStatus)
                        )
                        .padding(.horizontal)
                    } else if viewModel.state.isInitialLoading || viewModel.state.isContentLoading {
                        Spacer()
                    } else if let error = viewModel.state.errorMessage {
                        Text(verbatim: error)
                            .foregroundColor(.red)
                            .padding()
                        Spacer()
                    }

                    footer
                }

                if viewModel.state.isInitialLoading || viewModel.state.isContentLoading {
                    FullScreenLoader()
                }

                if viewModel.state.isActionLoading && !viewModel.state.isInitialLoading {
                    OverlayLoader()
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private var header: some View {
        VDRFillingStatusHeaderView(
            title: NSLocalizedString("Filling status", comment: ""),
            subtitle: NSLocalizedString("In this panel you can monitor the completion of\nthe form in which you participate or in which you\nare the organizer of completion", comment: ""),
            onCancel: { presentationMode.wrappedValue.dismiss() }
        )
    }

    @ViewBuilder
    private var footer: some View {
        if viewModel.state.stopEnable || viewModel.state.fillEnable {
            VDRFillingStatusFooterView(
                stopEnabled: viewModel.state.stopEnable,
                fillEnabled: viewModel.state.fillEnable,
                onStop: viewModel.stopFilling,
                onFill: {
                    presentationMode.wrappedValue.dismiss()
                    onFillTapped()
                }
            )
        }
    }

    private func sectionHeader(_ text: String) -> some View {
        HStack {
            Text(verbatim: text)
                .textCase(.uppercase)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.horizontal)
                .padding(.top, 16)

            Spacer()
        }
    }
}
