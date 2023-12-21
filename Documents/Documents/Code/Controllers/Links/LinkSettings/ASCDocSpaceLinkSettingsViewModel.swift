//
//  ASCDocSpaceLinkSettingsViewModel.swift
//  Documents
//
//  Created by Lolita Chernysheva on 03.12.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import Combine
import SwiftUI

enum LinkSettingsContentState {
    case general
    case additional
}

final class ASCDocSpaceLinkSettingsViewModel: ObservableObject {
    @Published var isProtected: Bool = false
    @Published var isRestrictCopyOn: Bool = false
    @Published var isTimeLimited: Bool = false
    @Published var contentState: LinkSettingsContentState

    private var cancelable = Set<AnyCancellable>()

    // MARK: temp

    init(contentState: LinkSettingsContentState = .general) {
        self.contentState = contentState
    }
}

//    private func setIsProtectedHandler() {
//        $isProtected
//            .sink { [weak self] value in
//                guard let self else { return }
//                switch contentState {
//                case .general:
//                    contentState = .general(protected: value)
//                case let .additional(_, timeLimited):
//                    contentState = .additional(protected: value, timeLimited: timeLimited)
//                }
//            }
//            .store(in: &cancelable)
//    }
//
//    private func setIsTmeLimitedHandler() {
//        $isTimeLimited
//            .sink { [weak self] value in
//                print("isTimeLimited", value)
//                guard let self else { return }
//                switch contentState {
//                case let .additional(protected, _):
//                    contentState = .additional(protected: protected, timeLimited: value)
//                default:
//                    break
//                }
//            }
//            .store(in: &cancelable)
//    }
