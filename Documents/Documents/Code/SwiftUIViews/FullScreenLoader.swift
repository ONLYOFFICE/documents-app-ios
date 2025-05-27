//
//  FullScreenLoader.swift
//  Documents
//
//  Created by Pavel Chernyshev on 7.05.2025.
//  Copyright © 2025 Ascensio System SIA. All rights reserved.
//

import SwiftUI

struct FullScreenLoader: View {
    var body: some View {
        ZStack {
            Color.white.opacity(0.8).ignoresSafeArea()
            ProgressView("Loading…")
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(1.5)
        }
    }
}
