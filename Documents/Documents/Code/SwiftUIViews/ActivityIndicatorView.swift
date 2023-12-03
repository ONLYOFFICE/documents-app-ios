//
//  ActivityIndicatorView.swift
//  Documents-opensource
//
//  Created by Pavel Chernyshev on 03.12.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import Foundation
import SwiftUI

struct ActivityIndicatorView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIActivityIndicatorView {
        let activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.startAnimating()
        return activityIndicator
    }
    
    func updateUIView(_ uiView: UIActivityIndicatorView, context: Context) {}
}

struct ActivityIndicatorView_Preview: PreviewProvider {
    static var previews: some View {
        VStack {
            Text("Loading...")
            ActivityIndicatorView()
        }
    }
}
