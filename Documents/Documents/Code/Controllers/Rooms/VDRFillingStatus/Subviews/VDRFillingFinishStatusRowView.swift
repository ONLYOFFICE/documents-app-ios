//
//  VDRFillingFinishStatusRowView.swift
//  Documents
//
//  Created by Pavel Chernyshev on 21.05.2025.
//  Copyright © 2025 Ascensio System SIA. All rights reserved.
//

import SwiftUI

struct FormFillingStatusRowViewModel {
    let fillingStatus: FormFillingStatus
}

struct VDRFillingFinishStatusRowView: View {
    var model: FormFillingStatusRowViewModel
    var color: Color {
        isFinishedStatus
            ? model.fillingStatus.color
            : .gray
    }

    var finishedStatuses: [FormFillingStatus] {
        [FormFillingStatus.stopped, .complete]
    }

    var isFinishedStatus: Bool {
        finishedStatuses.contains(model.fillingStatus)
    }

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .strokeBorder(color, lineWidth: 1.4)
                    .frame(width: 40, height: 40)
                Circle()
                    .fill(Color(.systemBackground))
                    .frame(width: 36.3, height: 36.3)

                if isFinishedStatus {
                    Circle()
                        .fill(color)
                        .frame(width: 34, height: 34)
                }
                statusImage
            }

            Text(verbatim: isFinishedStatus
                ? model.fillingStatus.localizedString
                : NSLocalizedString("Complete", comment: "")
            )
            .font(.subheadline)
            .foregroundColor(color)
            Spacer()
        }
        .padding(.leading, 46)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }

    private var statusImage: some View {
        switch model.fillingStatus {
        case .stopped:
            Image(systemName: "xmark")
                .font(.system(size: 17, weight: .regular))
                .foregroundColor(.white)
        default:
            Image(systemName: "checkmark")
                .font(.system(size: 17, weight: .regular))
                .foregroundColor(isFinishedStatus ? .white : Color.secondary)
        }
    }
}
