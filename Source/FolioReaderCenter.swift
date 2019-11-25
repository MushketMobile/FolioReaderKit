//
//  FolioReaderCenter.swift
//  FolioReaderKit
//
//  Created by Heberti Almeida on 08/04/15.
//  Copyright (c) 2015 Folio Reader. All rights reserved.
//


import UIKit
import ZFDragableModalTransition

/// Protocol which is used from `FolioReaderCenter`s.
@objc public protocol FolioReaderCenterDelegate: class {
    
    /// Notifies that a page appeared. This is triggered is a page is chosen and displayed.
    ///
    /// - Parameter page: The appeared page
    @objc optional func pageDidAppear(_ page: FolioReaderPage)
    
    /// Passes and returns the HTML content as `String`. Implement this method if you want to modify the HTML content of a `FolioReaderPage`.
    ///
    /// - Parameters:
    ///   - page: The `FolioReaderPage`.
    ///   - htmlContent: The current HTML content as `String`.
    /// - Returns: The adjusted HTML content as `String`. This is the content which will be loaded into the given `FolioReaderPage`.
    @objc optional func htmlContentForPage(_ page: FolioReaderPage, htmlContent: String) -> String
}


/// The base reader class
open class FolioReaderCenter: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UIWebViewDelegate, UICollectionViewDelegateFlowLayout {
    
    /// This delegate receives the events from the current `FolioReaderPage`s delegate.
    open weak var delegate: FolioReaderCenterDelegate?
    
    /// This delegate receives the events from current page
    open weak var pageDelegate: FolioReaderPageDelegate?
    
    /// The base reader container
    open weak var readerContainer: FolioReaderContainer?
    
    /// The current visible page on reader
    open fileprivate(set) var currentPage: FolioReaderPage?
    open var readerProgressManager: ReaderProgressManager?

    var goToPagePositionInChapter: Float?
    var scrolltoPage: Int?
    var tutorialDidShow: Bool = false

    var collectionView: UICollectionView!

    let collectionViewLayout = UICollectionViewFlowLayout()
    var loadingView: UIActivityIndicatorView!
    var pages: [String]!
    var totalPages: Int = 0
    var tempFragment: String?
    var animator: ZFModalTransitionAnimator!
    var pageIndicatorView: FolioReaderPageIndicator?
    var pageIndicatorHeight: CGFloat = 20
    var recentlyScrolled = false
    var recentlyScrolledDelay = 2.0 // 2 second delay until we clear recentlyScrolled
    var recentlyScrolledTimer: Timer!
    var scrollScrubber: ScrollScrubber?
    var activityIndicator = UIActivityIndicatorView()
    var isScrolling = false
    var needScrollOffset = false
    var needScrollAfterRotation = false
    var pageScrollDirection = ScrollDirection()
    var nextPageNumber: Int = 0
    var previousPageNumber: Int = 0
    var currentPageNumber: Int = 0
    var pageWidth: CGFloat = 0.0
    var pageHeight: CGFloat = 0.0
    var keyboardHeight: CGFloat = 0.0

    var arrays: [FolioReaderWebView] = []
    var lastContentOffset: CGPoint = CGPoint()
    
    var navBarView: ReaderNavBar?
    var bookTitleView: ReaderBookTitleBar?
    open var progressView: ReaderProgress?
    var folioReaderFontsMenu: FolioReaderFontsMenu?
    var searchBar: ReaderSearchBar?
    var popUpView: PopUpView?
    
    var searchBarShouldHide = false
    var navBarShouldHide = false
    var fontsMenuShouldHide = true
    var needReload = false
    var popUpShouldHide = true

    var newChpt = 0
    var lastChpt = -1
    
    fileprivate var screenBounds: CGRect!
    fileprivate var pointNow = CGPoint.zero
    fileprivate var pageOffsetRate: CGFloat = 0
    fileprivate var tempReference: FRTocReference?
    fileprivate var isFirstLoad = true
    fileprivate var currentWebViewScrollPositions = [Int: CGPoint]()
    fileprivate var currentOrientation: UIInterfaceOrientation?
    
    fileprivate var readerConfig: FolioReaderConfig {
        guard let readerContainer = readerContainer else { return FolioReaderConfig() }
        return readerContainer.readerConfig
    }
    
    public var book: FRBook {
        guard let readerContainer = readerContainer else { return FRBook() }
        return readerContainer.book
    }

    public var folioReader: FolioReader {
        guard let readerContainer = readerContainer else { return FolioReader() }
        return readerContainer.folioReader
    }
    
    // MARK: - Init
    
    init(withContainer readerContainer: FolioReaderContainer) {
        self.readerContainer = readerContainer
        super.init(nibName: nil, bundle: Bundle.frameworkBundle())
        self.initialization()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("This class doesn't support NSCoding.")
    }
    
    /**
     Common Initialization
     */
    fileprivate func initialization() {
        
        if (self.readerConfig.hideBars == true) {
            self.pageIndicatorHeight = 0
        }
        
        self.totalPages = book.spine.spineReferences.count
        
        // Loading indicator
        let style: UIActivityIndicatorView.Style = folioReader.isNight(.white, .gray)
        loadingView = UIActivityIndicatorView(activityIndicatorStyle: style)
        loadingView.hidesWhenStopped = true
        loadingView.startAnimating()

        self.view.addSubview(loadingView)
    }
    
    func getColor() -> UIColor {
        if folioReader.milkMode {
            return self.readerConfig.milkModeBackground
        } else {
            if folioReader.nightMode {
                return self.readerConfig.nightModeBackground
            } else {
                return UIColor.white
            }
        }
    }
    
    // MARK: - View life cicle
    
    func updateColors() {
        let background = getColor()
        self.view.backgroundColor = background
        self.collectionView.backgroundColor = background
        self.currentPage?.updateColors()
    }
    
    @objc open func refreshPageMode() {
        updateColors()
        needScrollOffset = true
        reloadData()
    }
    
    @objc func applicationDidBecomeActive() {
        needScrollOffset = true
        reloadData()
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()

        if #available(iOS 9.0, *) {
            UIView.appearance().semanticContentAttribute = .forceLeftToRight
        }
        
        screenBounds = self.view.frame
        setPageSize(UIApplication.shared.statusBarOrientation)
        
        collectionViewLayout.sectionInset = UIEdgeInsets.zero
        collectionViewLayout.minimumLineSpacing = 0
        collectionViewLayout.minimumInteritemSpacing = 0
        collectionViewLayout.scrollDirection = .direction(withConfiguration: self.readerConfig)
        collectionViewLayout.itemSize = CGSize(width: screenBounds.width, height: screenBounds.height)

        // CollectionView
        collectionView = UICollectionView(frame: screenBounds, collectionViewLayout: collectionViewLayout)
        
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.isPagingEnabled = true
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.decelerationRate = UIScrollViewDecelerationRateFast
        enableScrollBetweenChapters(scrollEnabled: true)
        view.addSubview(collectionView)

        updateColors()
        NotificationCenter.default.addObserver(self, selector: #selector(refreshPageMode), name: NSNotification.Name(rawValue: "needRefreshPageMode"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(willResignActive), name: NSNotification.Name.UIApplicationWillResignActive, object: nil)

        // Activity Indicator
        self.activityIndicator.activityIndicatorViewStyle = .gray
        self.activityIndicator.hidesWhenStopped = true
        self.activityIndicator = UIActivityIndicatorView(frame: CGRect(x: self.view.frame.width/2, y: self.view.frame.height/2, width: 30, height: 30))
        self.activityIndicator.backgroundColor = UIColor.gray
        self.view.addSubview(self.activityIndicator)
        self.view.bringSubview(toFront: self.activityIndicator)
        
        if #available(iOS 10.0, *) {
            collectionView.isPrefetchingEnabled = false
        }
        
        // Register cell classes
        collectionView?.register(FolioReaderPage.self, forCellWithReuseIdentifier: kReuseCellIdentifier)
        
        // Configure navigation / search / progress bars & book title view and layout
        automaticallyAdjustsScrollViewInsets = false
        extendedLayoutIncludesOpaqueBars = true
        configureNavBar()
        configureBookTitleView()
        configureProgressBar()
        configureSearchBar()
        configurePopUpView()
        
