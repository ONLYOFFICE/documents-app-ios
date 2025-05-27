//
//  VDRFillingStatusResponceModel.swift
//  Documents
//
//  Created by Pavel Chernyshev on 19.05.2025.
//  Copyright © 2025 Ascensio System SIA. All rights reserved.
//

import Foundation
import SwiftUI

struct VDRFillingStatusResponceModel: Codable {
    let roleName: String?
    let user: ASCUser?
    let stoppedBy: ASCUser?
    let sequence: Int
    var submitted: Bool = false
    let stopedBy: ASCUser?
    let history: VDRFillingHistory?
    let roleStatus: FormFillingStatus?
    let roleColor: String?

    var roleSwiftUIColor: Color {
        guard let roleColor else { return .black }
        return Color(hex: roleColor)
    }
}

struct VDRFillingHistory: Codable {
    let started: String?
    let completed: String?
    let stopped: String?

    static let isoFormatter = ISO8601DateFormatter()
    static let isoFormatterMillisec: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [
            .withInternetDateTime,
            .withFractionalSeconds,
        ]
        return f
    }()

    var history: [Int: Date] {
        [started, completed, stopped]
            .enumerated()
            .reduce(into: [Int: Date]()) { partialResult, item in
                if let dateStr = item.element,
                   let date = Self.isoFormatter.date(from: dateStr)
                   ?? Self.isoFormatterMillisec.date(from: dateStr)
                {
                    partialResult[item.offset] = date
                }
            }
    }

    enum CodingKeys: String, CodingKey {
        case started = "0"
        case completed = "1"
        case stopped = "2"
    }
}

struct DynamicKey: CodingKey {
    var stringValue: String
    init?(stringValue: String) { self.stringValue = stringValue }

    var intValue: Int? { Int(stringValue) }
    init?(intValue: Int) { stringValue = "\(intValue)" }
}

extension VDRFillingHistory {
    func mapToHistoryElements() -> [VDRFillingHistoryElement] {
        return (0 ... 3).compactMap {
            guard let date = history[$0] else { return nil }
            return VDRFillingHistoryElement(statusCode: String($0), date: date)
        }
    }
}

extension Array where Element == VDRFillingStatusResponceModel {
    func mapToVDRFillingStatusEventRowViewModel() -> [VDRFillingStatusEventRowViewModel] {
        var res = [VDRFillingStatusEventRowViewModel]()
        var isStopped = false
        for item in self {
            isStopped = isStopped || item.roleStatus == .stopped
            let borderType = item.roleStatus == .complete || isStopped
                ? VDRFillingStatusEventRowViewModel.BorderType.solid
                : .dashed
            let defaultBorderColor: Color = borderType == .solid ? .gray : .gray.opacity(0.4)
            let imageBorderColor: Color = {
                guard item.roleStatus != .yourTurn else { return .blue }
                guard !isStopped else { return .red }
                return defaultBorderColor
            }()
            let roleColor: Color = {
                guard item.roleStatus != .yourTurn else { return .blue }
                guard item.roleStatus != .stopped else { return .red }
                return .black
            }()
            res.append(
                VDRFillingStatusEventRowViewModel(
                    id: UUID(),
                    user: item.user,
                    stopedBy: item.stopedBy,
                    secuence: item.sequence,
                    roleName: item.roleName ?? "",
                    imageBorderColor: imageBorderColor,
                    statusBorderColor: isStopped ? .red : defaultBorderColor,
                    roleColor: roleColor,
                    borderType: item.roleStatus == .complete || isStopped ? .solid : .dashed,
                    actorName: item.user?.displayName ?? "",
                    history: item.history?.mapToHistoryElements() ?? [],
                    fillingStatus: item.roleStatus ?? .none
                )
            )
        }
        return res
    }
}
