//
//  VDRFillingStatusTimelineView.swift
//  Documents-opensource
//
//  Created by Pavel Chernyshev on 10.05.2025.
//  Copyright © 2025 Ascensio System SIA. All rights reserved.
//

import SwiftUI

/// Timeline view showing list of events
struct VDRFillingStatusTimelineView: View {
    let events: [VDRFillingStatusEvent]

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(Array(events.enumerated()), id: \.1.id) { idx, item in
                    VDRFillingStatusEventRowView(
                        event: item,
                        showConnector: idx < events.count - 1
                    )
                }
            }
            .padding(.vertical, 8)
        }
    }
}
