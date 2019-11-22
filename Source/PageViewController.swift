//
//  PageViewController.swift
//  FolioReaderKit
//
//  Created by Heberti Almeida on 14/07/16.
//  Copyright © 2016 FolioReader. All rights reserved.
//

import UIKit

public extension UIImage {
    public convenience init?(color: UIColor, size: CGSize = CGSize(width: 1, height: 1)) {
        let rect = CGRect(origin: .zero, size: size)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0.0)
        color.setFill()
        UIRectFill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        guard let cgImage = image?.cgImage else { return nil }
        self.init(cgImage: cgImage)
    }
}

class PageViewController: UIPageViewController {
    var viewList = [UIViewController]()

    var viewControllerOne: UIViewController!
    var viewControllerTwo: UIViewController!
    var viewControllerThree: UIViewController!
    var index: Int
    
    var button1: UIButton?
    var button2: UIButton?
    var button3: UIButton?
    var closeButton: UIButton?
    var buttonSize = CGSize()
    var navBarView: ReaderNavBar?
    
    fileprivate var readerConfig: FolioReaderConfig
    fileprivate var folioReader: FolioReader

    // MARK: Lifecicle Object

    init(folioReader: FolioReader, readerConfig: FolioReaderConfig) {
        self.folioReader = folioReader
        self.readerConfig = readerConfig
        self.index = self.folioReader.currentMenuIndex
        super.init(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)

        self.edgesForExtendedLayout = UIRectEdge()
        self.extendedLayoutIncludesOpaqueBars = true
    }

    required init?(coder: NSCoder) {
        fatalError("storyboards are incompatible with truth and beauty")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("PAGE VIEW CONTROLLER")
        setupButtons()
        closeButton = setCloseButton()
        viewList = [viewControllerOne, viewControllerTwo, viewControllerThree]
        viewControllerOne.didMove(toParent: self)
        viewControllerTwo.didMove(toParent: self)
        viewControllerThree.didMove(toParent: self)
        self.delegate = self
        self.dataSource = self
        self.view.backgroundColor = UIColor.white
        self.setViewControllers([viewList[index]], direction: .forward, animated: false, completion: nil)
        buttonsTapped(sender: button1!)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateUI()
    }
    
    func updateUI() {
        let y: CGFloat = UIDevice.current.userInterfaceIdiom == .phone ? 50.0 : 55.0
        button1?.frame = CGRect(origin: CGPoint(x: self.view.center.x/2 - buttonSize.width/2, y: y), size: buttonSize)
        button2?.frame = CGRect(origin: CGPoint(x: self.view.center.x - buttonSize.width/2, y: y), size: buttonSize)
        button3?.frame = CGRect(origin: CGPoint(x: self.view.center.x + self.view.center.x/2 - buttonSize.width/2, y: y), size: buttonSize)
        closeButton?.frame = CGRect(origin: CGPoint(x: self.view.frame.width/2 - 27, y: self.view.frame.height - 70), size: CGSize(width: 55, height: 55))
    }
    
