//
//  ASCIntroViewController.swift
//  Documents
//
//  Created by Alexander Yuzhin on 5/2/17.
//  Copyright © 2017 Ascensio System SIA. All rights reserved.
//

import UIKit

class ASCIntroViewController: UIViewController {
    static let identifier = String(describing: ASCIntroViewController.self)

    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var doneButton: UIButton!
    
    private var pageViewController: UIPageViewController? {
        didSet {
            configure()
        }
    }
    private var pages = [UIViewController]()
    private var pagesInfo: [[String: String]] = [
        [
            "image": "intro-step-one",
            "title": NSLocalizedString("Getting started", comment: "Introduction Step One - Title"),
            "info": String.localizedStringWithFormat(NSLocalizedString("Welcome to %@ mobile editing suite!\nSwipe to learn more about the app.", comment: "Introduction Step One - Description"), ASCConstants.Name.appNameShort)
        ],[
            "image": "intro-step-two",
            "title": NSLocalizedString("Work with office files", comment: "Introduction Step Two - Title"),
            "info": NSLocalizedString("Create and edit documents with our comprehensive toolbar: work with complex objects in text documents, perform extensive calculations in spreadsheets, create stunning presentations and view PDF files with no formatting loss.", comment: "Introduction Step Two - Description")
        ],[
            "image": "intro-step-three",
            "title": NSLocalizedString("Third-party storage", comment: "Introduction Step Three - Title"),
            "info": String.localizedStringWithFormat(NSLocalizedString("Connect third-party storage\nlike Nextcloud, ownCloud, Yandex Disk and\nothers which use WebDAV protocol.", comment: "Introduction Step Three - Description"), ASCConstants.Name.appNameShort)
        ],[
            "image": "intro-step-four",
            "title": NSLocalizedString("Edit documents locally", comment: "Introduction Step Four - Title"),
            "info": NSLocalizedString("Work with documents offline.\nCreated files can later be uploaded to online portal and\nthen accessed from any other device.", comment: "Introduction Step Four - Description")
        ],[
            "image": "intro-step-five",
            "title": NSLocalizedString("Collaborate with your team", comment: "Introduction Step Five - Title"),
            "info": String.localizedStringWithFormat(NSLocalizedString("In online mode, use real-time co-editing features of %@ to work on documents together with your portal members, share documents and create common storage folders.", comment: "Introduction Step Five - Description"), ASCConstants.Name.appNameShort)
        ]
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()

        doneButton.titleLabel?.numberOfLines = 1
        doneButton.titleLabel?.adjustsFontSizeToFitWidth = true
        doneButton.titleLabel?.lineBreakMode = .byClipping
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
        return UIDevice.phone ? .portrait : [.portrait, .landscape]
    }
    
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return UIDevice.phone ? .portrait : super.preferredInterfaceOrientationForPresentation
    }
    
    private func configure() {
        if let pageController = pageViewController {
            pageController.delegate = self
            pageController.dataSource = self
            
            if #available(iOS 13.0, *) {
                pageController.view.backgroundColor = .systemBackground
            } else {
                pageController.view.backgroundColor = .white
            }
            
            for subview in pageController.view.subviews {
                if subview is UIPageControl {
                    subview.isHidden = true
                }
            }
            
            pages.removeAll()
            
            for (index, info) in pagesInfo.enumerated() {
                let page = ASCIntroPageController.instantiate(from: Storyboard.intro)
                page.pageImage = UIImage(named: info["image"]!)
                page.pageTitle = info["title"]
                page.pageInfo = info["info"]
                page.view.tag = index

                pages.append(page)
            }
            
            if pages.count > 0 {
                pageController.setViewControllers([pages.first!], direction: .forward, animated: false, completion: nil)
            }
        }
    }

    // MARK: - Actions
    
    @IBAction func onDone(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == StoryboardSegue.Intro.embedPageController.rawValue {
            pageViewController = segue.destination as? UIPageViewController
        }
    }
}

extension ASCIntroViewController: UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        guard completed else { return }
        pageControl.currentPage = pageViewController.viewControllers?.first?.view.tag ?? previousViewControllers.first?.view.tag ?? 0
    }
}

extension ASCIntroViewController: UIPageViewControllerDataSource {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        let currentIndex = viewController.view.tag
        doneButton.setTitle(NSLocalizedString("SKIP", comment: "").uppercased(), for: .normal)

        if currentIndex < 1 {
            return nil
        }

        let previousIndex = abs((currentIndex - 1) % pages.count)
        return pages[previousIndex]
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        let currentIndex = viewController.view.tag

        if currentIndex >= pages.count - 1 {
            doneButton.setTitle(NSLocalizedString("GET STARTED!", comment: "").uppercased(), for: .normal)
            return nil
        }

        let nextIndex = abs((currentIndex + 1) % pages.count)
        return pages[nextIndex]
    }

    func presentationCount(for pageViewController: UIPageViewController) -> Int {
        pageControl.numberOfPages = pages.count
        return pages.count
    }

    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        return 0
    }
}
