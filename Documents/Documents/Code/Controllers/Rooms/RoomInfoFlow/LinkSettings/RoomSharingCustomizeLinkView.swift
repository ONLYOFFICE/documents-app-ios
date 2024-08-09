//
//  RoomSharingCustomizeLinkView.swift
//  Documents
//
//  Created by Lolita Chernysheva on 03.12.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import MBProgressHUD
import SwiftUI

struct RoomSharingCustomizeLinkView: View {
    @Environment(\.presentationMode) var presentationMode

    @ObservedObject var viewModel: RoomSharingCustomizeLinkViewModel
    @State private var showDeleteAlert = false
    @State private var showRevokeAlert = false

    var body: some View {
        handleHUD()

        return content
            .navigationBarItems(rightBtn: doneButton)
            .disabledIfDeleting(viewModel.isDeleting)
            .alertForErrorMessage($viewModel.errorMessage)
            .dismissOnChange(of: viewModel.isReadyToDismissed, using: presentationMode)
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.contentState {
        case .general:
            generalLinkView
        case .additional:
            additionalLinkView
        }
    }

    var generalLinkView: some View {
        List {
            generalSection
            protectedSection
            restrictionSection
            deleteSection
            revokeSection
                .alert(isPresented: $showRevokeAlert, content: revokeAlert)
        }
        .navigationBarTitle(Text(NSLocalizedString("General link", comment: "")))
    }

    var additionalLinkView: some View {
        List {
            generalSection
            protectedSection
            restrictionSection
            timeLimitSection
            deleteSection
                .alert(isPresented: $showDeleteAlert, content: deleteAlert)
        }
        .navigationBarTitle(Text(NSLocalizedString("Additional links", comment: "")))
    }

    private var generalSection: some View {
        Section(header: Text(NSLocalizedString("General", comment: ""))) {
            TextField("Link name", text: $viewModel.linkName)
        }
    }

    private var protectedSection: some View {
        Section(header: Text(NSLocalizedString("Protection", comment: ""))) {
            Toggle(isOn: $viewModel.isProtected.animation()) {
                Text(NSLocalizedString("Password access", comment: ""))
            }
            .tintColor(Color(Asset.Colors.brend.color))
            .foregroundColor(.primary)

            if viewModel.isProtected {
                PasswordCellView(
                    model: PasswordCellModel(
                        password: $viewModel.password,
                        isPasswordVisible: $viewModel.isPasswordVisible
                    )
                )
                .foregroundColor(.primary)
            }
        }
    }

    private var timeLimitSection: some View {
        Section(
            header: Text(NSLocalizedString("Time limit", comment: "")),
            footer: viewModel.isExpired
                ? Text(NSLocalizedString("The link has expired and has been disabled", comment: ""))
                .foregroundColor(.red)
                : nil
        ) {
            Toggle(isOn: $viewModel.isTimeLimited.animation()) {
                Text(NSLocalizedString("Enable time limit", comment: ""))
            }
            .tintColor(Color(Asset.Colors.brend.color))

            if viewModel.isTimeLimited {
                TimeLimitCellView(model: TimeLimitCellModel(
                    selectedDate: $viewModel.selectedDate,
                    title: NSLocalizedString("Valid through", comment: ""),
                    displayedComponents: [.date, .hourAndMinute]
                ))
            }
        }
    }

    @ViewBuilder
    private var restrictionSection: some View {
        if viewModel.roomType != .fillingForm {
            Section(footer: Text(NSLocalizedString("Enable this setting to disable downloads of files and folders from this room shared via a link", comment: ""))) {
                Toggle(isOn: $viewModel.isRestrictCopyOn) {
                    Text(NSLocalizedString("Restrict file content copy, file download and printing", comment: ""))
                }
                .tintColor(Color(Asset.Colors.brend.color))
            }
        }
    }

    @ViewBuilder
    private var deleteSection: some View {
        if viewModel.isDeletePossible {
            Section {
                ASCLabledCellView(
                    model: ASCLabledCellModel(
                        textString: NSLocalizedString("Delete link", comment: ""),
                        cellType: .deletable,
                        textAlignment: .center,
                        onTapAction: {
                            showDeleteAlert = true
                        }
                    )
                )
            }
        }
    }

    @ViewBuilder
    private var revokeSection: some View {
        if viewModel.isRevokePossible {
            Section {
                ASCLabledCellView(
                    model: ASCLabledCellModel(
                        textString: NSLocalizedString("Revoke link", comment: ""),
                        cellType: .deletable,
                        textAlignment: .center,
                        onTapAction: {
                            showRevokeAlert = true
                        }
                    )
                )
            }
        }
    }

    @ViewBuilder
    private var doneButton: some View {
        Button(
            NSLocalizedString("Done", comment: ""),
            action: {
                viewModel.onSave()
            }
        )
        .disabled(!viewModel.isPossibleToSave)
    }

    private func handleHUD() {
        MBProgressHUD.currentHUD?.hide(animated: false)

        if viewModel.isSaving || viewModel.isDeleting || viewModel.isRevoking {
            let hud = MBProgressHUD.showTopMost()
            hud?.mode = .indeterminate
            if viewModel.isDeleting {
                hud?.label.text = NSLocalizedString("Removing", comment: "") + "..."
            } else if viewModel.isSaving {
                hud?.label.text = NSLocalizedString("Saving", comment: "") + "..."
            } else if viewModel.isRevoking {
                hud?.label.text = NSLocalizedString("Revoking", comment: "") + "..."
            }
        } else if let resultModalModel = viewModel.resultModalModel,
                  let hud = MBProgressHUD.showTopMost()
        {
            switch resultModalModel.result {
            case .success:
                if viewModel.isDeleted {
                    hud.setState(result: .success(NSLocalizedString("Deleted", comment: "")))
                } else if viewModel.isSaved {
                    hud.setState(result: .success(resultModalModel.message))
                } else if viewModel.isRevoked {
                    hud.setState(result: .success(NSLocalizedString("Revoked", comment: "")))
                }
            case .failure:
                hud.setState(result: .failure(resultModalModel.message))
            }
            hud.hide(animated: true, afterDelay: resultModalModel.hideAfter)
        }
    }

    private func deleteAlert() -> Alert {
        Alert(
            title: Text(NSLocalizedString("Delete link", comment: "")),
            message: Text(NSLocalizedString("The link will be deleted permanently. You will not be able to undo this action.", comment: "")),
            primaryButton: .destructive(Text(NSLocalizedString("Delete", comment: "")), action: {
                viewModel.onDelete()
            }),
            secondaryButton: .cancel()
        )
    }

    private func revokeAlert() -> Alert {
        Alert(
            title: Text(NSLocalizedString("Revoke link", comment: "")),
            message: Text(NSLocalizedString("The previous link will become unavailable. A new shared link will be created.", comment: "")),
            primaryButton: .destructive(Text(NSLocalizedString("Revoke link", comment: "")), action: {
                viewModel.onRevoke()
            }),
            secondaryButton: .cancel()
        )
    }
}

// MARK: Modifiers

private extension View {
    func navigationBarItems(rightBtn: some View) -> some View {
        navigationBarItems(trailing: rightBtn)
    }

    func disabledIfDeleting(_ isDeleting: Bool) -> some View {
        disabled(isDeleting)
    }

    func dismissOnChange(of value: Bool, using presentationMode: Binding<PresentationMode>) -> some View {
        onChange(of: value) { newValue in
            if newValue {
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
}

#Preview {
    RoomSharingCustomizeLinkView(
        viewModel: .init(
            room: .init(),
            inputLink: nil,
            outputLink: .constant(nil)
        )
    )
}