    func setupButtons() {

         if UIScreen.main.bounds.size.width < UIScreen.main.bounds.size.height {
            buttonSize = CGSize(width: 78, height: 20)
        } else {
            buttonSize = CGSize(width: 110, height: 30)
        }
        let y: CGFloat = UIDevice.current.userInterfaceIdiom == .phone ? 50.0 : 55.0
        button1  = UIButton(type: .custom)
        button1?.frame = CGRect(origin: CGPoint(x: self.view.center.x/2 - buttonSize.width/2, y:  y), size: buttonSize)
        button1?.tag = 0
        button1?.addTarget(self, action: #selector(buttonsTapped), for: .touchUpInside)
        button1?.setImage(#imageLiteral(resourceName: "content"), for: .normal)
        button1?.setImage(#imageLiteral(resourceName: "content_blue"), for: .selected)
        self.view.addSubview(button1!)
        
        button2  = UIButton(type: .custom)
        button2?.frame =  CGRect(origin: CGPoint(x: self.view.center.x - buttonSize.width/2, y: y), size: buttonSize)
        button2?.tag = 1
        button2?.addTarget(self, action: #selector(buttonsTapped), for: .touchUpInside)
        button2?.setImage(#imageLiteral(resourceName: "Bookmarks"), for: .normal)
        button2?.setImage(#imageLiteral(resourceName: "Bookmarks_blue"), for: .selected)
        self.view.addSubview(button2!)

        button3  = UIButton(type: .custom)
        button3?.frame = CGRect(origin: CGPoint(x: self.view.center.x + self.view.center.x/2 - buttonSize.width/2, y: y), size: buttonSize)
        button3?.tag = 2
        button3?.addTarget(self, action: #selector(buttonsTapped), for: .touchUpInside)
        button3?.setImage(#imageLiteral(resourceName: "emphasis"), for: .normal)
        button3?.setImage(#imageLiteral(resourceName: "emphasis_blue"), for: .selected)
        self.view.addSubview(button3!)
    }
    
    func configureCustomNavBar() {
        let navBackground = self.folioReader.isNight(self.readerConfig.nightModeMenuBackground, UIColor.black)
        let tintColor = self.readerConfig.tintColor
        let navText = self.folioReader.isNight(UIColor.white, UIColor.white)
        let font = UIFont(name: "Avenir-Light", size: 25)!
        setTranslucentNavigation(false, color: navBackground, tintColor: tintColor, titleColor: navText, andFont: font)
    }
    
    func configureNavBar() {
/***/
        let navBackground = self.folioReader.isNight(self.readerConfig.nightModeMenuBackground, UIColor.white)
        let tintColor = self.readerConfig.tintColor
        let navText = self.folioReader.isNight(UIColor.white, UIColor.black)
        let font = UIFont(name: "Avenir-Light", size: 17)!
        setTranslucentNavigation(true, color: navBackground, tintColor: tintColor, titleColor: navText, andFont: font)
/***/
        
        navBarView = ReaderNavBar.instanceFromNib()
        navBarView?.pageViewController = self
        navBarView?.frame.size.width = view.frame.width
    }

    
    func presentNavBarView() {
        UIView.animate(withDuration: 1.0,
                       delay: 0.0,
                       options: .curveEaseIn,
                       animations: {  },
                       completion: { _ in
                        if let navBarView = self.navBarView {
                            self.view.addSubview(navBarView)
                        }
        })
    }
    
    
    func dismissNavBarView() {
        UIView.animate(withDuration: 1.0,
                       delay: 0.0,
                       options: .curveEaseOut,
                       animations: { },
                       completion: { _ in
                        self.navBarView?.removeFromSuperview()
        })
    }

    // MARK: - Actions

    @IBAction func buttonsTapped(sender: UIButton) {
        
        if sender.tag == 0 {
            if !sender.isSelected {
                sender.isSelected = true
                button2?.isSelected = false
                button3?.isSelected = false
            }
        }
        
        if sender.tag == 1 {
            if !sender.isSelected {
                sender.isSelected = true
                button1?.isSelected = false
                button3?.isSelected = false
            }
        }

        if sender.tag == 2 {
            if !sender.isSelected {
                sender.isSelected = true
                button1?.isSelected = false
                button2?.isSelected = false
            }
        }
        switchController(with: sender.tag)
    }
    
    func switchController(with index: Int) {
        let direction: UIPageViewController.NavigationDirection = (index < folioReader.currentMenuIndex ? .reverse : .forward)
        setViewControllers([viewList[index]], direction: direction, animated: true, completion: nil)
        self.folioReader.currentMenuIndex = index
    }
    
    override open func willRotate(to toInterfaceOrientation: UIInterfaceOrientation, duration: TimeInterval) {
        super.willRotate(to: toInterfaceOrientation, duration: duration)
        folioReader.readerCenter?.willRotate(to: toInterfaceOrientation, duration: duration)
    }
    
    override open func willAnimateRotation(to toInterfaceOrientation: UIInterfaceOrientation, duration: TimeInterval) {
        super.willAnimateRotation(to: toInterfaceOrientation, duration: duration)
        folioReader.readerCenter?.willAnimateRotation(to: toInterfaceOrientation, duration: duration)
    }
    
    override open func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
        super.didRotate(from: fromInterfaceOrientation)
        var buttonSize = CGSize()
        if UIScreen.main.bounds.size.width < UIScreen.main.bounds.size.height {
            buttonSize = CGSize(width: 78, height: 20)
        } else {
            buttonSize = CGSize(width: 110, height: 30)
        }
        button1?.frame = CGRect(origin: CGPoint(x: self.view.frame.width/4 - buttonSize.width/2, y: 40), size: buttonSize)
        button2?.frame =  CGRect(origin: CGPoint(x: self.view.frame.width/2 - buttonSize.width/2, y: 40), size: buttonSize)
        button3?.frame = CGRect(origin: CGPoint(x: self.view.frame.width*3/4 - buttonSize.width/2, y: 40), size: buttonSize)
        self.view.layoutIfNeeded()
        folioReader.readerCenter?.didRotate(from: fromInterfaceOrientation)
        folioReader.readerCenter?.needReload = true
    }
}

// MARK: UIPageViewControllerDelegate

extension PageViewController: UIPageViewControllerDelegate {

    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {

        if finished && completed {
            let viewController = pageViewController.viewControllers?.last
//            segmentedControl.selectedSegmentIndex = viewList.index(of: viewController!)!
        }
    }
}

// MARK: UIPageViewControllerDataSource

extension PageViewController: UIPageViewControllerDataSource {

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {

        let index = viewList.index(of: viewController)!
        if index == 0 {
            button1?.isSelected = true
            button2?.isSelected = false
            button3?.isSelected = false
        } else if index == 1 {
            button2?.isSelected = true
            button1?.isSelected = false
            button3?.isSelected = false
        } else if index == 2 {
            button3?.isSelected = true
            button1?.isSelected = false
            button2?.isSelected = false
        }
        
        if index < viewList.count - 1 {
            return viewList[index + 1]
        }

        return nil
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {

        let index = viewList.index(of: viewController)!
        if index == 0 {
            button1?.isSelected = true
            button2?.isSelected = false
            button3?.isSelected = false
        } else if index == 1 {
            button2?.isSelected = true
            button1?.isSelected = false
            button3?.isSelected = false
        } else if index == 2 {
            button3?.isSelected = true
            button1?.isSelected = false
            button2?.isSelected = false
        }
        if index > 0 {
            return viewList[index - 1]
        }

        return nil
    }
}

