//
//  ASCImageViewController.swift
//  Documents
//
//  Created by Alexander Yuzhin on 3/28/17.
//  Copyright © 2017 Ascensio System SIA. All rights reserved.
//

import UIKit
import MediaBrowser
import SDWebImage

class ASCImageViewController: MediaBrowser {
    
    var medias: [Media] = [] {
        didSet {
            reloadData()
        }
    }
    var dismissHandler: (() -> Void)? = nil

    private var fileProvider: ASCFileProviderProtocol?

    convenience init(with provider: ASCFileProviderProtocol) {
        self.init()

        fileProvider = provider
        delegate = self
        displayActionButton = true
        zoomPhotosToFill = false
        enableGrid = true
        loadingIndicatorShouldShowValueText = false

        setCurrentIndex(at: 0)

        if let authorization = provider.authorization {
            let imageDownloader = SDWebImageDownloader.shared
            imageDownloader.config.operationClass = ASCSDWebImageDownloaderOperation.self
            imageDownloader.setValue(authorization, forHTTPHeaderField: "Authorization")
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .black

        // Translate MWPhotoBrowser strings
        let _ = [
            NSLocalizedString("Select Photos", comment: ""),
            NSLocalizedString("photo", comment:"Used in the context: '1 photo'"),
            NSLocalizedString("photos", comment:"Used in the context: '3 photos'"),
            NSLocalizedString("of", comment: "Used in the context: 'Showing 1 of 3 items'")
        ]
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override func reloadData() {
        super.reloadData()
        navigationItem.rightBarButtonItem?.title = NSLocalizedString("Close", comment: "Close view")
    }

    override func performLayout() {
        super.performLayout()
        navigationItem.rightBarButtonItem?.title = NSLocalizedString("Close", comment: "Close view")
    }

    override func updateNavigation() {
        super.updateNavigation()
        navigationItem.rightBarButtonItem?.title = NSLocalizedString("Close", comment: "Close view")
    }
}

extension ASCImageViewController: MediaBrowserDelegate {

    func numberOfMedia(in mediaBrowser: MediaBrowser) -> Int {
        return medias.count
    }

    func media(for mediaBrowser: MediaBrowser, at index: Int) -> Media {
        if (index < medias.count) {
            return medias[index]
        }
        return Media()
    }
    
    func thumbnail(for mediaBrowser: MediaBrowser, at index: Int) -> Media {
        if (index < medias.count) {
            return medias[index]
        }
        return Media()
    }
    
    func mediaBrowserDidFinishModalPresentation(mediaBrowser: MediaBrowser) {
        dismiss(animated: true) {
            self.dismissHandler?()
        }
    }

    func accessToken(for url: URL?) -> String? {
        guard let provider = fileProvider else { return nil }

        if let onlyofficeProvider = provider as? ASCOnlyofficeProvider {
            // TODO: Hotfix by Linnic. Remove after resolve of conflict between SAAS and Enterprise versions
            if let baseUrl = onlyofficeProvider.api.baseUrl, URL(string: baseUrl)?.host == url?.host {
                return onlyofficeProvider.authorization
            }
        } else {
            return provider.authorization
        }

        return nil
    }
}