        // Page indicator view
        if (self.readerConfig.hidePageIndicator == false) {
            let frame = self.frameForPageIndicatorView()
            pageIndicatorView = FolioReaderPageIndicator(frame: frame, readerConfig: readerConfig, folioReader: folioReader)
            if let pageIndicatorView = pageIndicatorView {
                view.addSubview(pageIndicatorView)
            }
        }
        
        guard let readerContainer = readerContainer else { return }
        self.scrollScrubber = ScrollScrubber(frame: frameForScrollScrubber(), withReaderContainer: readerContainer)
        self.scrollScrubber?.delegate = self
        if let scrollScrubber = scrollScrubber {
            view.addSubview(scrollScrubber.slider)
        }
        
        readerProgressManager = ReaderProgressManager(folioReader: folioReader)
        if #available(iOS 9.0, *) {
            view.semanticContentAttribute = .forceLeftToRight
            collectionView.semanticContentAttribute = .forceLeftToRight
            scrollScrubber?.slider.semanticContentAttribute = .forceLeftToRight
        }
 
    }
    
    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Update pages
        if needReload == false {
            pagesForCurrentPage(currentPage)
            pageIndicatorView?.reloadView(updateShadow: true)
        }
        
        if tutorialDidShow {
            readerProgressManager?.clearAndUpdateIfNeeded()
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
    }
    

    
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if needReload == true {
            needReload = false
            reloadData()
        }
    }
    
    override open func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        screenBounds = view.frame
        loadingView.center = view.center
        
        setPageSize(UIApplication.shared.statusBarOrientation)
        updateSubviewFrames()
    }
    
    // MARK: Layout
    
    /**
     Enable or disable the scrolling between chapters (`FolioReaderPage`s). If this is enabled it's only possible to read the current chapter. If another chapter should be displayed is has to be triggered programmatically with `changePageWith`.
     
     - parameter scrollEnabled: `Bool` which enables or disables the scrolling between `FolioReaderPage`s.
     */
    open func enableScrollBetweenChapters(scrollEnabled: Bool) {
        self.collectionView.isUserInteractionEnabled = scrollEnabled
    }
    
    fileprivate func updateSubviewFrames() {
        self.pageIndicatorView?.frame = self.frameForPageIndicatorView()
        self.scrollScrubber?.frame = self.frameForScrollScrubber()
        self.navBarView?.frame = frameNavBarView()
        self.bookTitleView?.frame = frameBookTitleView()
        self.progressView?.frame = frameProgressView()
        self.popUpView?.frame = framePopUpView()
    }
    
    fileprivate func frameNavBarView() -> CGRect {
        var y: CGFloat = 0.0
        var height: CGFloat = 44.0
        if UIDevice().userInterfaceIdiom == .phone {
            if UIScreen.main.nativeBounds.height == 1624.0 ||
                UIScreen.main.nativeBounds.height == 2436.0 {
                y = 0.0
                height = 84.0
            }
        }
         return CGRect(x: 0, y: y, width: self.view.frame.width, height: height)
    }
    
    fileprivate func frameProgressView() -> CGRect {
        return CGRect(x: 0, y: view.frame.height - 60, width: self.view.frame.width, height: 60)
    }
    
    fileprivate func frameBookTitleView() -> CGRect {
        var y: CGFloat = 44.0
        if UIDevice().userInterfaceIdiom == .phone {
            if UIScreen.main.nativeBounds.height == 1624.0 ||
                UIScreen.main.nativeBounds.height == 2436.0 {
                y = 84.0
            }
        }
        return CGRect(x: 0, y: y, width: self.view.frame.width, height: 26)
    }

    fileprivate func frameForPageIndicatorView() -> CGRect {
        return CGRect(x: 0, y: view.frame.height-pageIndicatorHeight, width: view.frame.width, height: pageIndicatorHeight)
    }
    
    fileprivate func frameForScrollScrubber() -> CGRect {
        let scrubberY: CGFloat = ((self.readerConfig.shouldHideNavigationOnTap == true || self.readerConfig.hideBars == true) ? 50 : 74)
        return CGRect(x: self.pageWidth + 10, y: scrubberY, width: 40, height: (self.pageHeight - 100))
    }
    
    fileprivate func framePopUpView() -> CGRect {
        return CGRect(x: UIScreen.main.bounds.width/2 - 125, y: 188, width: 250, height: 250)
    }
    
    
    private func transformViewForRTL(_ view: UIView?) {
        if view?.transform.isIdentity == true {
            view?.transform = CGAffineTransform(scaleX: -1, y: 1)
        } else {
            view?.transform = CGAffineTransform.identity
        }
    }
    
    func setCollectionViewProgressiveDirection() {
        if collectionView.transform.isIdentity == true {
            transformViewForRTL(collectionView)
        }
    }
    
    func setPageProgressiveDirection(_ page: FolioReaderPage) {
        if page.transform.isIdentity == true {
            transformViewForRTL(page)
        }
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            keyboardHeight = keyboardSize.height
            currentPage?.webView.setupNoteFrame(keyboardHeight: keyboardHeight)
        }
    }
    
    func configureNavBar() {
        navBarView = ReaderNavBar.instanceFromNib()
        navBarView?.folioReaderCenter = self
        navBarView?.frame.size.width = view.frame.width
    }
    
    func configureBookTitleView() {
        bookTitleView = ReaderBookTitleBar.instanceFromNib()
        bookTitleView?.bookTitle.text = readerConfig.bookTitle
        bookTitleView?.folioReaderCenter = self
        bookTitleView?.frame = CGRect(x: 0, y: 64, width: self.view.frame.width, height: 26)
    }
    
    func configureProgressBar() {
        progressView = ReaderProgress.instanceFromNib()
        progressView?.folioReaderCenter = self
        progressView?.addObservers()
        progressView?.frame = CGRect(x: 0, y: view.frame.height - 60, width: self.view.frame.width, height: 59)
    }
    
    func configureSearchBar() {
        searchBar = ReaderSearchBar.instanceFromNib()
        searchBar?.folioReaderCenter = self
        searchBar?.frame = CGRect(x: 0, y: bookTitleView?.frame.maxY ?? 60.0, width: self.view.frame.width, height: 40)
    }
    
    func configurePopUpView() {
        popUpView = PopUpView.instanceFromNib()
        popUpView?.folioReaderCenter = self
        popUpView?.popUpView.layer.borderWidth = 1
        popUpView?.popUpView.layer.borderColor = UIColor.black.cgColor
        popUpView?.frame = CGRect(x: UIScreen.main.bounds.width/2 - 125, y: 188, width: 250, height: 250)
    }
    
    @objc func willResignActive() {
        collectionView.alpha = 0.0
    }
    
    func reloadData() {
        self.loadingView.stopAnimating()
        self.totalPages = (self.book.spine.spineReferences.count ?? 0)
        
        self.collectionView.reloadData()
        // Send notification to show tutorial
        if tutorialDidShow == false, UserDefaults.standard.integer(forKey: "openBookCount") < 3 {
            sendTutorialNotification()
        } else {
            readerProgressManager?.clearAndUpdateIfNeeded()
        }
        setCollectionViewProgressiveDirection()
        if let currentPage = currentPage {
         self.setPageProgressiveDirection(currentPage)
        }
        collectionView.alpha = 1.0

        guard
            let bookId = self.book.name,
            let position = folioReader.savedPositionForCurrentBook as? NSDictionary,
            let pageNumber = position["pageNumber"] as? Int,
            (pageNumber > 0) else {
                self.currentPageNumber = 1
                progressView?.updateUI()
                return
        }
        
        self.changePageWith(page: pageNumber)
        self.currentPageNumber = pageNumber
//        progressView?.configurateScroll()
//        progressView?.updateUI()
    }
    
    func sendTutorialNotification() {
        if tutorialDidShow { return }
        self.tutorialDidShow = true
        showBars()
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2.5) {
            let navBarStatus = ["NavBarStatus": self.navBarShouldHide]
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "com.app.GetBooksApp.Notification.Name.Reader.launch"),
                                            object: nil,
                                            userInfo: navBarStatus)
        }
    }
    
    //MARK: BookMark Methods
    
    @objc func addBookmark(sender: UIButton) {
        if readerProgressManager?.isLoading == true { return }
        let bookmarks: [Bookmark] = Bookmark.all(withConfiguration: readerConfig, andChapterIndex: currentPageNumber - 1)
        var needCreateBookmark: Bool = true
        var bookmarkForRemove: Bookmark?

        for bookmark in bookmarks {
            guard let width = self.currentPage?.webView.scrollView.contentSize.width,
                let x = self.currentPage?.webView.scrollView.contentOffset.x else { return }
            let currentOffset = round((width-x)/self.pageWidth)
            let bookmarkOffset = round((width * CGFloat(bookmark.pagePositionInChapter))/self.pageWidth)

            let currentPageInChapter = Int(currentOffset)
            let pageInBookmark = Int(bookmarkOffset)
            if currentPageInChapter == pageInBookmark {
                needCreateBookmark = false
                bookmarkForRemove = bookmark
            }
        }
        
        if needCreateBookmark == true {
            saveBookmark()
        } else {
            guard let bookmark = bookmarkForRemove else { return }
            removeBookMark(bookmark)
        }
    }
    
    func saveBookmark() {
        Bookmark.save(self, completion: { [weak self] (error) in
            if let error = error {
                self?.showBookMarkAlert(error.localizedDescription)
            } else {
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "com.app.GetBooksApp.Notification.Name.Book.update"),
                                                object: nil,
                                                userInfo: nil)
                self?.currentPage?.checkBookMarks()
            }
        })

    }
    
    func removeBookMark(_ bookmark: Bookmark) {
        bookmark.remove(withConfiguration: readerConfig) { [weak self] (error) in
            if let error = error {
                self?.showBookMarkAlert(error.localizedDescription)
            } else {
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "com.app.GetBooksApp.Notification.Name.Book.update"),
                                                object: nil,
                                                userInfo: nil)
                self?.currentPage?.checkBookMarks()
            }
        }
    }
    
    func getGuid()-> String? {
        print(self.currentPage?.webView.js("guid()")!)
        return self.currentPage?.webView.js("guid()")!
    }
    
    //TeST
    func showBookMarkAlert(_ message:String){
        let bookMarkAlert = UIAlertView()
        bookMarkAlert.delegate = self
        bookMarkAlert.title = ""
        bookMarkAlert.message = message
        bookMarkAlert.addButton(withTitle: "OK")
        bookMarkAlert.show()
    }
    
    // MARK: Change layout orientation
    
    /// Get internal page offset before layout change
    private func updatePageOffsetRate() {
        guard let currentPage = self.currentPage else {
            return
        }
        
        let pageScrollView = currentPage.webView.scrollView
        let contentSize = pageScrollView.contentSize.forDirection(withConfiguration: self.readerConfig)
        let contentOffset = pageScrollView.contentOffset.forDirection(withConfiguration: self.readerConfig)
        self.pageOffsetRate = (contentSize != 0 ? (contentOffset / contentSize) : 0)
    }
    
    func setScrollDirection(_ direction: FolioReaderScrollDirection) {
        guard let currentPage = self.currentPage else {
            return
        }
        
        let pageScrollView = currentPage.webView.scrollView
        
        // Get internal page offset before layout change
        self.updatePageOffsetRate()
        // Change layout
        self.readerConfig.scrollDirection = direction
        self.collectionViewLayout.scrollDirection = .direction(withConfiguration: self.readerConfig)
        self.currentPage?.setNeedsLayout()
        self.collectionView.collectionViewLayout.invalidateLayout()
        self.collectionView.setContentOffset(frameForPage(self.currentPageNumber).origin, animated: false)
        
        // Page progressive direction
        self.setCollectionViewProgressiveDirection()
        delay(0.2) { self.setPageProgressiveDirection(currentPage) }
        
        /**
         *  This delay is needed because the page will not be ready yet
         *  so the delay wait until layout finished the changes.
         */
        delay(0.1) {
            var pageOffset = (pageScrollView.contentSize.forDirection(withConfiguration: self.readerConfig) * self.pageOffsetRate)
            
            // Fix the offset for paged scroll
            if (self.readerConfig.scrollDirection == .horizontal && self.pageWidth != 0) {
                let page = round(pageOffset / self.pageWidth)
                pageOffset = (page * self.pageWidth)
            }
            
            let pageOffsetPoint = self.readerConfig.isDirection(CGPoint(x: 0, y: pageOffset), CGPoint(x: pageOffset, y: 0), CGPoint(x: 0, y: pageOffset))
            pageScrollView.setContentOffset(pageOffsetPoint, animated: true)
        }
    }
    
    // MARK: Status bar and Navigation bar
    
    func hideBars() {
        guard self.readerConfig.shouldHideNavigationOnTap == true else {
            return
        }
        self.updateBarsStatus(true)
    }
    
    func showBars() {
        self.updateBarsStatus(false)
    }
    
    func toggleBars() {
//        guard self.readerConfig.shouldHideNavigationOnTap == true else {
//            return
//        }

        let shouldHide = !self.navigationController!.isNavigationBarHidden
        self.updateBarsStatus(shouldHide)
    }
    
    private func updateBarsStatus(_ shouldHide: Bool, shouldShowIndicator: Bool = false) {
        guard let readerContainer = readerContainer else { return }
        readerContainer.shouldHideStatusBar = shouldHide

        UIView.animate(withDuration: 0.25, animations: {
//            readerContainer.setNeedsStatusBarAppearanceUpdate()
            if (shouldShowIndicator == true) {
                self.pageIndicatorView?.minutesLabel.alpha = shouldHide ? 0 : 1
            }
        })
        if navBarShouldHide { dismissNavBarView() }
        else { presentNavBarView() }
    }
    
    func presentNavBarView() {
//        UIApplication.shared.isStatusBarHidden = false

        UIView.animate(withDuration: 1.0,
                       delay: 0.0,
                       options: .curveEaseIn,
                       animations: {  },
                       completion: { _ in
                        self.navBarShouldHide = true
                        if let navBarView = self.navBarView {
                            self.view.addSubview(navBarView)
                        }
                        if let bookTitleView = self.bookTitleView {
                            self.view.addSubview(bookTitleView)
                        }
                        
                        if let progressView = self.progressView {
                            self.view.addSubview(progressView)
                        }
        })
    }
    
    func presentSearchBarView() {
        UIView.animate(withDuration: 1.0,
                       delay: 0.0,
                       options: .curveEaseIn,
                       animations: {  },
                       completion: { _ in
                        if self.searchBarShouldHide {
                            self.closeSearch()
                        } else {
                            self.searchBarShouldHide = true
                          self.searchBar?.searchTextFiled.becomeFirstResponder()
                            self.view.addSubview(self.searchBar!)
                        }
        })
    }
    
    func presentPopUpView() {
        if navBarShouldHide { return }
        UIView.animate(withDuration: 0.3,
                       delay: 0.0,
                       options: .curveEaseIn,
                       animations: {  },
                       completion: { _ in
                        if let popUpView = self.popUpView {
                            self.view.addSubview(popUpView)
                        }
        })
    }
    
    func closePopUpView() {
        popUpShouldHide = false
        self.popUpView?.removeFromSuperview()
    }
    
    func closeSearch() {
        self.searchBarShouldHide = false
        self.searchBar?.searchTextFiled.text = ""
        self.searchBar?.searchTextFiled.resignFirstResponder()
        self.searchBar?.removeFromSuperview()
    }
    
    func dismissNavBarView() {
        UIView.animate(withDuration: 1.0,
                       delay: 0.0,
                       options: .curveEaseOut,
                       animations: { },
                       completion: { _ in
                        self.navBarShouldHide = false
                        self.searchBar?.searchTextFiled.resignFirstResponder()
                        self.navBarView?.removeFromSuperview()
                        self.progressView?.removeFromSuperview()
                        self.bookTitleView?.removeFromSuperview()
                        self.closeSearch()
//                        UIApplication.shared.isStatusBarHidden = true
//                        self.readerContainer?.setNeedsStatusBarAppearanceUpdate()
        })
    }
    
    // MARK: UICollectionViewDataSource
    
    open func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    open func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return totalPages
    }
    
    open func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        var reuseableCell = collectionView.dequeueReusableCell(withReuseIdentifier: kReuseCellIdentifier, for: indexPath) as? FolioReaderPage
        return self.configure(readerPageCell: reuseableCell, atIndexPath: indexPath)
    }
    
    private func configure(readerPageCell cell: FolioReaderPage?, atIndexPath indexPath: IndexPath) -> UICollectionViewCell {
        collectionView.isUserInteractionEnabled = false
        collectionView.alpha = 0.0
        
        guard let cell = cell, let readerContainer = readerContainer else {
            return UICollectionViewCell()
        }
        self.newChpt = indexPath.row
        print("New cell \(indexPath.row)")
        cell.setup(withReaderContainer: readerContainer, folioReader: folioReader)
        cell.pageNumber = indexPath.row+1
        cell.webView.scrollView.delegate = self
        cell.webView.setupScrollDirection()
        cell.webView.frame = folioReader.webViewFrame()
        cell.delegate = self
        cell.backgroundColor = .clear
        
        setPageProgressiveDirection(cell)
        cell.bookMarkButton.addTarget(self, action:#selector(addBookmark), for: .touchUpInside)

        // Configure the cell
        guard let resource = self.book.spine.spineReferences[indexPath.row].resource,
            var html = try? String(contentsOfFile: resource.fullHref, encoding: String.Encoding.utf8) else {
                return cell
        }
        
        let mediaOverlayStyleColors = "\"\(self.readerConfig.mediaOverlayColor.hexString(false))\", \"\(self.readerConfig.mediaOverlayColor.highlightColor().hexString(false))\""

        // Inject CSS
        let jsFilePath = Bundle.frameworkBundle().path(forResource: "Bridge", ofType: "js")
        let cssFilePath = folioReader.styleCss
        let cssTag = "<link rel=\"stylesheet\" type=\"text/css\" href=\"\(cssFilePath)\">"
        let jsTag = "<script type=\"text/javascript\" src=\"\(jsFilePath!)\"></script>" +
        "<script type=\"text/javascript\">setMediaOverlayStyleColors(\(mediaOverlayStyleColors))</script>"

        let toInject = "\n\(cssTag)\n\(jsTag)\n</head>"
        html = html.replacingOccurrences(of: "</head>", with: toInject)

        // Font class name
        var classes = folioReader.currentFont.cssIdentifier
        classes += " " + folioReader.currentMediaOverlayStyle.className()


        if folioReader.milkMode {
            classes += " milkMode"
        } else if folioReader.nightMode {
            classes += " nightMode"
        }

        classes += " " + folioReader.currentDisplayMode.className()


        // Font Size
        classes += " \(folioReader.currentFontSize.cssIdentifier)"

        let currentLineHeight = folioReader.currentLineHeight
        switch currentLineHeight {
        case 0:
            classes += " lineHeightOne"
            break
        case 1:
            classes += " lineHeightTwo"
            break
        case 2:
            classes += " lineHeightThree"
            break
        default:
            break
        }


        html = html.replacingOccurrences(of: "<html ", with: "<html class=\"\(classes)\"")
        
        // Let the delegate adjust the html string
        if let modifiedHtmlContent = self.delegate?.htmlContentForPage?(cell, htmlContent: html) {
            html = modifiedHtmlContent
        }
        
        cell.loadHTMLString(html, baseURL: URL(fileURLWithPath: (resource.fullHref as NSString).deletingLastPathComponent))
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: collectionView.frame.height)
    }
    
    // MARK: - Device rotation
    
    override open func willRotate(to toInterfaceOrientation: UIInterfaceOrientation, duration: TimeInterval) {
        super.willRotate(to: toInterfaceOrientation, duration: duration)
        folioReader.saveReaderState()
        collectionView.alpha = 0
        
        if let _ = folioReaderFontsMenu {
            if (folioReaderFontsMenu?.fontsMenuShouldHide)! {
            fontsMenuShouldHide = false
        } else { fontsMenuShouldHide = true }}
        
        guard folioReader.isReaderReady else {
            collectionView.alpha = 1
            return }
        
        setPageSize(toInterfaceOrientation)
        updateCurrentPage()
        
        if self.currentOrientation == nil || (self.currentOrientation?.isPortrait != toInterfaceOrientation.isPortrait) {
            var pageIndicatorFrame = pageIndicatorView?.frame
            pageIndicatorFrame?.origin.y = ((screenBounds.size.height < screenBounds.size.width) ? (self.collectionView.frame.height - pageIndicatorHeight) : (self.collectionView.frame.width - pageIndicatorHeight))
            pageIndicatorFrame?.origin.x = 0
            pageIndicatorFrame?.size.width = ((screenBounds.size.height < screenBounds.size.width) ? (self.collectionView.frame.width) : (self.collectionView.frame.height))
            pageIndicatorFrame?.size.height = pageIndicatorHeight
            
            var scrollScrubberFrame = scrollScrubber?.slider.frame;
            scrollScrubberFrame?.origin.x = ((screenBounds.size.height < screenBounds.size.width) ? (view.frame.width - 100) : (view.frame.height + 10))
            scrollScrubberFrame?.size.height = ((screenBounds.size.height < screenBounds.size.width) ? (self.collectionView.frame.height - 100) : (self.collectionView.frame.width - 100))
            
            self.collectionView.collectionViewLayout.invalidateLayout()
            
            UIView.animate(withDuration: duration, animations: {
                // Adjust page indicator view
                if let pageIndicatorFrame = pageIndicatorFrame {
                    self.pageIndicatorView?.frame = pageIndicatorFrame
                    self.pageIndicatorView?.reloadView(updateShadow: true)
                }
                
                // Adjust scroll scrubber slider
                if let scrollScrubberFrame = scrollScrubberFrame {
                    self.scrollScrubber?.slider.frame = scrollScrubberFrame
                }
                
                // Adjust collectionView
                self.collectionView.contentSize = self.readerConfig.isDirection(
                    CGSize(width: self.pageWidth, height: self.pageHeight * CGFloat(self.totalPages)),
                    CGSize(width: self.pageWidth * CGFloat(self.totalPages), height: self.pageHeight),
                    CGSize(width: self.pageWidth * CGFloat(self.totalPages), height: self.pageHeight)
                )
                self.collectionView.setContentOffset(self.frameForPage(self.currentPageNumber).origin, animated: false)
                self.collectionView.collectionViewLayout.invalidateLayout()
                
                // Adjust internal page offset
                self.updatePageOffsetRate()
            })
        }
        self.currentOrientation = toInterfaceOrientation
    }
    
    override open func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
        super.didRotate(from: fromInterfaceOrientation)
        progressView?.frame = CGRect(x: 0, y: view.frame.height - 60, width: self.view.frame.width, height: 60)
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "com.app.GetBooksApp.Notification.Name.Progress.update"),
                                        object: nil,
                                        userInfo: nil)

        searchBar?.frame = CGRect(x: 0, y: bookTitleView?.frame.maxY ?? 60.0, width: self.view.frame.width, height: 40)
        if !fontsMenuShouldHide { navBarShouldHide = true; presentFontsMenu() }
        guard folioReader.isReaderReady == true, let currentPage = currentPage else {
            collectionView.alpha = 1
            return
        }
        progressView?.configurateScroll()
        // Update pages
        pagesForCurrentPage(currentPage)
        currentPage.refreshPageMode()
        
        scrollScrubber?.setSliderVal()
        
        // After rotation fix internal page offset
        var pageOffset = (currentPage.webView.scrollView.contentSize.forDirection(withConfiguration: self.readerConfig) * pageOffsetRate)
        
        // Fix the offset for paged scroll
        if (self.readerConfig.scrollDirection == .horizontal && self.pageWidth != 0) {
            let page = round(pageOffset / self.pageWidth)
            pageOffset = page * self.pageWidth
        }
        
        let pageOffsetPoint = self.readerConfig.isDirection(CGPoint(x: 0, y: pageOffset), CGPoint(x: pageOffset, y: 0), CGPoint(x: 0, y: pageOffset))
        currentPage.webView.scrollView.setContentOffset(pageOffsetPoint, animated: true)
        currentPage.checkBookMarks()
        currentPage.webView.hiddenMenu()
        currentPage.webView.isUserInteractionEnabled = false
        currentPage.webView.isUserInteractionEnabled = true

        collectionView.alpha = 1
        needScrollAfterRotation = true
        reloadData()
    }
    
    override open func willAnimateRotation(to toInterfaceOrientation: UIInterfaceOrientation, duration: TimeInterval) {
        super.willAnimateRotation(to: toInterfaceOrientation, duration: duration)
        guard folioReader.isReaderReady else {
            return
        }
        
        self.collectionView.scrollToItem(at: IndexPath(row: self.currentPageNumber - 1, section: 0), at: UICollectionView.ScrollPosition(), animated: false)
        if (self.currentPageNumber + 1) >= totalPages {
            UIView.animate(withDuration: duration, animations: {
                self.collectionView.setContentOffset(self.frameForPage(self.currentPageNumber).origin, animated: false)
            })
        }
    }
    
    // MARK: - Page
    
    func setPageSize(_ orientation: UIInterfaceOrientation) {
        guard orientation.isPortrait else {
            if screenBounds.size.width > screenBounds.size.height {
                self.pageWidth = self.view.frame.width
                self.pageHeight = self.view.frame.height
            } else {
                self.pageWidth = self.view.frame.height
                self.pageHeight = self.view.frame.width
            }
            return
        }
        
        if screenBounds.size.width < screenBounds.size.height {
            self.pageWidth = self.view.frame.width
            self.pageHeight = self.view.frame.height
        } else {
            self.pageWidth = self.view.frame.height
            self.pageHeight = self.view.frame.width
        }
    }
    
    func updateCurrentPage(_ page: FolioReaderPage? = nil, completion: (() -> Void)? = nil) {
        if let page = page {
            currentPage = page
            self.previousPageNumber = page.pageNumber-1
            self.currentPageNumber = page.pageNumber
        } else {
            let currentIndexPath = getCurrentIndexPath()
            currentPage = collectionView.cellForItem(at: currentIndexPath) as? FolioReaderPage
            
            if goToPagePositionInChapter != nil {
                collectionView?.alpha = 0.0
            }
            self.currentPageNumber =  currentIndexPath.row + 1
            self.previousPageNumber = currentIndexPath.row
        }
        
        self.nextPageNumber = (((self.currentPageNumber + 1) <= totalPages) ? (self.currentPageNumber + 1) : self.currentPageNumber)
        
        // Set pages
        guard let currentPage = currentPage else {
            completion?()
            return
        }
        
        scrollScrubber?.setSliderVal()
        
        if let readingTime = currentPage.webView.js("getReadingTime()") {
            pageIndicatorView?.totalMinutes = Int(readingTime)!
        } else {
            pageIndicatorView?.totalMinutes = 0
        }
        delay(0.1) { [weak self] in
            self?.pagesForCurrentPage(currentPage)
        }
        
        delegate?.pageDidAppear?(currentPage)
        
        completion?()
    }
    
    func pagesForCurrentPage(_ page: FolioReaderPage?) {
        guard let page = page else { return }
        
        let pageSize = self.readerConfig.isDirection(pageHeight, self.pageWidth, pageHeight)
        let contentSize = page.webView.scrollView.contentSize.forDirection(withConfiguration: self.readerConfig)
        self.pageIndicatorView?.totalPages = ((pageSize != 0) ? Int(ceil(contentSize / pageSize)) : 0)
        
        let pageOffSet = self.readerConfig.isDirection(page.webView.scrollView.contentOffset.x, page.webView.scrollView.contentOffset.x, page.webView.scrollView.contentOffset.y)
        let webViewPage = pageForOffset(pageOffSet, pageHeight: pageSize)
        
        self.pageIndicatorView?.currentPage = webViewPage
    }
    
    open func pageForOffset(_ offset: CGFloat, pageHeight height: CGFloat) -> Int {
        guard (height != 0) else {
            return 0
        }
        
        let page = Int(ceil(offset / height))+1
        return page
    }
    
    func getCurrentIndexPath() -> IndexPath {
        let indexPaths = collectionView.indexPathsForVisibleItems
        var indexPath = IndexPath()
        
        if indexPaths.count > 1 {
            let first = indexPaths.first!
            let last = indexPaths.last!
            
            switch self.pageScrollDirection {
            case .up, .left:
                if first.compare(last) == .orderedAscending {
                    indexPath = last
                } else {
                    indexPath = first
                }
            default:
                if first.compare(last) == .orderedAscending {
                    indexPath = first
                } else {
                    indexPath = last
                }
            }
        } else {
            indexPath = indexPaths.first ?? IndexPath(row: 0, section: 0)
        }
        
        return indexPath
    }
    
    func frameForPage(_ page: Int) -> CGRect {
        return self.readerConfig.isDirection(
            CGRect(x: 0, y: self.pageHeight * CGFloat(page-1), width: self.pageWidth, height: self.pageHeight),
            CGRect(x: self.pageWidth * CGFloat(page-1), y: 0, width: self.pageWidth, height: self.pageHeight),
            CGRect(x: 0, y: self.pageHeight * CGFloat(page-1), width: self.pageWidth, height: self.pageHeight)
        )
    }
    
    func goToBookMark(bookmark: BookmarkStruct) {
        goToPagePositionInChapter = bookmark.pagePositionInChapter
        if (self.currentPageNumber - 1) == bookmark.chapterIndex, currentPage != nil {
            self.currentPage?.goTo(pagePositionInChapter: bookmark.pagePositionInChapter)
            goToPagePositionInChapter = nil
            delay(0.2) { [weak self] in
                self?.currentPage?.checkBookMarks()
            }
        } else {
            collectionView?.alpha = 0.0
            changePageWith(page: bookmark.chapterIndex + 1, animated: false, completion: { [weak self] () -> Void in
                self?.updateCurrentPage()
            })
        }
    }
    
    func changePageTo(chapter: Int, page: Int) {
        if self.currentPageNumber == chapter, currentPage != nil {
            self.currentPage?.goTo(chapterPage: page)
            delay(0.2) { [weak self] in
                self?.currentPage?.checkBookMarks()
            }
        } else {
            collectionView?.alpha = 0.0
            scrolltoPage = page
            changePageWith(page: chapter, animated: false, completion: { [weak self] () -> Void in
                self?.updateCurrentPage()
            })
        }
    }
    
    func changePageWith(page: Int, andFragment fragment: String, isNoteExist: Bool, animated: Bool = false, isScrool: Bool? = nil, completion: (() -> Void)? = nil) {
        
        if (self.currentPageNumber == page) {
            if fragment != "" && currentPage != nil {
                self.currentPage?.handleAnchor(fragment, avoidBeginningAnchors: false, animated: animated)
                delay(0.2) {
                    self.currentPage?.checkBookMarks()
                }
                if (completion != nil) { completion!() }
            }
        } else {
            collectionView?.alpha = 0.0
            tempFragment = fragment
            changePageWith(page: page, animated: animated, completion: { () -> Void in
                self.updateCurrentPage {
                    completion?()
                }
            })
        }
    }
    
    func changePageWith(href: String, animated: Bool = false, completion: (() -> Void)? = nil) {
        let item = findPageByHref(href)
        let indexPath = IndexPath(row: item, section: 0)
        changePageWith(indexPath: indexPath, animated: animated, completion: { () -> Void in
            self.updateCurrentPage {
                completion?()
            }
        })
    }
    
    func changePageWith(href: String, andAudioMarkID markID: String) {
        if recentlyScrolled { return } // if user recently scrolled, do not change pages or scroll the webview
        guard let currentPage = currentPage else { return }
        
        let item = findPageByHref(href)
        let pageUpdateNeeded = item+1 != currentPage.pageNumber
        let indexPath = IndexPath(row: item, section: 0)
        changePageWith(indexPath: indexPath, animated: false) { () -> Void in
            if pageUpdateNeeded {
                self.updateCurrentPage {
                    currentPage.audioMarkID(markID)
                }
            } else {
                currentPage.audioMarkID(markID)
            }
        }
    }
    
    func changePageWith(indexPath: IndexPath, animated: Bool = false, completion: (() -> Void)? = nil) {
        guard indexPathIsValid(indexPath) else {
            print("ERROR: Attempt to scroll to invalid index path")
            completion?()
            return
        }
        
        UIView.animate(withDuration: animated ? 0.3 : 0, delay: 0, options: UIView.AnimationOptions(), animations: { () -> Void in
            self.collectionView.scrollToItem(at: indexPath, at: .direction(withConfiguration: self.readerConfig), animated: false)
        }) { (finished: Bool) -> Void in
            completion?()
        }
    }
    
    func indexPathIsValid(_ indexPath: IndexPath) -> Bool {
        let section = indexPath.section
        let row = indexPath.row
        let lastSectionIndex = numberOfSections(in: collectionView) - 1
        
        //Make sure the specified section exists
        if section > lastSectionIndex {
            return false
        }
        
        let rowCount = self.collectionView(collectionView, numberOfItemsInSection: indexPath.section) - 1
        return row <= rowCount
    }
    
    func isLastPage() -> Bool{
        return (currentPageNumber == self.nextPageNumber)
    }
    
    func changePageToNext(_ completion: (() -> Void)? = nil) {
        changePageWith(page: self.nextPageNumber, animated: true) { () -> Void in
            completion?()
        }
    }
    
    func changePageToPrevious(_ completion: (() -> Void)? = nil) {
        changePageWith(page: self.previousPageNumber, animated: true) { () -> Void in
            completion?()
        }
    }
    
    /**
     Find a page by FRTocReference.
     */
    func findPageByResource(_ reference: FRTocReference) -> Int {
        var count = 0
        for item in self.book.spine.spineReferences {
            if let resource = reference.resource, item.resource == resource {
                return count
            }
            count += 1
        }
        return count
    }
    
    /**
     Find a page by href.
     */
    func findPageByHref(_ href: String) -> Int {
        var count = 0
        for item in self.book.spine.spineReferences {
            if item.resource.href == href {
                return count
            }
            count += 1
        }
        return count
    }
    
    /**
     Find and return the current chapter resource.
     */
    func getCurrentChapter() -> FRResource? {
        for item in self.book.flatTableOfContents {
            if
                let reference = self.book.spine.spineReferences[safe: (self.currentPageNumber - 1)],
                let resource = item.resource,
                (resource == reference.resource) {
                return item.resource
            }
        }
        return nil
    }
    
    /**
     Find and return the index if chapter.
     */
    func getCurrentChapterIndex() -> Int {
        for (index, item) in self.book.flatTableOfContents.enumerated() {
            if
                let reference = self.book.spine.spineReferences[safe: (self.currentPageNumber - 1)],
                let resource = item.resource,
                (resource == reference.resource) {
                return index + 1
            }
        }
        return 0
    }
    
    /**
     Find and return the current chapter name.
     */
    func getCurrentChapterName() -> String? {
        for item in self.book.flatTableOfContents {
            guard
                let reference = self.book.spine.spineReferences[safe: (self.currentPageNumber - 1)],
                let resource = item.resource,
                (resource == reference.resource),
                let title = item.title else {
                    continue
            }
            
            return title
        }
        
        return nil
    }
    
    // MARK: Public page methods
    
    /**
     Changes the current page of the reader.
     
     - parameter page: The target page index. Note: The page index starts at 1 (and not 0).
     - parameter animated: En-/Disables the animation of the page change.
     - parameter completion: A Closure which is called if the page change is completed.
     */
    open func changePageWith(page: Int, animated: Bool = false, completion: (() -> Void)? = nil) {
        if page > 0 && page-1 < totalPages {
            let indexPath = IndexPath(row: page-1, section: 0)
            changePageWith(indexPath: indexPath, animated: animated, completion: { () -> Void in
                self.updateCurrentPage {
                    completion?()
                }
            })
        }
    }
    
    // MARK: - Audio Playing
    
    func audioMark(href: String, fragmentID: String) {
        changePageWith(href: href, andAudioMarkID: fragmentID)
    }
    
    // MARK: - Sharing
    
    /**
     Sharing chapter method.
     */
    func shareChapter(_ sender: UIBarButtonItem) {
        guard let currentPage = currentPage else { return }
        
        if let chapterText = currentPage.webView.js("getBodyText()") {
            let htmlText = chapterText.replacingOccurrences(of: "[\\n\\r]+", with: "<br />", options: .regularExpression)
            var subject = readerConfig.localizedShareChapterSubject
            var html = ""
            var text = ""
            var bookTitle = ""
            var chapterName = ""
            var authorName = ""
            var shareItems = [AnyObject]()
            
            // Get book title
            if let title = self.book.title() {
                bookTitle = title
                subject += " “\(title)”"
            }
            
            // Get chapter name
            if let chapter = getCurrentChapterName() {
                chapterName = chapter
            }
            
            // Get author name
            if let author = self.book.metadata.creators.first {
                authorName = author.name
            }
            
            // Sharing html and text
            html = "<html><body>"
            html += "<br /><hr> <p>\(htmlText)</p> <hr><br />"
            html += "<center><p style=\"color:gray\">"+readerConfig.localizedShareAllExcerptsFrom+"</p>"
            html += "<b>\(bookTitle)</b><br />"
            html += readerConfig.localizedShareBy+" <i>\(authorName)</i><br />"
            
            if let bookShareLink = readerConfig.localizedShareWebLink {
                html += "<a href=\"\(bookShareLink.absoluteString)\">\(bookShareLink.absoluteString)</a>"
                shareItems.append(bookShareLink as AnyObject)
            }
            
            html += "</center></body></html>"
            text = "\(chapterName)\n\n“\(chapterText)” \n\n\(bookTitle) \n\(readerConfig.localizedShareBy) \(authorName)"
            
            let act = FolioReaderSharingProvider(subject: subject, text: text, html: html)
            shareItems.insert(contentsOf: [act, "" as AnyObject], at: 0)
            
            let activityViewController = UIActivityViewController(activityItems: shareItems, applicationActivities: nil)
            activityViewController.excludedActivityTypes = [UIActivity.ActivityType.print, UIActivity.ActivityType.postToVimeo]
            
            // Pop style on iPad
            if let actv = activityViewController.popoverPresentationController {
                actv.barButtonItem = sender
            }
            
            present(activityViewController, animated: true, completion: nil)
        }
    }
    
    /**
     Sharing highlight method.
     */
    func shareHighlight(_ string: String, rect: CGRect) {
        var subject = readerConfig.localizedShareHighlightSubject
        var html = ""
        var text = ""
        var bookTitle = ""
        var chapterName = ""
        var authorName = ""
        var shareItems = [AnyObject]()
        
        // Get book title
        if let title = self.book.title() {
            bookTitle = title
            subject += " “\(title)”"
        }
        
        // Get chapter name
        if let chapter = getCurrentChapterName() {
            chapterName = chapter
        }
        
        // Get author name
        if let author = self.book.metadata.creators.first {
            authorName = author.name
        }
        
        // Sharing html and text
        html = "<html><body>"
        html += "<br /><hr> <p>\(chapterName)</p>"
        html += "<p>\(string)</p> <hr><br />"
        html += "<center><p style=\"color:gray\">"+readerConfig.localizedShareAllExcerptsFrom+"</p>"
        html += "<b>\(bookTitle)</b><br />"
        html += readerConfig.localizedShareBy+" <i>\(authorName)</i><br />"
        
        if let bookShareLink = readerConfig.localizedShareWebLink {
            html += "<a href=\"\(bookShareLink.absoluteString)\">\(bookShareLink.absoluteString)</a>"
            shareItems.append(bookShareLink as AnyObject)
        }
        
        html += "</center></body></html>"
        text = "\(chapterName)\n\n“\(string)” \n\n\(bookTitle) \n\(readerConfig.localizedShareBy) \(authorName)"
        
        let act = FolioReaderSharingProvider(subject: subject, text: text, html: html)
        shareItems.insert(contentsOf: [act, "" as AnyObject], at: 0)
        
        let activityViewController = UIActivityViewController(activityItems: shareItems, applicationActivities: nil)
        activityViewController.excludedActivityTypes = [UIActivity.ActivityType.print, UIActivity.ActivityType.postToVimeo]
        
        // Pop style on iPad
        if let actv = activityViewController.popoverPresentationController {
            actv.sourceView = currentPage
            actv.sourceRect = rect
        }
        
        present(activityViewController, animated: true, completion: nil)
    }
    
    // MARK: - ScrollView Delegate
    
    open func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        let isCollectionScrollView = (scrollView is UICollectionView)

        lastContentOffset = scrollView.contentOffset
        self.isScrolling = true
        clearRecentlyScrolled()
        recentlyScrolled = true
        pointNow = scrollView.contentOffset
