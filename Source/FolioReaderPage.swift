//
//  FolioReaderPage.swift
//  FolioReaderKit
//
//  Created by Heberti Almeida on 10/04/15.
//  Copyright (c) 2015 Folio Reader. All rights reserved.
//

import UIKit
import SafariServices
import MenuItemKit
import JSQWebViewController

/// Protocol which is used from `FolioReaderPage`s.
@objc public protocol FolioReaderPageDelegate: class {

    /**
     Notify that the page will be loaded. Note: The webview content itself is already loaded at this moment. But some java script operations like the adding of class based on click listeners will happen right after this method. If you want to perform custom java script before this happens this method is the right choice. If you want to modify the html content (and not run java script) you have to use `htmlContentForPage()` from the `FolioReaderCenterDelegate`.

     - parameter page: The loaded page
     */
    @objc optional func pageWillLoad(_ page: FolioReaderPage)

    /**
     Notifies that page did load. A page load doesn't mean that this page is displayed right away, use `pageDidAppear` to get informed about the appearance of a page.

     - parameter page: The loaded page
     */
    @objc optional func pageDidLoad(_ page: FolioReaderPage)
}

open class FolioReaderPage: UICollectionViewCell, UIWebViewDelegate, UIGestureRecognizerDelegate {
    weak var delegate: FolioReaderPageDelegate?
    weak var readerContainer: FolioReaderContainer?
    open var searchHighlights: [Highlight]?
    open var needTransform: Bool = true
    
    /// The index of the current page. Note: The index start at 1!
    open var pageNumber: Int!
    var webView: FolioReaderWebView!
    var bookMarkButton: UIButton!
    var bookMarkId: String?
    
    var noteButtons: [NoteButton] = []
    
    fileprivate var colorView: UIView!
    fileprivate var shouldShowBar = true
    fileprivate var menuIsVisible = false

    fileprivate var readerConfig: FolioReaderConfig {
        guard let readerContainer = readerContainer else { return FolioReaderConfig() }
        return readerContainer.readerConfig
    }

    fileprivate var book: FRBook {
        guard let readerContainer = readerContainer else { return FRBook() }
        return readerContainer.book
    }

    fileprivate var folioReader: FolioReader {
        guard let readerContainer = readerContainer else { return FolioReader() }
        return self.readerContainer!.folioReader
    }

    // MARK: - View life cicle

