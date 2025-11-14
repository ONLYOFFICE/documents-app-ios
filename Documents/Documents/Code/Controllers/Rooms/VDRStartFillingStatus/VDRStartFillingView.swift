//
//  VDRStartFillingView.swift
//  Documents
//
//  Created by Pavel Chernyshev on 25.04.2025.
//  Copyright © 2025 Ascensio System SIA. All rights reserved.
//

import Kingfisher
import SwiftUI

// MARK: - Under construction. Docspace 3.2 or later

enum VDRStartFillingResult {
    case close
    case fill
    case fail
}

struct VDRStartFillingView: View {
    @Environment(\.presentationMode) var presentationMode

    @ObservedObject var viewModel: VDRStartFillingViewModel

    let onDismiss: (Result<VDRStartFillingResult, any Error>) -> Void

    var body: some View {
        NavigationView {
            ZStack(alignment: .bottom) {
                Color(UIColor.systemGray6).ignoresSafeArea()

                VStack(spacing: 0) {
                    header

                    List {
                        Section {
                            ForEach(viewModel.state.roles) { role in
                                RoleRow(role: role) {
                                    viewModel.roleTapped(role)
                                }
                                .deleteDisabled(role.appliedUser == nil)
                            }
                            .onDelete { indexSet in
                                indexSet.map { viewModel.state.roles[$0] }
                                    .forEach(viewModel.deleteRoleAppliedUser)
                            }
                        } header: {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("In this panel you can monitor the completion of the form in which you participate or in which you are the organizer of completion")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .multilineTextAlignment(.center)
                                    .textCase(nil)

                                Text("Roles from the form:")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                    .textCase(nil)
                            }
                            .padding(.vertical, 8)
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
                    .listRowSeparatorAvailable()
                }

                footer
            }
            .navigateToChooseMembers(isActive: $viewModel.state.isChooseFromListScreenDisplaying, viewModel: viewModel)
            .navigateToFillingStatus(isActive: $viewModel.state.isFillingStatusScreenDisplaying, viewModel: viewModel)
        }
        .stackNavigationStyleForDevice()
        .onChange(of: viewModel.state.finishWithFill) { value in
            if value {
                onDismiss(.success(.fill))
            }
        }
        .onChange(of: viewModel.state.finishWithGoToRoom) { value in
            if value {
                onDismiss(.success(.close))
            }
        }
        .onChange(of: viewModel.state.finishWithError) {
            if let error = $0 {
                onDismiss(.failure(error))
            }
        }
        .onAppear(perform: {
            viewModel.onAppear()
        })
        .onDisappear {
            onDismiss(.success(.fail))
        }
    }

    // MARK: — Header

    private var header: some View {
        ZStack {
            HStack {
                Button(NSLocalizedString("Close", comment: ""), action: { presentationMode.wrappedValue.dismiss() })
                    .foregroundColor(Asset.Colors.brend.swiftUIColor)

                Spacer()
            }
            HStack {
                Spacer()

                Text("Start filling")
                    .font(.headline)

                Spacer()
            }
        }
        .padding()
    }

    // MARK: — Footer

    private var footer: some View {
        HStack {
            Spacer()
            Button("Start", action: viewModel.startTapped)
                .brandButton(.filledCapsule)
                .disabled(!viewModel.state.isStartEnabled)
                .padding(.vertical, 16)
                .padding(.horizontal)
        }
        .background(Color.secondarySystemGroupedBackground.ignoresSafeArea(edges: [.horizontal, .bottom]))
    }
}

// MARK: — Row

struct RoleRow: View {
    typealias RoleItem = VDRStartFillingRoleItem

    let role: RoleItem
    let onTap: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Text("\(role.number)")
                .font(.body)
                .frame(width: 20, alignment: .leading)
                .foregroundColor(.secondary)
            if let user = role.appliedUser {
                imageView(for: .url(user.avatar ?? ""))
            } else {
                Circle()
                    .fill(role.color)
                    .frame(width: .imageWidth, height: .imageHeight)
                    .overlay(Image(systemName: "plus").foregroundColor(.secondary))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: role.appliedUser?.displayName ?? role.title)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                if let accessValue = role.appliedUser?.userType.description {
                    Text(accessValue)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()
        }
        .padding(.horizontal)
        .background(Color.secondarySystemGroupedBackground)
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }

    @ViewBuilder
    private func imageView(for imageType: ASCRoomTemplateUserMemberRowModel.ImageSourceType) -> some View {
        switch imageType {
        case let .url(string):
            if let portal = OnlyofficeApiClient.shared.baseURL?.absoluteString.trimmed,
               !string.contains(String.defaultUserPhotoSize),
               let url = URL(string: portal)?.appendingSafePath(string)
            {
                KFOnlyOfficeProviderImageView(url: url)
                    .resizable()
                    .frame(width: .imageWidth, height: .imageHeight)
                    .cornerRadius(.imageCornerRadius)
                    .clipped()
            } else {
                Image(asset: Asset.Images.avatarDefault)
                    .resizable()
                    .frame(width: .imageWidth, height: .imageHeight)
            }
        case let .asset(asset):
            Image(asset: asset)
                .resizable()
                .frame(width: .imageWidth, height: .imageHeight)
        }
    }
}

// MARK: - Navigation

private extension View {
    @ViewBuilder
    func navigateToChooseMembers(isActive: Binding<Bool>, viewModel: VDRStartFillingViewModel) -> some View {
        navigation(isActive: isActive, destination: {
            ASCStartFillingAssignToRoleView(
                viewModel: ASCStartFillingAssignToRoleViewModel(
                    room: viewModel.dataModel.room
                ) { user in
                    viewModel.addRoleUser(user)
                    viewModel.state.isChooseFromListScreenDisplaying = false
                }
            )
        })
    }

    @ViewBuilder
    func navigateToFillingStatus(isActive: Binding<Bool>, viewModel: VDRStartFillingViewModel) -> some View {
        navigation(isActive: isActive, destination: {
            VDRFillingStatusView(
                viewModel: VDRFillingStatusViewModel(
                    service: VDRFillingStatusService(
                        sharedService: NetworkManagerSharedSettings()
                    ),
                    isOpenAfterStartFilling: true,
                    file: viewModel.dataModel.form,
                    onStoppedSuccess: {}
                ),
                onFillTapped: viewModel.onFillTapped,
                onGoToRoomTapped: viewModel.onGoToRoomTapped
            )
        })
    }
}

extension View {
    @ViewBuilder
    func stackNavigationStyleForDevice() -> some View {
        if UIDevice.current.userInterfaceIdiom == .phone {
            navigationViewStyle(StackNavigationViewStyle())
        } else {
            self
        }
    }
}

private extension CGFloat {
    static let imageWidth: CGFloat = 40
    static let imageHeight: CGFloat = 40
    static let imageCornerRadius: CGFloat = 20
}

private extension View {
    @ViewBuilder
    func listRowSeparatorAvailable() -> some View {
        if #available(iOS 15.0, *) {
            self.listRowSeparator(.automatic, edges: .bottom)
        } else {
            self
        }
    }
}
