//
//  ExpirationLinkDateService.swift
//  Documents
//
//  Created by Pavel Chernyshev on 18.06.2024.
//  Copyright © 2024 Ascensio System SIA. All rights reserved.
//

import Foundation

class ExpirationLinkDateService {
    func getExpirationInterval(expirationDateString: String?) -> Interval? {
        guard let expirationDateString else { return nil }

        let expirationDate = Self.dateFormatter.date(from: expirationDateString)

        guard let timeInterval = expirationDate?.timeIntervalSince(Date()) else { return nil }
        if timeInterval < 0 {
            return .expired
        } else if timeInterval < 24 * 60 * 60 {
            let hours = 1 + Int(timeInterval / 3600)
            return .hours(hours)
        } else {
            let days = 1 + Int(timeInterval / (24 * 60 * 60))
            return .days(days)
        }
    }

    enum Interval: Equatable {
        case days(Int)
        case hours(Int)
        case expired

        static func == (lhs: Interval, rhs: Interval) -> Bool {
            switch (lhs, rhs) {
            case let (.days(lhsValue), .days(rhsValue)):
                return lhsValue == rhsValue
            case let (.hours(lhsValue), .hours(rhsValue)):
                return lhsValue == rhsValue
            case (.expired, .expired):
                return true
            default:
                return false
            }
        }
    }

    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSSZ"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        return formatter
    }()
}