    public override init(frame: CGRect) {
        // Init explicit attributes with a default value. The `setup` function MUST be called to configure the current object with valid attributes.
        self.readerContainer = FolioReaderContainer(withConfig: FolioReaderConfig(), folioReader: FolioReader(), epubPath: "")
        super.init(frame: frame)

        NotificationCenter.default.addObserver(self, selector: #selector(refreshPageMode), name: NSNotification.Name(rawValue: "needRefreshPageMode"), object: nil)
    }

    public func setup(withReaderContainer readerContainer: FolioReaderContainer, folioReader: FolioReader) {
        self.readerContainer = readerContainer
        guard let readerContainer = self.readerContainer else { return }
        clearNotesButton()
        
        if webView == nil {
            webView = FolioReaderWebView(frame: folioReader.webViewFrame(), readerContainer: readerContainer, readerPageNumber: self.pageNumber ?? 0)
            webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            webView.dataDetectorTypes = .link
            webView.scrollView.showsVerticalScrollIndicator = false
            webView.scrollView.showsHorizontalScrollIndicator = false
            webView.isOpaque = false
            webView.backgroundColor = .clear
            self.contentView.addSubview(webView)
        }

        webView.delegate = self

        if colorView == nil {
            colorView = UIView()
            webView.scrollView.addSubview(colorView)
        }

        updateColors()
        
        if bookMarkButton == nil {
            bookMarkButton =  UIButton(frame: CGRect( x: 10, y: 10, width: 32, height: 60))
            bookMarkButton.setImage(#imageLiteral(resourceName: "addbokkmark_inside"), for: .normal)
            self.contentView.addSubview(bookMarkButton)
        }
        checkBookMarks()
        
        webView.gestureRecognizers?.forEach({ gesture in
            webView.removeGestureRecognizer(gesture)
        })
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture(_:)))
        tapGestureRecognizer.numberOfTapsRequired = 1
        tapGestureRecognizer.delegate = self
        webView.addGestureRecognizer(tapGestureRecognizer)
        
        if #available(iOS 9.0, *) {
            webView.semanticContentAttribute = .forceLeftToRight
            bookMarkButton.semanticContentAttribute = .forceLeftToRight
            colorView.semanticContentAttribute = .forceLeftToRight
            self.semanticContentAttribute = .forceLeftToRight
        }
    }
    
    func updateColors() {
        let background = folioReader.readerCenter?.getColor()
        colorView.backgroundColor = background
    }
    
    func checkBookMarks() {
        guard let pageNumber = self.pageNumber, let readerCenter = folioReader.readerCenter else { return }
        
        let bookmarks: [Bookmark] = Bookmark.all(withConfiguration: readerConfig, andChapterIndex: pageNumber - 1)
        var isBookmark = false

        for bookmark in bookmarks {
            let width = webView.scrollView.contentSize.width
            let x = webView.scrollView.contentOffset.x
            
            let currentOffset = round((width-x)/readerCenter.pageWidth)
            let bookmarkOffset = round((width * CGFloat(bookmark.pagePositionInChapter))/readerCenter.pageWidth)
            
            let currentPageInChapter = Int(currentOffset)
            let pageInBookmark = Int(bookmarkOffset)
            if currentPageInChapter == pageInBookmark {
                isBookmark = true
            }
        }
        
        bookMarkButton.setImage(isBookmark ? #imageLiteral(resourceName: "bluebookmark_inside_bookmark") : #imageLiteral(resourceName: "addbokkmark_inside"), for: .normal)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("storyboards are incompatible with truth and beauty")
    }

    deinit {
        webView.scrollView.delegate = nil
        webView.delegate = nil
        NotificationCenter.default.removeObserver(self)
    }

    override open func layoutSubviews() {
        super.layoutSubviews()

        webView.setupScrollDirection()
        webView.frame = folioReader.webViewFrame()
    }
    
    func getHTML()-> String? {
        
        let html = self.webView.js("getHTML()")
        
        return html
    }
    
    func getHTMLBody()-> String? {
        
        let htmlBody = self.webView.js("getHTMLBody()")
        
        return htmlBody
    }

    func loadHTMLString(_ htmlContent: String!, baseURL: URL!) {
        // Insert the stored highlights to the HTML
        let tempHtmlContent = htmlContentWithInsertHighlights(htmlContent)
        // Load the html into the webview
        webView.alpha = 0
        webView.loadHTMLString(tempHtmlContent, baseURL: baseURL)
    }

    // MARK: - Highlights

    fileprivate func htmlContentWithInsertHighlights(_ htmlContent: String) -> String {
        var tempHtmlContent = htmlContent as NSString
        // Restore highlights

        var highlights = Highlight.all(withConfiguration: self.readerConfig, andPage:NSNumber.init(value: pageNumber))

        if let searchHighlights = searchHighlights, searchHighlights.first?.page == pageNumber {
            highlights.append(contentsOf: searchHighlights)
        }
        
        if (highlights.count > 0) {
            for item in highlights {
                let style = HighlightStyle.classForStyle(item.type)
                if let title = item.title {
                    var tag = "<highlight id=\"\(item.highlightId!)\" onclick=\"callHighlightURL(this);\" class=\"\(style)\">\(title)</highlight>"
                    guard let contentPre = item.contentPre else { continue }
                    guard let contentPost = item.contentPost else { continue }
                    
                    let fullRange: NSRange = tempHtmlContent.range(of: contentPre + item.title + contentPost, options: .literal)
                    if fullRange.location != NSNotFound {
                        let newRange = NSRange(location: fullRange.location+contentPre.characters.count, length: title.characters.count)
                        tempHtmlContent = tempHtmlContent.replacingCharacters(in: newRange, with: tag) as NSString
                    }
                }
            }
        }
        return tempHtmlContent as String
    }
    
    func addNoteButton(rect: CGRect, highlightId: String, note: String) {
        var needStop = false
        noteButtons.forEach { (button) in
            if button.x == rect.origin.x, button.y == rect.origin.y {
                button.highlightIds.append((highlightId, note))
                needStop = true
                return
            }
        }
        if needStop == true { return }
        let noteButton = NoteButton(frame: rect)
        noteButton.setImage(#imageLiteral(resourceName: "list_note"), for: .normal)
        noteButton.x = rect.origin.x
        noteButton.y = rect.origin.y
        noteButton.highlightIds.append((highlightId, note))
        noteButton.addTarget(self, action: #selector(noteTapped), for: .touchUpInside)
        webView.scrollView.addSubview(noteButton)
        noteButtons.append(noteButton)
    }
    
    @objc func noteTapped(sender: NoteButton) {
        if sender.highlightIds.count > 1 {
            let actionSheet = UIAlertController(title: "", message: "", preferredStyle: .alert)
            let cancelAction: UIAlertAction = UIAlertAction(title: NSLocalizedString("FilioReader.ReaderNote.cancel", comment: ""), style: .cancel)
            actionSheet.addAction(cancelAction)

            sender.highlightIds.forEach({ (highlight) in
                let action: UIAlertAction = UIAlertAction(title: highlight.1 , style: .default) { action -> Void in
                    self.webView.showNote(highlight: highlight)
                }
                actionSheet.addAction(action)
            })
            readerContainer?.centerViewController?.present(actionSheet, animated: true, completion: nil)
        } else {
            webView.showNote(highlight: sender.highlightIds.first)
        }
    }
    
    func clearNotesButton() {
        noteButtons.forEach { (button) in
            button.removeFromSuperview()
        }
        noteButtons.removeAll()
    }
    
    func addNotesIfNeeded() {
        clearNotesButton()
        let highlights = Highlight.all(withConfiguration: self.readerConfig, andPage: pageNumber as NSNumber?)
        
        if (highlights.count > 0) {
            for item in highlights {
                if item.isNote == false { continue }
                guard let highlightId = item.highlightId else { return }

                let data = webView.js("getRectElement('\(highlightId)')")
    
                guard let jsonData = data?.data(using: String.Encoding.utf8) else { continue }
                do {
                    guard let json = try JSONSerialization.jsonObject(with: jsonData, options: []) as? NSArray else { continue }
                    guard let dic = json.firstObject as? Dictionary<String, Any> else { continue }
                    guard let rect = dic["rect"] as? Dictionary<String, Any> else { continue }
                    guard let top = rect["top"] as? CGFloat else { continue }
                    guard let bottom = rect["bottom"] as? CGFloat else { continue }
                    guard var offset = dic["offset"] as? CGFloat else { continue }

                    let pageWidth =  webView.frame.width
                    let buttonHeight: CGFloat = 30.0
                    let pages = Int(webView.scrollView.contentSize.width / pageWidth)
                    let offsetTwo = (offset < pageWidth ? pageWidth : offset)
                    let currentPage = offset < pageWidth ? 0 : Int(offsetTwo / pageWidth)
                    let page = pages - currentPage
                    
                    let x = CGFloat(page) * pageWidth - ( UIScreen.main.bounds.size.height > 812 ? 50 : 35)
                    let y = top + ((bottom - top)/2) - buttonHeight/2
                    let buttonRect = CGRect(x: x, y: y, width: 30, height: buttonHeight)
                    addNoteButton(rect: buttonRect, highlightId: highlightId, note: item.note)
                } catch {
                    print("Could not receive JSON")
                }
            }
        }
    }

    // MARK: - UIWebView Delegate

    open func webViewDidFinishLoad(_ webView: UIWebView) {
        guard let webView = webView as? FolioReaderWebView else {
            return
        }

        
        print("DID FINISH LOAD WEB VIEW contentSize = \(self.webView.scrollView.contentSize.width)")
        delegate?.pageWillLoad?(self)

        // Add the custom class based onClick listener
        self.setupClassBasedOnClickListeners()

        if (self.readerConfig.enableTTS == true && self.book.hasAudio() == false) {
            webView.js("wrappingSentencesWithinPTags()")

            if let audioPlayer = self.folioReader.readerAudioPlayer, (audioPlayer.isPlaying() == true) {
                audioPlayer.readCurrentSentence()
            }
        }

        let direction: ScrollDirection = self.folioReader.needsRTLChange ? .positive(withConfiguration: self.readerConfig) : .negative(withConfiguration: self.readerConfig)
        
//        if (self.folioReader.readerCenter?.pageScrollDirection == direction &&
//            self.folioReader.readerCenter?.isScrolling == true &&
//            self.readerConfig.scrollDirection != .horizontalWithVerticalContent) {
//            scrollPageToBottom()
//        }

        UIView.animate(withDuration: 0.2, animations: {webView.alpha = 1}, completion: { finished in
            webView.isColors = false
            self.webView.createMenu(options: false)
        })

        delegate?.pageDidLoad?(self)
        refreshPageMode()
       addNotesIfNeeded()
        

    }
    
    open func searchIfNeed() {
        if let searchHighlights = searchHighlights, searchHighlights.first?.page == pageNumber {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                searchHighlights.forEach({ model in
                    if let highlightId = model.highlightId {
                        self.searchHighlights = nil
                        self.webView.js("removeHighlightById('\(highlightId)')")
                    }
                    })

            }
        }
    }

    open func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebView.NavigationType) -> Bool {
        guard
            let webView = webView as? FolioReaderWebView,
            let scheme = request.url?.scheme else {
                return true
        }

        guard let url = request.url else { return false }

        if scheme == "highlight" {
            shouldShowBar = false

            guard let decoded = url.absoluteString.removingPercentEncoding else { return false }
            let rect = NSCoder.cgRect(for: decoded.substring(from: decoded.index(decoded.startIndex, offsetBy: 12)))

            webView.createMenu(options: true)
            let point = CGPoint(x: rect.origin.x + rect.size.width/2, y: rect.origin.y)
                webView.showHilightMenu(touchPoint: point)
//            webView.setMenuVisible(true, andRect: rect)
//            menuIsVisible = true

            return false
        } else if scheme == "play-audio" {

            guard let decoded = url.absoluteString.removingPercentEncoding else { return false }
            let playID = decoded.substring(from: decoded.index(decoded.startIndex, offsetBy: 13))
            let chapter = self.folioReader.readerCenter?.getCurrentChapter()
            let href = chapter?.href ?? ""
            self.folioReader.readerAudioPlayer?.playAudio(href, fragmentID: playID)

            return false
        } else if scheme == "file" {

            let anchorFromURL = url.fragment

            // Handle internal url
            if ((url.path as NSString).pathExtension != "") {

                var pathComponent = (self.book.opfResource.href as? NSString)?.deletingLastPathComponent
                guard let base = ((pathComponent == nil || pathComponent?.isEmpty == true) ? self.book.name : pathComponent) else {
                    return true
                }

                let path = url.path
                let splitedPath = path.components(separatedBy: base)

                // Return to avoid crash
                if (splitedPath.count <= 1 || splitedPath[1].isEmpty) {
                    return true
                }

                let href = splitedPath[1].trimmingCharacters(in: CharacterSet(charactersIn: "/"))
                let hrefPage = (self.folioReader.readerCenter?.findPageByHref(href) ?? 0) + 1

                if (hrefPage == pageNumber) {
                    // Handle internal #anchor
                    if anchorFromURL != nil {
                        handleAnchor(anchorFromURL!, avoidBeginningAnchors: false, animated: true)
                        return false
                    }
                } else {
                    self.folioReader.readerCenter?.changePageWith(href: href, animated: true)
                }

                return false
            }

            // Handle internal #anchor
            if anchorFromURL != nil {
                handleAnchor(anchorFromURL!, avoidBeginningAnchors: false, animated: true)
                return false
            }

            return true
        } else if scheme == "mailto" {
            return true
        } else if url.absoluteString != "about:blank" && scheme.contains("http") && navigationType == .linkClicked {

            if #available(iOS 9.0, *) {
                let safariVC = SFSafariViewController(url: request.url!)
                safariVC.view.tintColor = self.readerConfig.tintColor
                self.folioReader.readerCenter?.present(safariVC, animated: true, completion: nil)
            } else {
                let webViewController = WebViewController(url: request.url!)
                let nav = UINavigationController(rootViewController: webViewController)
                nav.view.tintColor = self.readerConfig.tintColor
                self.folioReader.readerCenter?.present(nav, animated: true, completion: nil)
            }
            return false
        } else {
            // Check if the url is a custom class based onClick listerner
            var isClassBasedOnClickListenerScheme = false
            for listener in self.readerConfig.classBasedOnClickListeners {

                if
                    (scheme == listener.schemeName),
                    let absoluteURLString = request.url?.absoluteString,
                    let range = absoluteURLString.range(of: "/clientX=") {
                    let baseURL = absoluteURLString.substring(to: range.lowerBound)
                    let positionString = absoluteURLString.substring(from: range.lowerBound)
                    if let point = getEventTouchPoint(fromPositionParameterString: positionString) {
                        let attributeContentString = (baseURL.replacingOccurrences(of: "\(scheme)://", with: "").removingPercentEncoding)
                        // Call the on click action block
                        listener.onClickAction(attributeContentString, point)
                        // Mark the scheme as class based click listener scheme
                        isClassBasedOnClickListenerScheme = true
                    }
                }
            }

            if isClassBasedOnClickListenerScheme == false {
                // Try to open the url with the system if it wasn't a custom class based click listener
                if UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.openURL(url)
                    return false
                }
            } else {
                return false
            }
        }

        return true
    }

    fileprivate func getEventTouchPoint(fromPositionParameterString positionParameterString: String) -> CGPoint? {
        // Remove the parameter names: "/clientX=188&clientY=292" -> "188&292"
        var positionParameterString = positionParameterString.replacingOccurrences(of: "/clientX=", with: "")
        positionParameterString = positionParameterString.replacingOccurrences(of: "clientY=", with: "")
        // Separate both position values into an array: "188&292" -> [188],[292]
        let positionStringValues = positionParameterString.components(separatedBy: "&")
        // Multiply the raw positions with the screen scale and return them as CGPoint
        if
            positionStringValues.count == 2,
            let xPos = Int(positionStringValues[0]),
            let yPos = Int(positionStringValues[1]) {
            return CGPoint(x: xPos, y: yPos)
        }
        return nil
    }

    // MARK: Gesture recognizer

    open func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {

//        if gestureRecognizer.view is FolioReaderWebView {
//            if otherGestureRecognizer is UILongPressGestureRecognizer {
//                if UIMenuController.shared.isMenuVisible {
//                    webView.setMenuVisible(false)
//                }
//                return false
//            }
//            return false
//        }
        return true
    }
    
    @objc open func handleTapGesture(_ recognizer: UITapGestureRecognizer) {
        if let selected = webView.js("getSelectedText()"), selected.isEmpty == false {
           
            if webView.highlightMenuIsVisible == true && webView.highlightMenu?.selectedText != selected {
                webView.hiddenMenu()
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                if let selected = self.webView.js("getSelectedText()"), selected.isEmpty == false, let getRectForSelectedText = self.webView.js("getRectForSelectedText()") {
                    let rect = NSCoder.cgRect(for: getRectForSelectedText)
                    self.webView.showMenu(touchPoint: CGPoint.init(x: rect.origin.x + rect.size.width/2, y: rect.origin.y))
                } else {
                    self.webView.hiddenMenu()
                }
            }
            return
        }
        
        let delay = 0.2 * Double(NSEC_PER_SEC) // 0.4 seconds * nanoseconds per seconds
        let dispatchTime = (DispatchTime.now() + (Double(Int64(delay)) / Double(NSEC_PER_SEC)))
        DispatchQueue.main.asyncAfter(deadline: dispatchTime, execute: {
            if (self.shouldShowBar == true) {
                if (self.folioReader.readerCenter?.readerProgressManager?.isLoading)! && (self.folioReader.readerCenter?.popUpShouldHide)! {
                    self.folioReader.readerCenter?.closePopUpView()
                } else {
                    self.folioReader.readerCenter?.toggleBars()
                }
            } else {
                if (self.readerConfig.shouldHideNavigationOnTap == true) {
                    self.folioReader.readerCenter?.hideBars()
                    self.menuIsVisible = false
                }
            }
        })
        self.webView.hiddenMenu()
    }

    // MARK: - Public scroll postion setter

    /**
     Scrolls the page to a given offset

     - parameter offset:   The offset to scroll
     - parameter animated: Enable or not scrolling animation
     */
    open func scrollPageToOffset(_ offset: CGFloat, animated: Bool) {
        let pageOffsetPoint = self.readerConfig.isDirection(CGPoint(x: 0, y: offset), CGPoint(x: offset, y: 0), CGPoint(x: 0, y: offset))
        webView.scrollView.setContentOffset(pageOffsetPoint, animated: animated)
    }

    /**
     Scrolls the page to bottom
     */
    open func scrollPageToBottom() {
        let bottomOffset = self.readerConfig.isDirection(
            CGPoint(x: 0, y: webView.scrollView.contentSize.height - webView.scrollView.bounds.height),
            CGPoint(x: webView.scrollView.contentSize.width - webView.scrollView.bounds.width, y: 0),
            CGPoint(x: webView.scrollView.contentSize.width - webView.scrollView.bounds.width, y: 0)
        )
        
        if bottomOffset.forDirection(withConfiguration: self.readerConfig) >= 0 {
//            DispatchQueue.main.async(execute: {
                self.webView.scrollView.setContentOffset(bottomOffset, animated: false)
                delay(0.2) { [weak self] in
                    self?.folioReader.readerCenter?.progressView?.updateUI()
                }
//            })
        }
    }
    
    open func scrollPageToTop() {
        let point = CGPoint(x: 0, y: 0)
//        DispatchQueue.main.async(execute: {
            self.webView.scrollView.setContentOffset(point, animated: false)
            delay(0.2) { [weak self] in
                self?.folioReader.readerCenter?.progressView?.updateUI()
            }
//        })
    }
    
    /**
     Handdle #anchors in html, get the offset and scroll to it

     - parameter anchor:                The #anchor
     - parameter avoidBeginningAnchors: Sometimes the anchor is on the beggining of the text, there is not need to scroll
     - parameter animated:              Enable or not scrolling animation
     */
    open func handleAnchor(_ anchor: String, avoidBeginningAnchors: Bool, animated: Bool = false) {
        if !anchor.isEmpty {
            guard let readerCenter = folioReader.readerCenter else { return }
            guard let readerProgressManager = readerCenter.readerProgressManager else { return }
            
            let offset = getAnchorOffset(anchor)
            let data = webView.js("getRectElement('\(anchor)')")
            
            switch self.readerConfig.scrollDirection {
            case .vertical, .defaultVertical:
                let isBeginning = (offset < frame.forDirection(withConfiguration: self.readerConfig) * 0.5)
                
                if !avoidBeginningAnchors {
                    scrollPageToOffset(offset, animated: animated)
                } else if avoidBeginningAnchors && !isBeginning {
                    scrollPageToOffset(offset, animated: animated)
                }
            case .horizontal, .horizontalWithVerticalContent:
                let totalOffset = webView.scrollView.contentSize.width - offset - readerCenter.pageWidth
                scrollPageToOffset(totalOffset, animated: animated)
            }
            
            searchIfNeed()
            
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "com.app.GetBooksApp.Notification.Name.Progress.update"),
                                            object: nil,
                                            userInfo: nil)
        }
        
    }
    
    func goTo(pagePositionInChapter: Float) {
        guard let readerCenter = folioReader.readerCenter else { return }
        guard let readerProgressManager = readerCenter.readerProgressManager else { return }
        
        var totalPages = readerProgressManager.currentTotalPages(section:  readerCenter.currentPageNumber - 1)
        let offset = CGFloat(Int(readerCenter.pageWidth) * (totalPages - Int(Float(totalPages) * pagePositionInChapter)))
        scrollPageToOffset(offset, animated: false)
        
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "com.app.GetBooksApp.Notification.Name.Progress.update"),
                                        object: nil,
                                        userInfo: nil)
    }
    
    func goTo(chapterPage: Int) {
        guard let readerCenter = folioReader.readerCenter else { return }
        guard let readerProgressManager = readerCenter.readerProgressManager else { return }
        
        var totalPages = readerProgressManager.currentTotalPages(section:  readerCenter.currentPageNumber - 1)
        let offset = CGFloat(Int(readerCenter.pageWidth) * (totalPages - chapterPage))
        scrollPageToOffset(offset, animated: false)
        
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "com.app.GetBooksApp.Notification.Name.Progress.update"),
                                        object: nil,
                                        userInfo: nil)
    }
    
    // MARK: Helper
    
    /**
     Get the #anchor offset in the page

     - parameter anchor: The #anchor id
     - returns: The element offset ready to scroll
     */
    func getAnchorOffset(_ anchor: String) -> CGFloat {
        let horizontal = self.readerConfig.scrollDirection == .horizontal
        if let strOffset = webView.js("getAnchorOffset('\(anchor)', \(horizontal.description))") {
            return CGFloat((strOffset as NSString).floatValue)
        }

        return CGFloat(0)
    }

    // MARK: Mark ID

    /**
     Audio Mark ID - marks an element with an ID with the given class and scrolls to it

     - parameter identifier: The identifier
     */
    func audioMarkID(_ identifier: String) {
        guard let currentPage = self.folioReader.readerCenter?.currentPage else {
            return
        }

        let playbackActiveClass = self.book.playbackActiveClass()
        currentPage.webView.js("audioMarkID('\(playbackActiveClass)','\(identifier)')")
    }

    // MARK: UIMenu visibility

    override open func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if UIMenuController.shared.menuItems?.count == 0 {
            webView.isColors = false
            webView.createMenu(options: false)
        }

        if !webView.isShare && !webView.isColors {
            if let result = webView.js("getSelectedText()") , result.components(separatedBy: " ").count == 1 {
                webView.isOneWord = true
                webView.createMenu(options: false)
            } else {
                webView.isOneWord = false
            }
        }

        return super.canPerformAction(action, withSender: sender)
    }

    // MARK: ColorView fix for horizontal layout
    @objc func refreshPageMode() {
        if (folioReader.nightMode == true || folioReader.milkMode == true) {
            let script = "document.documentElement.offsetHeight"
            let contentHeight = webView.stringByEvaluatingJavaScript(from: script)
            let frameHeight = webView.frame.height
            let lastPageHeight = frameHeight * CGFloat(webView.pageCount) - CGFloat(Double(contentHeight!)!)
            colorView.frame = CGRect(x: 0, y: webView.frame.height - lastPageHeight - 10, width: webView.frame.width + 5, height: webView.frame.height)
        } else {
            colorView.frame = CGRect.zero
        }
    }
    
    // MARK: - Class based click listener
    
    fileprivate func setupClassBasedOnClickListeners() {
        
        for listener in self.readerConfig.classBasedOnClickListeners {
            self.webView.js("addClassBasedOnClickListener(\"\(listener.schemeName)\", \"\(listener.querySelector)\", \"\(listener.attributeName)\", \"\(listener.selectAll)\")");
        }
    }
    
    // MARK: - Public Java Script injection
    
    /** 
     Runs a JavaScript script and returns it result. The result of running the JavaScript script passed in the script parameter, or nil if the script fails.
     
     - returns: The result of running the JavaScript script passed in the script parameter, or nil if the script fails.
     */
    open func performJavaScript(_ javaScriptCode: String) -> String? {
        return webView.js(javaScriptCode)
    }
}

extension String {
    
    func indicesOf(string: String) -> [Int] {
        var indices = [Int]()
        var searchStartIndex = self.startIndex
        
        while searchStartIndex < self.endIndex,
            let range = self.range(of: string, range: searchStartIndex..<self.endIndex),
            !range.isEmpty
        {
            let index = distance(from: self.startIndex, to: range.lowerBound)
            indices.append(index)
            searchStartIndex = range.upperBound
        }
        
        return indices
    }
    
    var words: [String] {
        return components(separatedBy: .punctuationCharacters)
            .joined()
            .components(separatedBy: .whitespaces)
            .filter{!$0.isEmpty}
    }
}
