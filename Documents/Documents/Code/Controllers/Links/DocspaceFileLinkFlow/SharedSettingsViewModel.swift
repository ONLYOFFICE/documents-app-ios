//
//  SharedSettingsViewModel.swift
//  Documents-opensource
//
//  Created by Lolita Chernysheva on 01.06.2024.
//  Copyright © 2024 Ascensio System SIA. All rights reserved.
//

import Combine
import Foundation
import SwiftUI

final class SharedSettingsViewModel: ObservableObject {
    let file: ASCFile
    
    @Published var isShared: Bool

    init(file: ASCFile) {
        self.file = file
        self.isShared = file.shared
    }

    func createAndCopySharedLink() {}
}
