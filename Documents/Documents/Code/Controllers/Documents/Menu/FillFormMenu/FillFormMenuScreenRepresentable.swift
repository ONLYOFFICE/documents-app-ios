//
//  FillFormMenuScreenRepresentable.swift
//  Documents-opensource
//
//  Created by Pavel Chernyshev on 13.09.2024.
//  Copyright © 2024 Ascensio System SIA. All rights reserved.
//

import SwiftUI
import UIKit

struct FillFormMenuScreenRepresentable: UIViewControllerRepresentable {
    let onOpenTapped: () -> Void
    let onShareTapped: () -> Void

    func makeUIViewController(context: Context) -> UIHostingController<FillFormMenuScreen> {
        let hostingController = UIHostingController(
            rootView: FillFormMenuScreen(onOpenTapped: onOpenTapped, onShareTapped: onShareTapped)
        )
        return hostingController
    }

    func updateUIViewController(_ uiViewController: UIHostingController<FillFormMenuScreen>, context: Context) {}
}
