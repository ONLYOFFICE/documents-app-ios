//
//  ASCDIProtocol.swift
//  Documents
//
//  Created by Alexander Yuzhin on 23.10.2023.
//  Copyright © 2023 Ascensio System SIA. All rights reserved.
//

import Foundation

protocol ASCDIProtocol {
    func register<Service>(type: Service.Type, service: Any)
    func resolve<Service>(type: Service.Type) -> Service?
}
