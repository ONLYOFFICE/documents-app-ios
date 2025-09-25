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
    @State var onGoToRoomTapped: () -> Void

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
                        ZStack {
                            VDRFillingStatusTimelineView(
                                rowViewModels: viewModel.state.events,
                                model: VDRFillingStatusTimelineViewModel(formFillingStatus: viewModel.file.formFillingStatus)
                            )
                            .padding(.horizontal)
                            
                            if viewModel.state.isInitialLoading || viewModel.state.isContentLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .primary))
                                    .scaleEffect(1.2)
                            }
                        }
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

                if viewModel.state.isActionLoading && !viewModel.state.isInitialLoading {
                    FullScreenLoader()
                }
            }
        }
        .navigationTitle("Filling status")
        .navigationBarItems(leading: Button(NSLocalizedString("Cancel", comment: ""), action: { presentationMode.wrappedValue.dismiss() }))
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private var header: some View {
        VDRFillingStatusHeaderView(
            title: screenHeaderTitle,
            subtitle: screenHeaderSubtitle,
            isReady: viewModel.isOpenAfterStartFilling
        )
    }

    private var screenHeaderTitle: String {
        return switch viewModel.file.formFillingStatus {
        case .yourTurn:
            NSLocalizedString("Form is ready for filling in room", comment: "")
        case .inProgress:
            NSLocalizedString("Form is ready for filling in room", comment: "")
        case .complete:
            NSLocalizedString("Form Finalized", comment: "")
        default:
            NSLocalizedString("Form is ready for filling in room", comment: "")
        }
    }

    private var screenHeaderSubtitle: String {
        return switch viewModel.file.formFillingStatus {
        case .yourTurn:
            NSLocalizedString("You are assigned to fill out the form as the first role. A\n notification has been sent to your email. You can start filling\n it out now or copy the filling link and return later.", comment: "")
        case .inProgress:
            NSLocalizedString("A notification has already been sent to the user in the first\n role, prompting them to fill out the form. You can navigate\n to the room or share the filling link with the participants.", comment: "")
        default:
            NSLocalizedString("In this panel you can monitor the completion of\n the form in which you participate or in which you\n are the organizer of completion", comment: "")
        }
    }

    @ViewBuilder
    private var footer: some View {
        if viewModel.state.stopEnable || viewModel.state.fillEnable {
            VDRFillingStatusFooterView(
                stopEnabled: viewModel.state.stopEnable,
                fillEnabled: viewModel.state.fillEnable,
                isReadyForFillingScreenStatus: viewModel.isOpenAfterStartFilling,
                fillingStatus: viewModel.file.formFillingStatus,
                onStop: viewModel.stopFilling,
                onFill: {
                    presentationMode.wrappedValue.dismiss()
                    onFillTapped()
                },
                onCopy: {
                    viewModel.onCopyLink()
                },
                onGoToRoom: {
                    presentationMode.wrappedValue.dismiss()
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
