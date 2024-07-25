//
//  ChevronUpDownView.swift
//  Documents
//
//  Created by Pavel Chernyshev on 20.05.2024.
//  Copyright © 2024 Ascensio System SIA. All rights reserved.
//

import Foundation

import SwiftUI

struct ChevronUpDownView: View {
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: "chevron.up")
                .resizable()
                .frame(width: 9, height: 5)
                .foregroundColor(.secondary)
            Image(systemName: "chevron.down")
                .resizable()
                .frame(width: 9, height: 5)
                .foregroundColor(.secondary)
        }
    }
}

struct ChevronUpDownView_Previews: PreviewProvider {
    static var previews: some View {
        ChevronUpDownView()
    }
}