//
//        if (scrollView is UICollectionView) {
//            scrollView.isUserInteractionEnabled = false
//        }
        
        if let currentPage = currentPage {
            currentPage.webView.createMenu(options: true)
            currentPage.webView.setMenuVisible(false)
            currentPage.bookMarkButton.isHidden = true
        }
        
        scrollScrubber?.scrollViewWillBeginDragging(scrollView)
    }
    
    var lastOffset:CGPoint? = CGPoint(x: 0, y: 0)
    var lastOffsetCapture:TimeInterval? = 0
    var isScrollingFast: Bool = false
    
    open func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        let currentOffset = scrollView.contentOffset
        let currentTime = NSDate().timeIntervalSinceReferenceDate
        let timeDiff = currentTime - lastOffsetCapture!
        let captureInterval = 0.1
        
        if(timeDiff > captureInterval) {
            
            let distance = currentOffset.y - lastOffset!.y     // calc distance
            let scrollSpeedNotAbs = (distance * 10) / 1000     // pixels per ms*10
            let scrollSpeed = fabsf(Float(scrollSpeedNotAbs))  // absolute value
            
            if (scrollSpeed > 0.3) {
                isScrollingFast = true
                return
            }
            else {
                isScrollingFast = false
                print("Slow")
            }
            
            lastOffset = currentOffset
            lastOffsetCapture = currentTime
            
        }
        
        if (navigationController?.isNavigationBarHidden == false) {
            self.toggleBars()
        }
        
        scrollScrubber?.scrollViewDidScroll(scrollView)
        
        let isCollectionScrollView = (scrollView is UICollectionView)
        let scrollType: ScrollType = ((isCollectionScrollView == true) ? .chapter : .page)
        // Update current reading page
        if (isCollectionScrollView == false), let page = currentPage {
            
            let pageSize = self.readerConfig.isDirection(self.pageHeight, self.pageWidth, self.pageHeight)
            let contentOffset = page.webView.scrollView.contentOffset.forDirection(withConfiguration: self.readerConfig)
            let contentSize = page.webView.scrollView.contentSize.forDirection(withConfiguration: self.readerConfig)
            if (contentOffset + pageSize <= contentSize) {
                
                let webViewPage = pageForOffset(contentOffset, pageHeight: pageSize)
                
                if (readerConfig.scrollDirection == .horizontalWithVerticalContent) {
                    let currentIndexPathRow = (page.pageNumber - 1)
                    
                    // if the cell reload doesn't save the top position offset
                    if let oldOffSet = self.currentWebViewScrollPositions[currentIndexPathRow], (abs(oldOffSet.y - scrollView.contentOffset.y) > 100) {
                        // Do nothing
                    } else {
                        self.currentWebViewScrollPositions[currentIndexPathRow] = scrollView.contentOffset
                    }
                }
                
                if (pageIndicatorView?.currentPage != webViewPage) {
                    pageIndicatorView?.currentPage = webViewPage
                }
            }
        }
        
        self.updatePageScrollDirection(inScrollView: scrollView, forScrollType: scrollType)
    }
    
    private func updatePageScrollDirection(inScrollView scrollView: UIScrollView, forScrollType scrollType: ScrollType) {
        
        let scrollViewContentOffsetForDirection = scrollView.contentOffset.forDirection(withConfiguration: self.readerConfig, scrollType: scrollType)
        let pointNowForDirection = pointNow.forDirection(withConfiguration: self.readerConfig, scrollType: scrollType)
        // The movement is either positive or negative. This happens if the page change isn't completed. Toggle to the other scroll direction then.
        let isCurrentlyPositive = (self.pageScrollDirection == .left || self.pageScrollDirection == .up)
        
        if (scrollViewContentOffsetForDirection < pointNowForDirection) {
            self.pageScrollDirection = .negative(withConfiguration: self.readerConfig, scrollType: scrollType)
        } else if (scrollViewContentOffsetForDirection > pointNowForDirection) {
            self.pageScrollDirection = .positive(withConfiguration: self.readerConfig, scrollType: scrollType)
        } else if (isCurrentlyPositive == true) {
            self.pageScrollDirection = .negative(withConfiguration: self.readerConfig, scrollType: scrollType)
        } else {
            self.pageScrollDirection = .positive(withConfiguration: self.readerConfig, scrollType: scrollType)
        }
    }
    
    open func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        self.isScrolling = false
        
