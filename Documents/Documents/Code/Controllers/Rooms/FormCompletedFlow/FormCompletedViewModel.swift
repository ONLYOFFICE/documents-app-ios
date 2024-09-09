//
//  FormCompletedViewModel.swift
//  Documents
//
//  Created by Lolita Chernysheva on 09.09.2024.
//  Copyright © 2024 Ascensio System SIA. All rights reserved.
//

import Combine
import Foundation

final class FormCompletedViewModel: ObservableObject {
    
    let form: ASCFile
    
    //MARK: - Published vars
    
    init(form: ASCFile) {
        self.form = form
    }
}

