//
//  ASCDocSpaceExternalLinkView.swift
//  Documents
//
//  Created by Lolita Chernysheva on 28.11.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import SwiftUI

// MARK: - TODO ckeck mark, single chosing

struct ASCDocSpaceExternalLinkView: View {
    @State private var selectedDate: Date = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()

    var body: some View {
        VStack {
            List {
                Section(header: Text(NSLocalizedString("General", comment: ""))) {
                    HStack {
                        Text(NSLocalizedString("Acces rights", comment: ""))
                        Spacer()
                        Image(systemName: "eye.fill")
                            .foregroundColor(Asset.Colors.grayLight.swiftUIColor)
                        Button(action: {
                            // MARK: - TODO add action
                        }) {
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                    }

                    HStack {
                        Text(NSLocalizedString("Link life time", comment: ""))
                        Spacer()

                        Text(NSLocalizedString("Custom", comment: "")) // MARK: - TODO

                            .foregroundColor(Asset.Colors.grayLight.swiftUIColor) // MARK: - TODO

                        Button(action: {
                            // MARK: - TODO add action
                        }) {
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                    }
                }

                Section(header: Text(NSLocalizedString("Time limit", comment: ""))) {
                    HStack {
                        DatePicker(
                            NSLocalizedString("Valid through", comment: ""),
                            selection: $selectedDate,
                            in: Date()...,
                            displayedComponents: .date
                        )
                        .datePickerStyle(.automatic)

                        // MARK: TODO date picker
                    }
                }

                Section(header: Text(NSLocalizedString("Type", comment: ""))) {
                    Text(NSLocalizedString("Anyone with the link", comment: ""))
                    Text(NSLocalizedString("DocSpace users only", comment: ""))
                }

                Section {
                    ASCLabledCellView(textString: NSLocalizedString("Copy link", comment: ""), cellType: .standard, textAlignment: .center)
                }

                Section {
                    ASCLabledCellView(textString: NSLocalizedString("Delete link", comment: ""), cellType: .deletable, textAlignment: .center)
                }
            }
        }
        .navigationBarTitle(Text(NSLocalizedString("External link", comment: "")), displayMode: .inline)
        .navigationBarItems(leading: Button(action: {
            // MARK: - TODO add back btn action
        }, label: {
            Text(NSLocalizedString("Back", comment: ""))
                .foregroundColor(Asset.Colors.brend.swiftUIColor)
        }))
        .navigationBarItems(trailing: Button(action: {
            // MARK: - TODO add share btn action
        }, label: {
            Text(NSLocalizedString("Share", comment: ""))
                .foregroundColor(Asset.Colors.brend.swiftUIColor)
        }))
    }
}

struct ASCDocSpaceExternalLinkView_Previews: PreviewProvider {
    static var previews: some View {
        ASCDocSpaceExternalLinkView()
    }
}
