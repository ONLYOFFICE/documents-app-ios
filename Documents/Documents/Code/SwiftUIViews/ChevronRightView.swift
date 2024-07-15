//
//  ChevronRightView.swift
//  Documents
//
//  Created by Pavel Chernyshev on 15.07.2024.
//  Copyright © 2024 Ascensio System SIA. All rights reserved.
//

import SwiftUI

struct ChevronRightView: View {
    
    var body: some View {
        Image(systemName: "chevron.right")
            .font(.subheadline)
            .foregroundColor(Color.separator)
            .flipsForRightToLeftLayoutDirection(true)
    }
}
