//
//  ResultModalView.swift
//  Documents-opensource
//
//  Created by Pavel Chernyshev on 03/01/24.
//  Copyright © 2024 Ascensio System SIA. All rights reserved.
//

import Foundation
import SwiftUI

struct ResultModalView: View {
    @Binding var model: Model?

    var body: some View {
        GeometryReader { geometry in
            if let resultModel = model {
                VStack {
                    Image(systemName: resultModel.result == .success ? "checkmark" : "xmark")
                        .foregroundColor(.gray)
                        .font(.largeTitle)
                    Text(resultModel.message)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .frame(maxWidth: geometry.size.width / 2)
                .background(Color(.systemGray6))
                .cornerRadius(4)
                .transition(.identity)
                .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + (model?.hideAfter ?? 5)) {
                        withAnimation {
                            self.model = nil
                        }
                    }
                }
            }
        }
    }
}

extension ResultModalView {
    struct Model {
        enum Result {
            case success, failure
        }

        var result: Result
        var message: String
        var hideAfter: TimeInterval = 2.5
    }
}
