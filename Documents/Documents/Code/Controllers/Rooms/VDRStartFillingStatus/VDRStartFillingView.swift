//
//  VDRStartFillingView.swift
//  Documents
//
//  Created by Pavel Chernyshev on 25.04.2025.
//  Copyright © 2025 Ascensio System SIA. All rights reserved.
//

import SwiftUI

struct VDRStartFillingView: View {
    @ObservedObject var viewModel: VDRStartFillingViewModel

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("In this panel you can monitor the completion\nof the form in which you participate or in which you\nare the organizer of completion")
                        .font(.footnote)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal)

                    Text("Roles from the form:")
                        .font(.headline)
                        .padding(.horizontal)

                    VStack(spacing: 0) {
                        ForEach(viewModel.roles) { role in
                            RoleRow(role: role) {
                                viewModel.roleTapped(role)
                            }
                            Divider()
                        }
                    }
                    .background(Color.white)
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                .padding(.top, 16)
            }

            footer
        }
        .background(Color(UIColor.systemGray6).ignoresSafeArea())
    }

    private var header: some View {
        HStack {
            Button("Close", action: viewModel.closeTapped)
                .foregroundColor(.blue)

            Spacer()

            Text("Start filling")
                .font(.headline)

            Spacer()

            Spacer().frame(width: 44)
        }
        .padding()
        .background(Color.white)
    }

    private var footer: some View {
        HStack {
            Spacer()
            Button(action: viewModel.startTapped) {
                Text("Start")
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(Color.gray.opacity(0.4))
                    .cornerRadius(16)
            }
            .padding()
        }
        .background(Color.white)
    }
}

struct RoleRow: View {
    typealias RoleItem = VDRStartFillingRoleItem
    
    let role: RoleItem
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Text("\(role.number)")
                    .font(.body)
                    .frame(width: 20, alignment: .leading)

                Circle()
                    .fill(role.color)
                    .frame(width: 30, height: 30)
                    .overlay(Image(systemName: "plus").foregroundColor(.black))

                Text(role.title)
                    .foregroundColor(.primary)

                Spacer()
            }
            .padding(.vertical, 12)
            .padding(.horizontal)
        }
    }
}