//        if (scrollView is UICollectionView) {
//            scrollView.isUserInteractionEnabled = true
//        }
        
        // Perform the page after a short delay as the collection view hasn't completed it's transition if this method is called (the index paths aren't right during fast scrolls).
        delay(0.2, closure: { [weak self] in
            
            if (self?.readerConfig.scrollDirection == .horizontalWithVerticalContent),
                let cell = ((scrollView.superview as? UIWebView)?.delegate as? FolioReaderPage) {
                let currentIndexPathRow = cell.pageNumber - 1
                self?.currentWebViewScrollPositions[currentIndexPathRow] = scrollView.contentOffset
            }
            
            if (scrollView is UICollectionView) {
                if self?.totalPages > 0 {
                    self?.updateCurrentPage()
                }
            } else {
                self?.scrollScrubber?.scrollViewDidEndDecelerating(scrollView)
                delay(0.2) { self?.progressView?.updateUI() }
            }
            self?.currentPage?.bookMarkButton.isHidden = false
            self?.currentPage?.checkBookMarks()
        })
    }
    
    open func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        recentlyScrolledTimer = Timer(timeInterval:recentlyScrolledDelay, target: self, selector: #selector(FolioReaderCenter.clearRecentlyScrolled), userInfo: nil, repeats: false)
        RunLoop.current.add(recentlyScrolledTimer, forMode: RunLoopMode.commonModes)
        if !decelerate
        {
            let currentIndex = floor(scrollView.contentOffset.x / scrollView.bounds.size.width)
            
            let offset = CGPoint(x: scrollView.bounds.size.width * currentIndex, y: 0)
            
            scrollView.setContentOffset(offset, animated: true)
        }
    }
    
    @objc func clearRecentlyScrolled() {
        if(recentlyScrolledTimer != nil) {
            recentlyScrolledTimer.invalidate()
            recentlyScrolledTimer = nil
        }
        recentlyScrolled = false
    }
    
    open func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        scrollScrubber?.scrollViewDidEndScrollingAnimation(scrollView)
    }
    
    
    // MARK: NavigationBar Actions
    
    func closeReader() {
        readerProgressManager?.clear()
        sendStateNotification()
        dismiss()
        folioReader.close()
    }
    
    func sendStateNotification() {
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "com.app.GetBooksApp.Notification.Name.Reader.state"),
                                            object: nil,
                                            userInfo: nil)
    }
    
    
    /**
     Present chapter list
     */
    func presentChapterList() {
        folioReader.saveReaderState()
        
        let chapterStoryboard = UIStoryboard.init(name: "FolioReaderChapterList", bundle: Bundle.frameworkBundle())
        let chapterVC = chapterStoryboard.instantiateViewController(withIdentifier: "FolioReaderChapterList") as! FolioReaderChapterList
        chapterVC.add(folioReader: folioReader, readerConfig: readerConfig, book: book, delegate: self)

        let bookmarkStoryboard = UIStoryboard.init(name: "FolioReaderBookmarkList", bundle: Bundle.frameworkBundle())
        let bookmarkVC = bookmarkStoryboard.instantiateViewController(withIdentifier: "FolioReaderBookmarkList") as! FolioReaderBookmarkList
        bookmarkVC.add(folioReader: folioReader, readerConfig: readerConfig, book: book, delegate: self)
        
        let highlightStoryboard = UIStoryboard.init(name: "FRHighlightList", bundle: Bundle.frameworkBundle())
        let highlightVC = highlightStoryboard.instantiateViewController(withIdentifier: "FRHighlightList") as! FRHighlightList
        highlightVC.add(folioReader: folioReader, readerConfig: readerConfig, book: book, delegate: nil)
        
        let pageController = PageViewController(folioReader: folioReader, readerConfig: readerConfig)
        pageController.viewControllerOne = chapterVC
        pageController.viewControllerTwo = bookmarkVC
        pageController.viewControllerThree = highlightVC
        
        let nav = UINavigationController(rootViewController: pageController)
        nav.setNavigationBarHidden(true, animated: false)
        present(nav, animated: true, completion: nil)
    }

    func presentSearch() {
        presentSearchBarView()
    }
    
    func search(text: String) {
        let characterSet = CharacterSet.init(charactersIn: ".?!")
        let sentens = text.components(separatedBy:characterSet).filter({!$0.isEmpty})
        
        if sentens.count >= 2 {
            UIAlertView.init(title: "GetBooks-Steimatzky", message: "הכנסתם ערך חיפוש גדול מידי. אנא הכניסו ערך לא גדול יותר ממשפט אחד.", delegate: nil, cancelButtonTitle: "בסדר").show()
            return
        }
        
        let storyboard = UIStoryboard.init(name: "FolioReaderSearchViewController", bundle: Bundle.frameworkBundle())
        let searchVC = storyboard.instantiateViewController(withIdentifier: "FolioReaderSearchViewController") as! FolioReaderSearchViewController
        searchVC.add(folioReaderCenter: self)
        searchVC.searchText = text
        let navigation = UINavigationController(rootViewController: searchVC)
        navigation.setNavigationBarHidden(true, animated: false)
        present(navigation, animated: true, completion: nil)
    }
    
    func presentFontsMenu() {
        folioReader.saveReaderState()
        hideBars()
        
        var nibName: String = "ReaderFontsMenuLandscape"
        if UIScreen.main.bounds.size.width < UIScreen.main.bounds.size.height {
            nibName = "ReaderFontsMenu"
        }
        
        folioReaderFontsMenu = FolioReaderFontsMenu(folioReader: self.folioReader, readerConfig: self.readerConfig, readerCenter: self, nib: nibName)
        folioReaderFontsMenu?.modalPresentationStyle = .overCurrentContext
        if let folioReaderFontsMenu = folioReaderFontsMenu {
            self.present(folioReaderFontsMenu, animated: true, completion: nil)
        }
    }

    
    /**
     Present audio player menu
     */
    func presentPlayerMenu(_ sender: UIBarButtonItem) {
        folioReader.saveReaderState()
        hideBars()
        
        let menu = FolioReaderPlayerMenu(folioReader: folioReader, readerConfig: readerConfig)
        menu.modalPresentationStyle = .custom
        
        animator = ZFModalTransitionAnimator(modalViewController: menu)
        animator.isDragable = true
        animator.bounces = false
        animator.behindViewAlpha = 0.4
        animator.behindViewScale = 1
        animator.transitionDuration = 0.6
        animator.direction = ZFModalTransitonDirection.bottom
        
        menu.transitioningDelegate = animator
        present(menu, animated: true, completion: nil)
    }
    
    /**
     Present Quote Share
     */
    func presentQuoteShare(_ string: String) {
        let quoteShare = FolioReaderQuoteShare(initWithText: string, readerConfig: readerConfig, folioReader: folioReader, book: book)
        let nav = UINavigationController(rootViewController: quoteShare)
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            nav.modalPresentationStyle = .formSheet
        }
        present(nav, animated: true, completion: nil)
    }
}

