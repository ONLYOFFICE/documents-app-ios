//
//  ASCSDWebImageDownloaderOperation.swift
//  Documents
//
//  Created by Alexander Yuzhin on 22/02/2018.
//  Copyright © 2018 Ascensio System SIA. All rights reserved.
//

import SDWebImage

class ASCSDWebImageDownloaderOperation: SDWebImageDownloaderOperation {
    override func urlSession(_ session: URLSession,
                             task: URLSessionTask,
                             willPerformHTTPRedirection response: HTTPURLResponse,
                             newRequest request: URLRequest,
                             completionHandler: @escaping (URLRequest?) -> Void)
    {
        var modifyRequest = request

        if let provider = ASCFileManager.provider {
            modifyRequest = provider.modifyImageDownloader(request: modifyRequest)
        }

        completionHandler(modifyRequest)
    }
}
