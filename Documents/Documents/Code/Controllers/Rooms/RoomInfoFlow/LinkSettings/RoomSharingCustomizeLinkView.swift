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
    @State private var showPasswordErrorAlert = false

    @State private var passwordErrorAlertMessage = ""

    var body: some View {
        handleHUD()

        return content
            .navigationBarItems(rightBtn: doneButton.alert(isPresented: $showPasswordErrorAlert) { passwordErrorAlert })
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
            linkNameSection
            generalSection
            protectedSection
            restrictionSection
            deleteSection
            revokeSection
                .alert(isPresented: $showRevokeAlert, content: revokeAlert)
        }
        .navigationBarTitle(Text(NSLocalizedString("Edit link", comment: "")))
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
        .navigationBarTitle(Text(NSLocalizedString("Edit link", comment: "")))
    }

    private var linkNameSection: some View {
        Section(header: Text(NSLocalizedString("Link name", comment: ""))) {
            TextField("Link name", text: $viewModel.linkName)
        }
    }

    private var generalSection: some View {
        Section(
            header: Text(NSLocalizedString("General", comment: "")))
        {
            accessCell
            timeLimitCell
                .disabled(viewModel.isExpired)
        }
    }

    private var protectedSection: some View {
        Section(header: Text(NSLocalizedString("Protection", comment: "")), footer: protectionSectionFooter) {
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

    private var protectionSectionFooter: some View {
        Text(String.protectionSectionFooterText)
    }

    @ViewBuilder
    private var timeLimitCell: some View {
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

    @ViewBuilder
    private var restrictionSection: some View {
        if viewModel.roomType != .fillingForm {
            Section(footer: Text(String.restrictionSectionFooterText)) {
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

    private var accessCell: some View {
        MenuView(menuItems: viewModel.accessMenuItems) {
            ASCDetailedImageChevronUpDownCellView(model: ASCDetailedImageChevronUpDownCellViewModel(
                title: NSLocalizedString("Access rights", comment: ""),
                image: viewModel.selectedAccessRight.swiftUIImage ?? Image(""),
                isEnabled: !viewModel.isExpired
            ))
        }
    }

    @ViewBuilder
    private var doneButton: some View {
        Button(
            NSLocalizedString("Done", comment: ""),
            action: {
                viewModel.onSave { errorMessage in
                    if let errorMessage = errorMessage {
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
            message: Text(String.deleteAlertMessage),
            primaryButton: .destructive(Text(NSLocalizedString("Delete", comment: "")), action: {
                viewModel.onDelete()
            }),
            secondaryButton: .cancel()
        )
    }

    private func revokeAlert() -> Alert {
        Alert(
            title: Text(NSLocalizedString("Revoke link", comment: "")),
            message: Text(String.revokeAlertMessage),
            primaryButton: .destructive(Text(NSLocalizedString("Revoke link", comment: "")), action: {
                viewModel.onRevoke()
            }),
            secondaryButton: .cancel()
        )
    }

    private var passwordErrorAlert: Alert {
        Alert(
            title: Text(NSLocalizedString("Error", comment: "")),
            message: Text(passwordErrorAlertMessage),
            dismissButton: .default(Text(NSLocalizedString("OK", comment: "")))
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

private extension String {
    static let protectionSectionFooterText = NSLocalizedString("Minimum length: 8 | Allowed characters: a-z, A-Z, 0-9, !\"#%&'()*+,-./:;<=>?@[]^_`{|}", comment: "")
    static let restrictionSectionFooterText = NSLocalizedString("Enable this setting to disable downloads of files and folders from this room shared via a link", comment: "")
    static let deleteAlertMessage = NSLocalizedString("Links to all files in the room will be deleted. Previous links to room files and embedded documents will become unavailable.\n \nThis action cannot be undone. Are you sure you want to continue?", comment: "")
    static let revokeAlertMessage = NSLocalizedString("Links to all files in the room will be re-generated. Previous links to room files and embedded documents will become unavailable.\n \nThis action cannot be undone. Are you sure you want to continue?", comment: "")
}
