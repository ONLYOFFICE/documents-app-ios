//
//  EditSharedLinkView.swift
//  Documents
//
//  Created by Lolita Chernysheva on 03.12.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import MBProgressHUD
import SwiftUI

struct EditSharedLinkView: View {
    @Environment(\.presentationMode) var presentationMode

    @ObservedObject var viewModel: EditSharedLinkViewModel
    @State private var showDeleteAlert = false
    @State private var showRevokeAlert = false
    @State private var showPasswordErrorAlert = false

    @State private var passwordErrorAlertMessage = ""

    var body: some View {
        handleHUD()

        return content
            .navigationBarItems(rightBtn: doneButton.alert(isPresented: $showPasswordErrorAlert) { passwordErrorAlert })
            .disabledIfDeleting(viewModel.screenModel.isDeleting)
            .alertForErrorMessage($viewModel.errorMessage)
            .dismissOnChange(of: viewModel.screenModel.isReadyToDismissed, using: presentationMode)
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
            linkNameSection
            generalSection
            protectedSection
            restrictionSection
            deleteSection
            revokeSection
                .alert(isPresented: $showRevokeAlert, content: revokeAlert)
        }
        .navigationBarTitle(Text("Edit link"))
    }

    var additionalLinkView: some View {
        List {
            linkNameSection
            generalSection
            protectedSection
            restrictionSection
            deleteSection
                .alert(isPresented: $showDeleteAlert, content: deleteAlert)
        }
        .navigationBarTitle(Text("Edit link"))
    }

    private var linkNameSection: some View {
        Section(header: Text("Link name")) {
            TextField("Link name", text: $viewModel.linkModel.linkName)
        }
    }

    private var generalSection: some View {
        Section(
            header: Text("General")
        ) {
            accessCell
            if viewModel.showTimeLimit {
                timeLimitCell
                    .disabled(viewModel.linkModel.isExpired)
            }
        }
    }

    private var protectedSection: some View {
        Section(header: Text("Protection"), footer: protectionSectionFooter) {
            Toggle(isOn: $viewModel.linkModel.isProtected.animation()) {
                Text("Password access")
            }
            .tintColor(Color(Asset.Colors.brend.color))
            .foregroundColor(.primary)

            if viewModel.linkModel.isProtected {
                PasswordCellView(
                    model: PasswordCellModel(
                        password: $viewModel.linkModel.password,
                        isPasswordVisible: $viewModel.screenModel.isPasswordVisible
                    )
                )
                .foregroundColor(.primary)
            }
        }
    }

    private var protectionSectionFooter: some View {
        Text(verbatim: String.protectionSectionFooterText)
    }

    @ViewBuilder
    private var timeLimitCell: some View {
        Toggle(isOn: $viewModel.linkModel.isTimeLimited.animation()) {
            Text("Enable time limit")
        }
        .tintColor(Color(Asset.Colors.brend.color))

        if viewModel.linkModel.isTimeLimited {
            TimeLimitCellView(model: TimeLimitCellModel(
                selectedDate: $viewModel.linkModel.selectedDate,
                title: NSLocalizedString("Valid through", comment: ""),
                displayedComponents: [.date, .hourAndMinute]
            ))
        }
    }

    @ViewBuilder
    private var restrictionSection: some View {
        if viewModel.roomType != .fillingForm {
            Section(footer: Text(verbatim: String.restrictionSectionFooterText)) {
                Toggle(isOn: $viewModel.linkModel.isRestrictCopyOn) {
                    Text("Restrict file content copy, file download and printing")
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
    private var accessCell: some View {
        if viewModel.isEditAccessPossible {
            MenuView(menuItems: viewModel.accessMenuItems) {
                ASCDetailedImageChevronUpDownCellView(model: ASCDetailedImageChevronUpDownCellViewModel(
                    title: NSLocalizedString("Access rights", comment: ""),
                    subtitle: viewModel.linkModel.selectedAccessRight.title(),
                    isEnabled: !viewModel.linkModel.isExpired
                ))
            }
        }
    }

    @ViewBuilder
    private var doneButton: some View {
        Button(
            NSLocalizedString("Done", comment: ""),
            action: {
                Task { @MainActor in
                    if let errorMessage = await viewModel.onSave() {
                        showErrorAlert(message: errorMessage)
                    }
                }
            }
        )
        .disabled(!viewModel.isPossibleToSave)
    }

    private func showErrorAlert(message: String) {
        passwordErrorAlertMessage = message
        showPasswordErrorAlert = true
    }

    private func handleHUD() {
        MBProgressHUD.currentHUD?.hide(animated: false)

        if viewModel.screenModel.isSaving || viewModel.screenModel.isDeleting || viewModel.screenModel.isRevoking {
            let hud = MBProgressHUD.showTopMost()
            hud?.mode = .indeterminate
            if viewModel.screenModel.isDeleting {
                hud?.label.text = NSLocalizedString("Removing", comment: "") + "..."
            } else if viewModel.screenModel.isSaving {
                hud?.label.text = NSLocalizedString("Saving", comment: "") + "..."
            } else if viewModel.screenModel.isRevoking {
                hud?.label.text = NSLocalizedString("Revoking", comment: "") + "..."
            }
        } else if let resultModalModel = viewModel.resultModalModel,
                  let hud = MBProgressHUD.showTopMost()
        {
            switch resultModalModel.result {
            case .success:
                if viewModel.screenModel.isDeleted {
                    hud.setState(result: .success(NSLocalizedString("Deleted", comment: "")))
                } else if viewModel.screenModel.isSaved {
                    hud.setState(result: .success(resultModalModel.message))
                } else if viewModel.screenModel.isRevoked {
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
            title: Text("Delete link"),
            message: Text(verbatim: String.deleteAlertMessage),
            primaryButton: .destructive(Text("Delete"), action: {
                Task { @MainActor in
                    await viewModel.onDelete()
                }
            }),
            secondaryButton: .cancel()
        )
    }

    private func revokeAlert() -> Alert {
        Alert(
            title: Text("Revoke link"),
            message: Text(verbatim: String.revokeAlertMessage),
            primaryButton: .destructive(Text("Revoke link"), action: {
                Task { @MainActor in
                    await viewModel.onRevoke()
                }
            }),
            secondaryButton: .cancel()
        )
    }

    private var passwordErrorAlert: Alert {
        Alert(
            title: Text("Error"),
            message: Text(verbatim: passwordErrorAlertMessage),
            dismissButton: .default(Text("OK"))
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
    EditSharedLinkView(
        viewModel: .init(
            room: .init(),
            inputLink: nil,
            outputLink: .constant(nil)
        )
    )
}

private extension String {
    static let protectionSectionFooterText = NSLocalizedString("Minimum length: 8 | Allowed characters: a-z, A-Z, 0-9, !\"#%&'()*+,-./:;<=>?@[]^_`{|}", comment: "")
    static let restrictionSectionFooterText = NSLocalizedString("Enable this setting to disable downloads of files and folders from this room shared via a link", comment: "")
    static let deleteAlertMessage = NSLocalizedString("Links to all files in the room will be deleted. Previous links to room files and embedded documents will become unavailable.\n \nThis action cannot be undone. Are you sure you want to continue?", comment: "")
    static let revokeAlertMessage = NSLocalizedString("Links to all files in the room will be re-generated. Previous links to room files and embedded documents will become unavailable.\n \nThis action cannot be undone. Are you sure you want to continue?", comment: "")
}
