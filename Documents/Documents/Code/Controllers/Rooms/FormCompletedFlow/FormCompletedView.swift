//
//  FormCompletedView.swift
//  Documents
//
//  Created by Lolita Chernysheva on 09.09.2024.
//  Copyright © 2024 Ascensio System SIA. All rights reserved.
//

import SwiftUI
import MessageUI

struct FormCompletedView: View {
    
    @ObservedObject var viewModel: FormCompletedViewModel
    @Environment(\.presentationMode) var presentationMode
    
    @State private var isShowingMailView = false
    @State private var mailData = ComposeMailData(
        subject: "",
        recipients: [""],
        messageBody: "",
        isHtml: false
    )
    
    var body: some View {
        NavigationView {
            VStack {
                screenHeader
                List {
                    formSection
                    formNumberSection
                    ownerSection
                }
            }
            .background(Color.systemGroupedBackground)
            .ignoresSafeArea(edges: .top)
            .toolbar {
                ToolbarItemGroup(placement: .bottomBar) {
                    VStack(spacing: 0) {
                        
                        Divider()
                            .background(Color.gray)
                            .frame(height: Constants.deviderHeight)
                        HStack {
                            Button(action: {
                                presentationMode.wrappedValue.dismiss()
                            }) {
                                Text(TextConstants.backToRoom)
                            }
                            .foregroundColor(.blue)
                            Spacer()
                            Button(action: {
                                presentationMode.wrappedValue.dismiss()
                            }) {
                                Text(TextConstants.checkReadyForm)
                                    .font(.headline)
                            }
                            .background(Color.blue)
                            .foregroundColor(Color.white)
                            .cornerRadius(Constants.toolbarButtonCornerRadius)
                        }
                        .padding()
                    }
                    .padding(.horizontal, Constants.toolbarHorizontalPadding)
                }
            }
        }
        .onAppear {
            self.mailData = ComposeMailData(
                subject: viewModel.formModel.form.title,
                recipients: [viewModel.formModel.authorEmail],
                messageBody: "",
                isHtml: false
            )
        }
    }
    
    @ViewBuilder
    private var screenHeader: some View {
        VStack(spacing: Constants.screenHedaerInsets) {
            Asset.Images.checkmarkGreenCircle.swiftUIImage
            Text(TextConstants.formCompletedSuccessfully)
                .font(.title2)
                .foregroundColor(.primary)
            Text(TextConstants.formSaved)
                .font(.subheadline)
                .foregroundColor(.secondaryLabel)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, Constants.screenHeaderHorizontalPadding)
        .padding(.top, UIApplication.shared.windows.first?.safeAreaInsets.top ?? Constants.screenHeaderDefaultTopInsets)
    }
    
    @ViewBuilder
    private var formSection: some View {
        Section {
            ASCFormCellView(model: ASCFormCellModel(
                title: viewModel.formModel.form.title,
                author: viewModel.formModel.authorName,
                date: viewModel.formModel.form.created?.string() ?? "",
                onLinkAction: {
                    viewModel.onCopyLink()
                })
            )
        }
    }
    
    @ViewBuilder
    private var formNumberSection: some View {
        Section {
            HStack {
                Text(TextConstants.formNumber)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                Spacer()
                Text("\(viewModel.formModel.formNumber)")
                    .font(.body)
                    .foregroundColor(.secondaryLabel)
            }
        }
    }
    
    @ViewBuilder
    private var ownerSection: some View {
        Section(header: Text(TextConstants.formOwner)) {
            ASCUserWithEmailRowView(
                model: ASCUserWithEmailRowViewModel(
                    image: .uiImage(
                        UIImage(base64String: viewModel.formModel.authorAvatar)
                        ?? UIImage(asset: Asset.Images.avatarDefault)
                        ?? UIImage()
                    ),
                    userName: viewModel.formModel.authorName,
                    email: viewModel.formModel.authorEmail,
                    onEmailAction: {
                        self.isShowingMailView = true
                    }
                )
            )
        }
        .sheet(isPresented: $isShowingMailView) {
            CompleteFormMailView(data: $mailData) { result in
                print(result)
            }
        }
    }
}

fileprivate struct Constants {
    static let toolbarButtonCornerRadius: CGFloat = 14.0
    static let screenHedaerInsets: CGFloat = 16.0
    static let screenHeaderHorizontalPadding: CGFloat = 18.0
    static let screenHeaderDefaultTopInsets: CGFloat = 16.0
    static let deviderHeight: CGFloat = 1.0
    static let toolbarHorizontalPadding: CGFloat = -16.0
}

fileprivate struct TextConstants {
    static let formCompletedSuccessfully: String = NSLocalizedString("Form completed successfully", comment: "")
    static let formSaved: String = NSLocalizedString("The filled PDF form is saved and available to you\n in the Complete folder. To check the status,\n contact the form owner providing the assigned number.", comment: "")
    static let backToRoom: String = NSLocalizedString("Back to room", comment: "")
    static let checkReadyForm: String = NSLocalizedString("Check ready form", comment: "")
    static let formNumber: String = NSLocalizedString("Form number", comment: "")
    static let formOwner: String = NSLocalizedString("Form owner", comment: "")
}

private extension UIImage {
    convenience init?(base64String: String) {
        guard let data = Data(base64Encoded: base64String.replacingOccurrences(of: "data:image/png;base64,", with: "")),
              let _ = UIImage(data: data) else {
            return nil
        }
        self.init(data: data)
    }
}