// MARK: FolioPageDelegate

extension FolioReaderCenter: FolioReaderPageDelegate {
    
    func scroll(_ page: FolioReaderPage, offset: CGFloat) {
        if offset > page.webView.scrollView.contentSize.width {
            page.scrollPageToBottom()
        } else {
            page.scrollPageToOffset(offset, animated: false)
            delay(0.2) { [weak self] in
                self?.progressView?.updateUI()
            }
        }

    }
    
    public func pageDidLoad(_ page: FolioReaderPage) {
        updateCurrentPage(page)

        if let bookId = self.book.name,
            let position = folioReader.savedPositionForCurrentBook as? NSDictionary,
            let pageNumber = position["pageNumber"] as? Int,
            var pageOffset = self.readerConfig.isDirection(position["pageOffsetY"], position["pageOffsetX"], position["pageOffsetY"]) as? CGFloat,
            var progressX = position["progressX"] as? CGFloat {

            //TODO: Need sent notification with progress(ProgressManager) + pageNumber

            let progress = readerProgressManager?.persentInteger
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "com.app.GetBooksApp.Notification.Name.Book.half"),
                                            object: nil,
                                            userInfo: ["readProgress": progress, "lastPage": pageNumber])
            
            if isFirstLoad == true {
                //TODO: Если в модели нашей, текущая страница больше, предложить перейти на нее. changePageWith - метод в жтом классе

            }
            
