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

    @IBOutlet var pageControl: UIPageControl!
    @IBOutlet var doneButton: UIButton!

    private var pageViewController: UIPageViewController? {
        didSet {
            configure()
        }
    }

    private var pageViewControllers = [UIViewController]()
    private var pages: [ASCIntroPage] = [
        /// 1
        ASCIntroPage(
            title: NSLocalizedString("Getting started", comment: "Introduction Step One - Title"),
            subtitle: String.localizedStringWithFormat(NSLocalizedString("Welcome to %@ mobile editing suite!\nSwipe to learn more about the app.", comment: "Introduction Step One - Description"), ASCConstants.Name.appNameShort),
            image: Asset.Images.introStepOne.image
        ),
        /// 2
        ASCIntroPage(
            title: NSLocalizedString("Work with office files", comment: "Introduction Step Two - Title"),
            subtitle: NSLocalizedString("Create and edit documents with our comprehensive toolbar: work with complex objects in text documents, perform extensive calculations in spreadsheets, create stunning presentations and view PDF files with no formatting loss.", comment: "Introduction Step Two - Description"),
            image: Asset.Images.introStepTwo.image
        ),
        /// 3
        ASCIntroPage(
            title: NSLocalizedString("Third-party storage", comment: "Introduction Step Three - Title"),
            subtitle: String.localizedStringWithFormat(NSLocalizedString("Connect third-party storage\nlike Nextcloud, ownCloud, Yandex Disk and\nothers which use WebDAV protocol.", comment: "Introduction Step Three - Description"), ASCConstants.Name.appNameShort),
            image: Asset.Images.introStepThree.image
        ),
        /// 4
        ASCIntroPage(
            title: NSLocalizedString("Edit documents locally", comment: "Introduction Step Four - Title"),
            subtitle: NSLocalizedString("Work with documents offline.\nCreated files can later be uploaded to online portal and\nthen accessed from any other device.", comment: "Introduction Step Four - Description"),
            image: Asset.Images.introStepFour.image
        ),
        /// 5
        ASCIntroPage(
            title: NSLocalizedString("Collaborate with your team", comment: "Introduction Step Five - Title"),
            subtitle: String.localizedStringWithFormat(NSLocalizedString("In online mode, use real-time co-editing features of %@ to work on documents together with your portal members, share documents and create common storage folders.", comment: "Introduction Step Five - Description"), ASCConstants.Name.appNameShort),
            image: Asset.Images.introStepFive.image
        ),
    ]

    override func viewDidLoad() {
        super.viewDidLoad()

        doneButton.titleLabel?.numberOfLines = 1
        doneButton.titleLabel?.adjustsFontSizeToFitWidth = true
        doneButton.titleLabel?.lineBreakMode = .byClipping

        if #available(iOS 13.0, *) {
            pageControl.pageIndicatorTintColor = UIColor.systemGray5
            pageControl.currentPageIndicatorTintColor = UIColor.systemGray
        }

        pageControl.addTarget(self, action: #selector(pageControlSelectionAction), for: [.touchUpInside, .touchUpOutside])
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
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

            pageViewControllers.removeAll()

            for (index, page) in pages.enumerated() {
                let pageVC = ASCIntroPageController.instantiate(from: Storyboard.intro)
                pageVC.page = page
                pageVC.view.tag = index

                pageViewControllers.append(pageVC)
            }

            if let firstViewController = pageViewControllers.first {
                pageController.setViewControllers([firstViewController], direction: .forward, animated: false, completion: nil)
            }
        }
    }

    private func updateDone(by index: Int) {
        var title = NSLocalizedString("SKIP", comment: "")

        if index >= pageViewControllers.count - 1 {
            title = NSLocalizedString("GET STARTED!", comment: "")
        }

        doneButton.setTitle(title.uppercased(), for: .normal)
    }

    // MARK: - Actions

    @IBAction func onDone(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }

    @objc func pageControlSelectionAction(_ sender: UIPageControl) {
        let prevIndex = sender.currentPage
        delay(seconds: 0.1) {
            let page = self.pageControl.currentPage

            var direction: UIPageViewController.NavigationDirection = page - prevIndex > 0 ? .forward : .reverse

            if page < 1 {
                direction = .reverse
            }

            self.pageViewController?.setViewControllers([self.pageViewControllers[page]], direction: direction, animated: true, completion: nil)
            self.updateDone(by: page)
        }
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
        updateDone(by: pageControl.currentPage)
    }
}

extension ASCIntroViewController: UIPageViewControllerDataSource {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        let currentIndex = viewController.view.tag

        if currentIndex < 1 {
            return nil
        }

        let previousIndex = abs((currentIndex - 1) % pageViewControllers.count)
        return pageViewControllers[previousIndex]
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        let currentIndex = viewController.view.tag

        if currentIndex >= pages.count - 1 {
            return nil
        }

        let nextIndex = abs((currentIndex + 1) % pageViewControllers.count)

        return pageViewControllers[nextIndex]
    }

    func presentationCount(for pageViewController: UIPageViewController) -> Int {
        pageControl.numberOfPages = pageViewControllers.count
        return pageViewControllers.count
    }

    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        return 0
    }
}
