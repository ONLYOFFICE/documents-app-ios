//
//  ASCDownloaderTests.swift
//  DocumentsTests
//
//  Created by Alexander Yuzhin on 26.01.2024.
//  Copyright © 2024 Ascensio System SIA. All rights reserved.
//

import Foundation

class ASCDownloader {
    class func load(url: URL, to localUrl: URL, completion: @escaping (Data) -> Void) {
        let sessionConfig = URLSessionConfiguration.default
        let session = URLSession(configuration: sessionConfig)
        var request = try! URLRequest(url: url, method: .get)

        request.setValue("Bearer bEIWYlIjVYIZn6/s6nkmMuErLgcTIxlXeg4ocLXndV4qwjxujYSzbUlQtDhHQu9mpxkr8zuR9DxRF5fu/BjaZe6hFvF8rdAniVQwl/c8bQRV/NmWZMLsxjGB5cu8dKug1jrbDVHacwblB+DiWTe95EG5g9CImj1UJd00Br2m2BA=", forHTTPHeaderField: "Authorization")
        request.setValue("bytes=0-110", forHTTPHeaderField: "Range")

        let task = session.downloadTask(with: request) { tempLocalUrl, response, error in
            if let tempLocalUrl, error == nil {
                // Success
                if let statusCode = (response as? HTTPURLResponse)?.statusCode {
                    print("Success: \(statusCode)")
                }

//                do {
//                    try FileManager.default.copyItem(at: tempLocalUrl, to: localUrl)
//                    completion()
//                } catch (let writeError) {
//                    print("error writing file \(localUrl) : \(writeError)")
//                }

            } else {
                print("Failure: %@", error?.localizedDescription)
            }
        }
        task.resume()
    }
}

import XCTest

class ASCDownloaderTests: XCTestCase {
    override func setUpWithError() throws {
        try super.setUpWithError()
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
    }

    func testDownnloadPartially() {
        let downloadUrl = URL(string: "https://alexanderyuzhin.teamlab.info/Products/Files/HttpHandlers/filehandler.ashx?action=download&fileid=8687219")!

        ASCDownloader.load(url: downloadUrl, to: URL(fileURLWithPath: "")) { data in
            //
        }
//        XCTAssertEqual(sut.definePortalType(), .unknown)
    }
}
