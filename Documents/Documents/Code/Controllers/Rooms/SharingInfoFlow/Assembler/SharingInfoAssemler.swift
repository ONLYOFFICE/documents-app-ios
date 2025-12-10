//
//  SharingInfoAssemler.swift
//  Documents
//
//  Created by Pavel Chernyshev on 12.11.2025.
//  Copyright © 2025 Ascensio System SIA. All rights reserved.
//

enum SharingInfoAssemler {
    @MainActor
    static func make(entityType: SharingInfoEntityType) -> SharingInfoView {
        SharingInfoView(
            viewModel: SharingInfoViewModel(
                entityType: entityType,
                viewModelService: SharingInfoViewModelServiceImp(entityType: entityType),
                linkAccessService: SharingInfoLinkAccessServiceImp(
                    entityType: entityType,
                    roomSharingLinkAccesskService: ServicesProvider.shared.roomSharingLinkAccesskService,
                    folderSharingNetworkService: ServicesProvider.shared.folderSharingNetworkService,
                    fileSharingNetworkService: ServicesProvider.shared.fileSharingNetworkService,
                    sharingRoomNetworkService: ServicesProvider.shared.roomSharingNetworkService,
                    editSharedLinkService: EditSharedLinkService(entity: entityType.editSharedLinkEntityType)
                )
            )
        )
    }
}
