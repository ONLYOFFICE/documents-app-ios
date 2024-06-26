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

    // MARK: - Outlets

    @IBOutlet var pageControl: UIPageControl!
    @IBOutlet var doneButton: UIButton!

    // MARK: - Properties

    var complation: (() -> Void)?

    private var pageViewController: UIPageViewController? {
        didSet {
            configure()
        }
    }

    private var pageViewControllers = [UIViewController]()
    private var pages: [ASCIntroPage] {
        ASCDIContainer.shared.resolve(type: ASCIntroPageStoreProtocol.self)?.fetch() ?? []
    }

    // MARK: - Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        doneButton.titleLabel?.numberOfLines = 1
        doneButton.titleLabel?.adjustsFontSizeToFitWidth = true
        doneButton.titleLabel?.lineBreakMode = .byClipping

        pageControl.pageIndicatorTintColor = UIColor.systemGray5
        pageControl.currentPageIndicatorTintColor = UIColor.systemGray

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
        dismiss(animated: true, completion: complation)
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
