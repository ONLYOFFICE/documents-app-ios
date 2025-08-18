//
//  VDRStartFillingView.swift
//  Documents
//
//  Created by Pavel Chernyshev on 25.04.2025.
//  Copyright © 2025 Ascensio System SIA. All rights reserved.
//

import SwiftUI

// MARK: - Under construction. Docspace 3.2 or later

struct VDRStartFillingView: View {
    @ObservedObject var viewModel: VDRStartFillingViewModel

    let onDismiss: (Result<Bool, any Error>) -> Void

    var body: some View {
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
                            .fullWidthSeparators()
                        }
                        .onDelete { indexSet in
                            indexSet.map { viewModel.state.roles[$0] }
                                .forEach(viewModel.deleteRole)
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
                Button(NSLocalizedString("Cancel", comment: ""), action: viewModel.closeTapped)
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
                    .font(.body)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 4)
                    .background(
                        viewModel.state.isStartEnabled
                            ? Color(Asset.Colors.documentEditor.color)
                            : Color.secondary.opacity(0.16)
                    )
                    .cornerRadius(16)
            }
            .disabled(!viewModel.state.isStartEnabled)
            .padding(.top, 16)
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

            Circle()
                .fill(role.color)
                .frame(width: 40, height: 40)
                .overlay(Image(systemName: "plus").foregroundColor(.secondary))

            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: role.title)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                Text("Role description")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 12)
        .padding(.horizontal)
        .background(Color.white)
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }
}

extension View {
    func fullWidthSeparators() -> some View {
        if #available(iOS 15, *) {
            return self
                .listRowSeparator(.visible, edges: .bottom)
                .listRowInsets(EdgeInsets())
        } else {
            return self
        }
    }
}
