//
//  FullScreenLoader.swift
//  Documents
//
//  Created by Pavel Chernyshev on 7.05.2025.
//  Copyright © 2025 Ascensio System SIA. All rights reserved.
//

import SwiftUI

struct FullScreenLoader: View {
    
    var displayLabel = false
    
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .opacity(0.8)
                .ignoresSafeArea()

            if displayLabel {
                ProgressView("Loading…")
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(1.5)
            } else {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(1.5)
            }
        }
    }
}
