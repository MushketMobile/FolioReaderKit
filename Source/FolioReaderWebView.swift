//
//  FolioReaderWebView.swift
//  FolioReaderKit
//
//  Created by Hans Seiffert on 21.09.16.
//  Copyright (c) 2016 Folio Reader. All rights reserved.
//

import UIKit


/// The custom WebView used in each page
open class FolioReaderWebView: UIWebView {
    var isColors = false
    var isShare = false
    var isOneWord = false
    var highlightMenu: HighlightMenu?
    var highlightMenuIsVisible: Bool = false
    
    var tempJSONData: Data?
    var noteWindow: Note?
    var noteWidth: CGFloat = 300.0
    var noteHeight: CGFloat = 250.0
    var keyboardMargin: CGFloat = 70.0
    var noteIsVisible: Bool = false
    
    var navBarView: ReaderNavBar?
    
    weak var readerContainer: FolioReaderContainer?

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

    override init(frame: CGRect) {
        fatalError("use init(frame:readerConfig:book:) instead.")
    }

    init(frame: CGRect, readerContainer: FolioReaderContainer, readerPageNumber: Int) {
        self.readerContainer = readerContainer
        super.init(frame: frame)
    }

    convenience init(frame: CGRect, readerContainer: FolioReaderContainer) {
        self.init(frame: frame, readerContainer: readerContainer, readerPageNumber: 0)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UIMenuController

    open override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        return false

        guard (self.readerConfig.useReaderMenuController == true) else {
            return super.canPerformAction(action, withSender: sender)
        }

        if isShare {
            return false
        } else if isColors {
            return false
        } else {
            if action == #selector(highlight(_:))
                || (action == #selector(define(_:)) && isOneWord)
                || (action == #selector(play(_:)) && (self.book.hasAudio() == true || self.readerConfig.enableTTS == true))
                || (action == #selector(share(_:)) && self.readerConfig.allowSharing == true)
                || (action == #selector(copy(_:)) && self.readerConfig.allowSharing == true) {
                return true
            }
            return false
        }
    }

    // MARK: - UIMenuController - Actions

    @objc func share(_ sender: UIMenuController) {
        
        
//        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
//
//        let shareImage = UIAlertAction(title: self.readerConfig.localizedShareImageQuote, style: .default, handler: { (action) -> Void in
//            if self.isShare {
//                if let textToShare = self.js("getHighlightContent()") {
//                    self.folioReader.readerCenter?.presentQuoteShare(textToShare)
//                }
//            } else {
//                if let textToShare = self.js("getSelectedText()") {
//                    self.folioReader.readerCenter?.presentQuoteShare(textToShare)
//
//                    self.clearTextSelection()
//                }
//            }
//            self.setMenuVisible(false)
//        })
//
//        let shareText = UIAlertAction(title: self.readerConfig.localizedShareTextQuote, style: .default) { (action) -> Void in
//            if self.isShare {
//                if let textToShare = self.js("getHighlightContent()") {
//                    self.folioReader.readerCenter?.shareHighlight(textToShare, rect: sender.menuFrame)
//                }
//            } else {
//                if let textToShare = self.js("getSelectedText()") {
//                    self.folioReader.readerCenter?.shareHighlight(textToShare, rect: sender.menuFrame)
//                }
//            }
//            self.setMenuVisible(false)
//        }
//
//        let cancel = UIAlertAction(title: self.readerConfig.localizedCancel, style: .cancel, handler: nil)
//
//        alertController.addAction(shareImage)
//        alertController.addAction(shareText)
//        alertController.addAction(cancel)
//
//        if let alert = alertController.popoverPresentationController {
//            alert.sourceView = self.folioReader.readerCenter?.currentPage
//            alert.sourceRect = sender.menuFrame
//        }
//
//        self.folioReader.readerCenter?.present(alertController, animated: true, completion: nil)
    }

    func colors(_ sender: UIMenuController?) {
        isColors = true
        createMenu(options: false)
        setMenuVisible(true)
    }

    func remove(_ sender: UIMenuController?) {
        if let removedId = js("removeThisHighlight()") {
            Highlight.removeById(withConfiguration: self.readerConfig, highlightId: removedId)
            readerContainer?.centerViewController?.currentPage?.addNotesIfNeeded()
        }
        setMenuVisible(false)
    }

    @objc func highlight(_ sender: UIMenuController?) -> Bool {

        if let text = js("getSelectedText()") as? String, text.contains("\n") {
            hiddenMenu()
            return false
        }
        
        let highlightAndReturn = js("highlightString('\(HighlightStyle.classForStyle(self.folioReader.currentHighlightStyle))')")
        guard let jsonData = highlightAndReturn?.data(using: String.Encoding.utf8) else { return false }
        
        do {
            guard let json = try JSONSerialization.jsonObject(with: jsonData, options: []) as? NSArray else { return false }
            guard let dic = json.firstObject as? [String: String] else { return false }
            guard let rectString = dic["rect"] as? String else { return false }
            guard let startOffset = dic["startOffset"] else { return false }
            guard let endOffset = dic["endOffset"] else { return false }
            
            let rect = CGRectFromString(rectString)

            guard
                let html = js("getHTML()"),
                let identifier = dic["id"] else {
                    return false
            }

            let pageNumber = folioReader.readerCenter?.currentPageNumber ?? 0
            let note = "default note"
            let isNoteExist = false

            let match = Highlight.MatchingHighlight(text: html,
                                                    id: identifier,
                                                    startOffset: startOffset,
                                                    endOffset: endOffset,
                                                    currentPage: pageNumber,
                                                    note: note,
                                                    isNote: isNoteExist)
            
            guard let highlight = Highlight.matchHighlight(readerConfig: readerConfig, match, text: js("getSelectedText()") as? String) else {
                hiddenMenu()
                return false
            }

            createMenu(options: true)
            setMenuVisible(true, andRect: rect)
            
            highlight.persist(withConfiguration: self.readerConfig)
            return true
        } catch {
            print("Could not receive JSON")
            return false
        }
    }

    func highlightForNote(_ sender: UIMenuController?) -> Bool {
        if let text = js("getSelectedText()") as? String, text.contains("\n") {
            hiddenMenu()
            return false
        }
        let highlightAndReturn = js("highlightString('\(HighlightStyle.classForStyle(self.folioReader.currentHighlightStyle))')")
        guard let jsonData = highlightAndReturn?.data(using: String.Encoding.utf8) else { return false }
        tempJSONData = jsonData
        return true
    }

    
    func createHighlightForNote(_ sender: UIMenuController?) -> Bool {
        guard let jsonData = tempJSONData else { return false }
        do {
            guard let json = try JSONSerialization.jsonObject(with: jsonData, options: []) as? NSArray else { return false }
            guard let dic = json.firstObject as? [String: String] else { return false }
            guard let rectString = dic["rect"] as? String else { return false }
            guard let startOffset = dic["startOffset"] else { return false }
            guard let endOffset = dic["endOffset"] else { return false }
            
            let rect = CGRectFromString(rectString)
            
            guard
                let html = js("getHTML()"),
                let identifier = dic["id"] else {
                    return false
            }
            
            let pageNumber = folioReader.readerCenter?.currentPageNumber ?? 0
            let note = noteWindow?.noteView.text ?? "default note"
            let isNoteExist = true
            
            let match = Highlight.MatchingHighlight(text: html,
                                                    id: identifier,
                                                    startOffset: startOffset,
                                                    endOffset: endOffset,
                                                    currentPage: pageNumber,
                                                    note: note,
                                                    isNote: isNoteExist)
            
            guard let highlight = Highlight.matchHighlight(readerConfig: readerConfig, match, text: js("getSelectedText()") as? String) else {
                hiddenMenu()
                return false
            }
            highlight.persist(withConfiguration: self.readerConfig)
            readerContainer?.centerViewController?.currentPage?.addNotesIfNeeded()
            
            return true
        } catch {
            print("Could not receive JSON")
            return false
        }
    }
    
    func dismissHighlightForNote() {
        
        
    }
    
    @objc func define(_ sender: UIMenuController?) {
        guard let selectedText = js("getSelectedText()") else {
            return
        }

        self.setMenuVisible(false)
        self.clearTextSelection()

        let vc = UIReferenceLibraryViewController(term: selectedText)
        vc.view.tintColor = self.readerConfig.tintColor
        guard let readerContainer = readerContainer else { return }
        readerContainer.show(vc, sender: nil)
    }

    @objc func play(_ sender: UIMenuController?) {
        self.folioReader.readerAudioPlayer?.play()

        self.clearTextSelection()
    }

    func setYellow(_ sender: UIMenuController?) {
        changeHighlightStyle(sender, style: .yellow)
    }

    func setGreen(_ sender: UIMenuController?) {
        changeHighlightStyle(sender, style: .green)
    }

    func setBlue(_ sender: UIMenuController?) {
        changeHighlightStyle(sender, style: .blue)
    }

    func setPink(_ sender: UIMenuController?) {
        changeHighlightStyle(sender, style: .pink)
    }

    func setUnderline(_ sender: UIMenuController?) {
        changeHighlightStyle(sender, style: .underline)
    }

    func changeHighlightStyle(_ sender: UIMenuController?, style: HighlightStyle) {
        self.folioReader.currentHighlightStyle = style.rawValue

        if let updateId = js("setHighlightStyle('\(HighlightStyle.classForStyle(style.rawValue))')") {
            Highlight.updateById(withConfiguration: self.readerConfig, highlightId: updateId, type: style)
        }
    }

    // MARK: - Create and show menu

    func createMenu(options: Bool) {
        return
        guard (self.readerConfig.useReaderMenuController == true) else {
            return
        }

        isShare = options

        let colors = UIImage(readerImageNamed: "colors-marker")
        let share = UIImage(readerImageNamed: "share-marker")
        let remove = UIImage(readerImageNamed: "no-marker")
        let yellow = UIImage(readerImageNamed: "yellow-marker")
        let green = UIImage(readerImageNamed: "green-marker")
        let blue = UIImage(readerImageNamed: "blue-marker")
        let pink = UIImage(readerImageNamed: "pink-marker")
        let underline = UIImage(readerImageNamed: "underline-marker")

        let menuController = UIMenuController.shared
        
        let highlightItem = UIMenuItem(title: self.readerConfig.localizedHighlightMenu, action: #selector(highlight(_:)))
        let playAudioItem = UIMenuItem(title: self.readerConfig.localizedPlayMenu, action: #selector(play(_:)))
//        let highlightItem = UIMenuItem(title: "", image: #imageLiteral(resourceName: "list_note"), action: #selector(define(_:)))
        
        let defineItem = UIMenuItem(title: self.readerConfig.localizedDefineMenu, action: #selector(define(_:)))
        let colorsItem = UIMenuItem(title: "C", image: colors) { [weak self] _ in
            self?.colors(menuController)
        }
        let shareItem = UIMenuItem(title: "S", image: share) { [weak self] _ in
            self?.share(menuController)
        }
        let removeItem = UIMenuItem(title: "R", image: remove) { [weak self] _ in
            self?.remove(menuController)
        }
        let yellowItem = UIMenuItem(title: "Y", image: yellow) { [weak self] _ in
            self?.setYellow(menuController)
        }
        let greenItem = UIMenuItem(title: "G", image: green) { [weak self] _ in
            self?.setGreen(menuController)
        }
        let blueItem = UIMenuItem(title: "B", image: blue) { [weak self] _ in
            self?.setBlue(menuController)
        }
        let pinkItem = UIMenuItem(title: "P", image: pink) { [weak self] _ in
            self?.setPink(menuController)
        }
        let underlineItem = UIMenuItem(title: "U", image: underline) { [weak self] _ in
            self?.setUnderline(menuController)
        }

        var menuItems = [shareItem]

        // menu on existing highlight
        if isShare {
            menuItems = [colorsItem, removeItem]
            if (self.readerConfig.allowSharing == true) {
                menuItems.append(shareItem)
            }
        } else if isColors {
            // menu for selecting highlight color
            menuItems = [yellowItem, greenItem, blueItem, pinkItem, underlineItem]
        } else {
            // default menu
            menuItems = [highlightItem, defineItem, shareItem]

            if (self.book.hasAudio() == true || self.readerConfig.enableTTS == true) {
                menuItems.insert(playAudioItem, at: 0)
            }

            if (self.readerConfig.allowSharing == false) {
                menuItems.removeLast()
            }
        }
        
        menuController.menuItems = menuItems
/***/
    }
    
    func showMenu(touchPoint: CGPoint) {
        if highlightMenuIsVisible == true {
            hiddenMenu()
            return
        }
        if folioReader.readerCenter?.navBarShouldHide == true {
            folioReader.readerCenter?.hideBars()
        }

        highlightMenuIsVisible = true
        highlightMenu?.removeFromSuperview()
        hiddenNote()
        highlightMenu = HighlightMenu.instanceFromNib()
        highlightMenu?.folioReaderWebView = self

        let webViewFrame = folioReader.webViewFrame()
        
        var x = touchPoint.x - 75 + webViewFrame.minX
        var y = touchPoint.y - 74 + webViewFrame.minY

        if y < 0.0 { x = 0.0 }
        if x < 0.0 { y = 0.0 }
        if x + 150.0 > self.superview?.frame.width { x = (self.superview?.frame.width ?? 0) - 150 }
        highlightMenu?.frame = CGRect(x: x, y: y, width: 150, height: 64)
        self.superview?.addSubview(highlightMenu!)
    }
    
    func showHilightMenu(touchPoint: CGPoint) {
        if highlightMenuIsVisible == true {
            hiddenMenu()
            return
        }
        highlightMenuIsVisible = true
        highlightMenu?.removeFromSuperview()
        highlightMenu = HighlightMenu.colorMenuInstanceFromNib()
        highlightMenu?.folioReaderWebView = self

        let webViewFrame = folioReader.webViewFrame()

        var x = touchPoint.x - 119 + webViewFrame.minX
        var y = touchPoint.y - 64 + webViewFrame.minY
        
        if x < 0.0 { x = 0.0 }
        if y < 0.0 { y = 0.0 }
        if x + 238.0 > self.superview?.frame.width { x = (self.superview?.frame.width ?? 0) - 238 }

        highlightMenu?.frame = CGRect(x: x, y: y, width: 238, height: 64)
        self.superview?.addSubview(highlightMenu!)
    }
    
    func showNote(highlight: (String, String)? = nil) {
        highlightMenuIsVisible = false
        highlightMenu?.removeFromSuperview()
        noteIsVisible = true
        guard let noteView = Note.instanceFromNib() as? Note else { return }
        noteWindow = noteView
        noteWindow?.folioReaderWebView = self
        noteWindow?.frame = CGRect(x: (UIScreen.main.bounds.width - noteWidth)/2, y: (UIScreen.main.bounds.height - noteHeight)/2, width: noteWidth , height: noteHeight)
        noteWindow?.noteView.font = UIFont.systemFont(ofSize: 22)
        noteWindow?.noteView.text = highlight?.1 ?? ""
        noteWindow?.highlightTuple = highlight
        if let noteWindow = noteWindow {
            self.readerContainer?.centerViewController?.view.addSubview(noteWindow)
        }
    }

    func setupNoteFrame(keyboardHeight: CGFloat) {
        noteWindow?.frame.origin.y = (UIScreen.main.bounds.size.height - keyboardHeight - noteHeight - keyboardMargin)/2
    }
    
    func hiddenNote() {
        noteIsVisible = false
        noteWindow?.noteView.resignFirstResponder()
        noteWindow?.removeFromSuperview()
    }
    
    func hiddenMenu() {
        isUserInteractionEnabled = false
        isUserInteractionEnabled = true
        highlightMenuIsVisible = false
        highlightMenu?.removeFromSuperview()
        hiddenNote()
    }
    
    open func setMenuVisible(_ menuVisible: Bool, animated: Bool = true, andRect rect: CGRect = CGRect.zero) {
        
        if !menuVisible && isShare || !menuVisible && isColors {
            isColors = false
            isShare = false
        }
        
        hiddenMenu()
        
        if menuVisible  {
            if !rect.equalTo(CGRect.zero) {
                UIMenuController.shared.setTargetRect(rect, in: self)
            }
        }
        
        UIMenuController.shared.setMenuVisible(menuVisible, animated: animated)
    }
    
    // MARK: - Java Script Bridge
    
    @discardableResult func js(_ script: String) -> String? {
        let callback = self.stringByEvaluatingJavaScript(from: script)
        if callback!.isEmpty { return nil }
        return callback
    }
    
    // MARK: WebView
    
    func clearTextSelection() {
        // Forces text selection clearing
        // @NOTE: this doesn't seem to always work
        
        self.isUserInteractionEnabled = false
        self.isUserInteractionEnabled = true
    }
    
    func setupScrollDirection() {
        switch self.readerConfig.scrollDirection {
        case .vertical, .defaultVertical, .horizontalWithVerticalContent:
            scrollView.isPagingEnabled = false
            paginationMode = .unpaginated
            scrollView.bounces = true
            break
        case .horizontal:
            scrollView.isPagingEnabled = true
            paginationMode = folioReader.needsRTLChange == true ? .rightToLeft : .leftToRight
            paginationBreakingMode = .page
            scrollView.bounces = false
            break
        }
    }
    
    func highlightAllOccurencesOfString(str:String) -> Int {
        let result = js("uiWebview_HighlightAllOccurencesOfString('\(str)')")
        let result2 = js("uiWebview_SearchResultCount")
        return  Int(result2!)!
    }
    
    func scrollTo(index:Int)  {
        js("uiWebview_ScrollTo('\(index)')")
    }
    
    func removeAllHighlights() {
        js("uiWebview_RemoveAllHighlights()")
    }
}
