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

struct VDRStartFillingView: View {
    @Environment(\.presentationMode) var presentationMode

    @ObservedObject var viewModel: VDRStartFillingViewModel

    let onDismiss: (Result<Bool, any Error>) -> Void

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
                }

                footer
            }
            .navigateToChooseMembers(isActive: $viewModel.state.isChooseFromListScreenDisplaying, viewModel: viewModel)
        }
        .onChange(of: viewModel.state.finishWithSuccess) {
            onDismiss(.success($0))
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
            onDismiss(.success(false))
        }
    }

    // MARK: — Header

    private var header: some View {
        ZStack {
            HStack {
                Button(NSLocalizedString("Cancel", comment: ""), action: { presentationMode.wrappedValue.dismiss() })
                    .foregroundColor(.blue)

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
        .background(Color.white)
    }

    // MARK: — Footer

    private var footer: some View {
        HStack {
            Spacer()
            Button(action: viewModel.startTapped) {
                Text("Start")
                    .brandButton(.filledCapsule, isEnabled: viewModel.state.isStartEnabled)
            }
            .disabled(!viewModel.state.isStartEnabled)
            .padding(.vertical, 16)
            .padding(.horizontal)
        }
        .background(Color.white.ignoresSafeArea(edges: .bottom))
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
        .padding(.vertical, 12)
        .padding(.horizontal)
        .background(Color.white)
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }

    @ViewBuilder
    private func imageView(for imageType: ASCRoomTemplateUserMemberRowModel.ImageSourceType) -> some View {
        switch imageType {
        case let .url(string):
            if let portal = OnlyofficeApiClient.shared.baseURL?.absoluteString.trimmed,
               !string.contains(String.defaultUserPhotoSize),
               let url = URL(string: portal + string)
            {
                KFImage(url)
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
}

private extension CGFloat {
    static let imageWidth: CGFloat = 40
    static let imageHeight: CGFloat = 40
    static let imageCornerRadius: CGFloat = 20
}