            if (needScrollOffset == true) {
                needScrollOffset = false
                var pageNumber = round((page.webView.scrollView.contentSize.width * progressX) / self.pageWidth)
                pageOffset = pageNumber * self.pageWidth
                scroll(page, offset: pageOffset)

            } else if isFirstLoad || needScrollAfterRotation == true {
                isFirstLoad = false
                needScrollAfterRotation = false
                if (self.readerConfig.scrollDirection == .horizontal && self.pageWidth != 0) {
                    var pageNamber = round((page.webView.scrollView.contentSize.width * progressX) / self.pageWidth)
                    pageOffset = pageNamber * self.pageWidth
                }
                scroll(page, offset: pageOffset)
                self.lastChpt = self.newChpt
            } else if !needScrollOffset && scrolltoPage == nil && goToPagePositionInChapter == nil {
//                delay(0.2) { [weak self, weak page] in
//                    guard let strongSelf = self else { return }
                
                    if self.newChpt > self.lastChpt, !self.needScrollOffset {
                        page.scrollPageToBottom()
                    } else if self.newChpt < self.lastChpt, !self.needScrollOffset {
                        page.scrollPageToTop()
                    }
                    self.lastChpt = self.newChpt
//                }
            }
            
        } else if isFirstLoad || !needScrollOffset {
//            delay(0.2) { [weak self, weak page] in
//                guard let strongSelf = self else { return }
            
                if self.newChpt > self.lastChpt, !self.needScrollOffset {
                    page.scrollPageToBottom()
                } else if self.newChpt < self.lastChpt, !self.needScrollOffset {
                    page.scrollPageToTop()
                }
                self.lastChpt = self.newChpt
//            }
            updateCurrentPage(page)
            isFirstLoad = false
        }
        
        if let pagePositionInChapter = goToPagePositionInChapter, let currentPage = currentPage {
            delay(0.2) { [weak self] in
                currentPage.goTo(pagePositionInChapter: pagePositionInChapter)
                self?.goToPagePositionInChapter = nil
            }
        } else if let scrolltoPage = scrolltoPage, let currentPage = currentPage {
            delay(0.2) { [weak self] in
                currentPage.goTo(chapterPage: scrolltoPage)
                self?.scrolltoPage = nil
            }
        }
            
        // Go to fragment if needed
        if let fragmentID = tempFragment, let currentPage = currentPage, fragmentID != "" {
                delay(0.2) { [weak self] in
                    currentPage.handleAnchor(fragmentID, avoidBeginningAnchors: true, animated: false)
                    self?.collectionView.alpha = 1.0
                }
            tempFragment = nil
        }
        
        if (readerConfig.scrollDirection == .horizontalWithVerticalContent),
            let offsetPoint = self.currentWebViewScrollPositions[page.pageNumber - 1] {
            page.webView.scrollView.setContentOffset(offsetPoint, animated: false)
        }
        // Pass the event to the centers `pageDelegate`
        pageDelegate?.pageDidLoad?(page)
        delay(1) { [weak self] in
            self?.currentPage?.checkBookMarks()
            self?.collectionView.isUserInteractionEnabled = true
            self?.collectionView.alpha = 1.0
        }

    }
    
    public func pageWillLoad(_ page: FolioReaderPage) {
        // Pass the event to the centers `pageDelegate`
        pageDelegate?.pageWillLoad?(page)
    }
}

// MARK: FolioReaderChapterListDelegate

extension FolioReaderCenter: FolioReaderListDelegate {
    
    func selectItemList(didSelectRowAtIndexPath indexPath: IndexPath, withTocReference reference: FRTocReference) {
        let item = findPageByResource(reference)
        
        if item < totalPages {
            let indexPath = IndexPath(row: item, section: 0)
            changePageWith(indexPath: indexPath, animated: false, completion: { () -> Void in
                self.updateCurrentPage()
            })
            tempReference = reference
        } else {
            print("Failed to load book because the requested resource is missing.")
        }
    }
    
    func dismissList() {
        updateCurrentPage()
        
        // Move to #fragment
        if let reference = tempReference {
            if let fragmentID = reference.fragmentID, let currentPage = currentPage , fragmentID != "" {
                currentPage.handleAnchor(reference.fragmentID!, avoidBeginningAnchors: true, animated: true)
            }
            tempReference = nil
        }
    }
}
