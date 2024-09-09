//
//  FormCompletedView.swift
//  Documents
//
//  Created by Lolita Chernysheva on 09.09.2024.
//  Copyright © 2024 Ascensio System SIA. All rights reserved.
//

import SwiftUI

struct FormCompletedView: View {
    
    @ObservedObject var viewModel: FormCompletedViewModel
    
    var body: some View {
        VStack {
            screenHeader
            List {
                formSection
                formNumberSection
                ownerSection
            }
        }
        .background(Color.systemGroupedBackground)
        .ignoresSafeArea()
    }
    
    @ViewBuilder
    private var screenHeader: some View {
        VStack(spacing: 16) {
            Asset.Images.checkmarkGreenCircle.swiftUIImage
            Text(NSLocalizedString("Form completed successfully", comment: ""))
                .font(.title2)
                .foregroundColor(.primary)
            Text(NSLocalizedString("The filled PDF form is saved and available to you\n in the Complete folder. To check the status,\n contact the form owner providing the assigned number.", comment: ""))
                .font(.subheadline)
                .foregroundColor(.secondaryLabel)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal,18)
        .padding(.top, UIApplication.shared.windows.first?.safeAreaInsets.top ?? 16)
    }
    
    @ViewBuilder
    private var formSection: some View {
        Section {
            ASCFormCellView(model: ASCFormCellModel(title: "1 - Terry Dorwart - 2021", author: "Terry Dorwart", date: "04.06.2021")) //TODO: - from viewModel.form
        }
    }
    
    @ViewBuilder
    private var formNumberSection: some View {
        Section {
            HStack {
                Text(NSLocalizedString("Form number", comment: ""))
                    .font(.subheadline)
                    .foregroundColor(.primary)
                Spacer()
                Text("1") //TODO: -
                    .font(.body)
                    .foregroundColor(.secondaryLabel)
            }
        }
    }
    
    @ViewBuilder
    private var ownerSection: some View {
        Section(header: Text(NSLocalizedString("Form owner", comment: ""))) {
            ASCUserWithEmailRowView(model: ASCUserWithEmailRowViewModel(image: .url(""), userName: "Dmitry Go", email: "name.surename@gmail.com", onEmailAction: {
                //TODO: - email action
                print("===== show email screen")
            }))
        }
    }
}

struct FormCompletedView_Previews: PreviewProvider {
    static var previews: some View {
        FormCompletedView(viewModel: FormCompletedViewModel(form: ASCFile()))
    }
}


