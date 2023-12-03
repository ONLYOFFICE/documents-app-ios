//
//  ASCDocSpaceLinkSettingsView.swift
//  Documents
//
//  Created by Lolita Chernysheva on 03.12.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import SwiftUI

//TODO: - if password assess isOn copy link -> copy link and password

struct ASCDocSpaceLinkSettingsView: View {
    @State private var isPasswordAccess = false //TODO: -
    @State private var isRestrictCopyOn = false //TODO: -
    @State private var isTimeLimitOn = false //TODO: -
    var body: some View {
        List {
            Section(header: Text(NSLocalizedString("General", comment: ""))) {
                Text(NSLocalizedString("Link name", comment: "")) //TODO: -
            }
            
            Section(header: Text(NSLocalizedString("Protection", comment: ""))) {
                HStack {
                    Toggle(isOn: $isPasswordAccess) { //TODO: -
                        Text(NSLocalizedString("Password access", comment: ""))
                    }
                }
            }
            
            Section(footer: Text(NSLocalizedString("Enable this setting to disable downloads of files and folders from this room shared via a link", comment: ""))) {
                Toggle(isOn: $isRestrictCopyOn) { //TODO: -
                    Text(NSLocalizedString("Restrict file content copy, file download and printing", comment: ""))
                }
            }
            
            Section(header: Text(NSLocalizedString("Time limit", comment: ""))) {
                Toggle(isOn: $isTimeLimitOn) {
                    Text(NSLocalizedString("Enable time limit", comment: ""))
                }
            }
            Section {
                ASCLabledCellView(textString: NSLocalizedString("Copy link", comment: ""), cellType: .standard, textAlignment: .center)
            }
            Section {
                ASCLabledCellView(textString: NSLocalizedString("Delete link", comment: ""), cellType: .deletable, textAlignment: .center)
            }
        }
    }
}

struct ASCDocSpaceLinkSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        ASCDocSpaceLinkSettingsView()
    }
}
