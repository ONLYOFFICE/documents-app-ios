//
//  ASCViewModelSetter.swift
//  Documents
//
//  Created by Павел Чернышев on 15.06.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import Foundation

protocol ASCViewModelSetter {
    associatedtype ViewModel
    
    var viewModel: ViewModel? { get set }
}
