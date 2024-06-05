//
//  SharedSettingsViewModel.swift
//  Documents-opensource
//
//  Created by Lolita Chernysheva on 01.06.2024.
//  Copyright © 2024 Ascensio System SIA. All rights reserved.
//

import Combine
import Foundation
import SwiftUI

struct LinksFlowModel {
    var links: [SharedSettingsLinkResponceModel] = []
}

final class SharedSettingsViewModel: ObservableObject {
    let file: ASCFile

    private let networkService = NetworkManagerSharedSettings()
    private(set) var flowModel = LinksFlowModel()

    @Published var isShared: Bool
    @Published var links: [SharedSettingsLinkRowModel] = []
    @Published var isDocspaceUserOnly: Bool = false

    init(file: ASCFile) {
        self.file = file
        isShared = file.shared
        loadLinks()
        buildViewModel()
    }

    func createAndCopySharedLink() {}

    func loadLinks() {
        networkService.fetchFileLinks(file: file) { [weak self] result in
            guard let self else { return }
            switch result {
            case let .success(links):
                self.flowModel.links = links
                self.buildViewModel()
            case let .failure(error):
                print(error.localizedDescription)
            }
        }
    }

    func buildViewModel() {
        links = flowModel.links.map { self.mapToLinkViewModel(link: $0) }
    }

    func mapToLinkViewModel(link: SharedSettingsLinkResponceModel) -> SharedSettingsLinkRowModel {
        return SharedSettingsLinkRowModel(
            id: link.sharedTo.id,
            linkAccess: link.sharedTo.isInternal ? .docspaceUserOnly : .anyoneWithLink,
            expiredTo: "",
            rights: ""
        ) {
            // MARK: TODO
        }
    }
}
