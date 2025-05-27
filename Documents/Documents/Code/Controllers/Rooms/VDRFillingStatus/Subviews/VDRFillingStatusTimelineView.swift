//
//  VDRFillingStatusTimelineView.swift
//  Documents
//
//  Created by Pavel Chernyshev on 10.05.2025.
//  Copyright © 2025 Ascensio System SIA. All rights reserved.
//

import SwiftUI

struct VDRFillingStatusTimelineViewModel {
    let formFillingStatus: FormFillingStatus
}

/// Timeline view showing list of events
struct VDRFillingStatusTimelineView: View {
    let rowViewModels: [VDRFillingStatusEventRowViewModel]
    let model: VDRFillingStatusTimelineViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if !rowViewModels.isEmpty {
                    ForEach(Array(rowViewModels.enumerated()), id: \.1.id) { idx, item in
                        VDRFillingStatusEventRowView(
                            model: item
                        )
                    }

                    VDRFillingFinishStatusRowView(model: FormFillingStatusRowViewModel(fillingStatus: model.formFillingStatus))
                }
            }
            .cornerRadius(12)
            .padding(.vertical, 16)
        }
    }
}
