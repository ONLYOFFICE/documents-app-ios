//
//  NavigationLink+Extensions.swift
//  Documents-opensource
//
//  Created by Pavel Chernyshev on 20.11.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import Foundation
import SwiftUI

extension NavigationLink {

    init<T: Identifiable, D: View>(item: Binding<T?>,
                                   @ViewBuilder destination: (T) -> D,
                                   @ViewBuilder label: () -> Label) where Destination == D? {
        let isActive = Binding(
            get: { item.wrappedValue != nil },
            set: { value in
                if !value {
                    item.wrappedValue = nil
                }
            }
        )
        
        self.init(
            destination: item.wrappedValue.map(destination),
            isActive: isActive,
            label: label
        )
    }
}
