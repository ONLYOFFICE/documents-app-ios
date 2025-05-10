//
//  FullScreenLoader.swift
//  Documents-opensource
//
//  Created by Pavel Chernyshev on 7.05.2025.
//  Copyright © 2025 Ascensio System SIA. All rights reserved.
//

import SwiftUI

struct CardStyle: ViewModifier {
    var cornerRadius: CGFloat = 16
    var background: Color = .white
    func body(content: Content) -> some View {
        content
            .background(background)
            .cornerRadius(cornerRadius)
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}
