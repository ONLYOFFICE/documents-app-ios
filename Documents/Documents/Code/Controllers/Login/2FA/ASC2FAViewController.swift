//
//  ASC2FAViewController.swift
//  Documents
//
//  Created by Alexander Yuzhin on 15/04/2019.
//  Copyright © 2019 Ascensio System SIA. All rights reserved.
//

import UIKit

class ASC2FAViewController: UIViewController {
    static let identifier = String(describing: ASC2FAViewController.self)

    // MARK: - Properties

    var options: [String: Any] = [:]
    var completeon: ASCSignInComplateHandler?

    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var doneButton: UIButton!

    private var pageViewController: UIPageViewController? {
        didSet {
            configure()
        }
    }
    private var pages = [UIViewController]()
    private var pagesIdentifiers: [String] = [
        "ASC2FAStepInstallAppPageController",
        "ASC2FAStepRunAppPageController",
        "ASC2FAStepSecretPageController",
        "ASC2FAStepCodePageController"
    ]

    // MARK: - Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        doneButton.setTitle(NSLocalizedString("Next", comment: "Next step").uppercased(),
                            for: .normal)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if let navigationController = navigationController {
            navigationController.navigationBar.setBackgroundImage(UIImage(), for: .default)
            navigationController.navigationBar.isTranslucent = true
            navigationController.navigationBar.shadowImage = UIImage()
        }
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

            for (index, identifier) in pagesIdentifiers.enumerated() {
                if let page = storyboard?.instantiateViewController(withIdentifier: identifier) {
                    if let pageVC = page as? ASC2FAPageController {
                        pageVC.secret = options["tfaKey"] as? String
                        pageVC.options = options
                    } else if let codeVC = page as? ASC2FACodeViewController {
                        codeVC.options = options
                        codeVC.completeon = completeon
                    }
                    page.view.tag = index
                    pages.append(page)
                }
            }

            if pages.count > 0 {
                pageController.setViewControllers([pages.first!], direction: .forward, animated: false, completion: nil)
            }
        }
    }

    // MARK: - Actions

    @IBAction func onDone(_ sender: UIButton) {
        guard
            let pageViewController = pageViewController,
            let currentViewController = pageViewController.viewControllers?.first,
            let nextViewController = pageViewController.dataSource?.pageViewController(pageViewController, viewControllerAfter: currentViewController)
        else { return }

        pageViewController.setViewControllers([nextViewController], direction: .forward, animated: true) { [weak self] finished in
            if let pageCount = self?.pages.count, let currentIndex = pageViewController.viewControllers?.first?.view.tag {
                self?.pageControl.currentPage = currentIndex

                if currentIndex >= pageCount - 1 {
                    self?.doneButton?.isHidden = true
                }
            }
        }
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == StoryboardSegue.Login.embedPageController.rawValue {
            pageViewController = segue.destination as? UIPageViewController
        }
    }
}


extension ASC2FAViewController: UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController,
                            didFinishAnimating finished: Bool,
                            previousViewControllers: [UIViewController],
                            transitionCompleted completed: Bool)
    {
        guard completed else { return }
        pageControl.currentPage = pageViewController.viewControllers?.first?.view.tag ?? previousViewControllers.first?.view.tag ?? 0
    }
}

extension ASC2FAViewController: UIPageViewControllerDataSource {
    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerBefore viewController: UIViewController) -> UIViewController?
    {
        let currentIndex = viewController.view.tag

        doneButton?.isHidden = false
        doneButton.setTitle(NSLocalizedString("Next", comment: "Next step").uppercased(),
                            for: .normal)

        if currentIndex < 1 {
            return nil
        }

        let previousIndex = abs((currentIndex - 1) % pages.count)
        return pages[previousIndex]
    }

    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerAfter viewController: UIViewController) -> UIViewController?
    {
        let currentIndex = viewController.view.tag

        if currentIndex >= pages.count - 1 {
            doneButton?.isHidden = true
            return nil
        }

        doneButton?.isHidden = false

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
