//
//  FolioReaderKit.swift
//  FolioReaderKit
//
//  Created by Heberti Almeida on 08/04/15.
//  Copyright (c) 2015 Folio Reader. All rights reserved.
//

import Foundation
import UIKit

// MARK: - Internal constants

internal let kApplicationDocumentsDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
internal let kCurrentFontFamily = "com.folioreader.kCurrentFontFamily"
internal let kCurrentFontSize = "com.folioreader.kCurrentFontSize"
internal let kCurrentAudioRate = "com.folioreader.kCurrentAudioRate"
internal let kCurrentHighlightStyle = "com.folioreader.kCurrentHighlightStyle"
internal let kCurrentMediaOverlayStyle = "com.folioreader.kMediaOverlayStyle"
internal let kCurrentScrollDirection = "com.folioreader.kCurrentScrollDirection"
internal let kNightMode = "com.folioreader.kNightMode"
internal let kMode = "com.folioreader.kMode"
internal let kCurrentTOCMenu = "com.folioreader.kCurrentTOCMenu"
internal let kHighlightRange = 20
internal let kReuseCellIdentifier = "com.folioreader.Cell.ReuseIdentifier"
internal let kCurrentLineHeight = "kCurrentLineHeight"

/*** DISPLAY MODE ***/
internal let kDisplayMode = "com.folioreader.displayMode"


public struct FolioReaderError: Error {
    enum ErrorKind {
        case BookNotAvailable
        case ErrorInContainer
        case ErrorInOpf
        case AuthorNameNotAvailable
        case CoverNotAvailable
        case TitleNotAvailable
    }

    let kind: ErrorKind

    var localizedDescription: String {
        switch self.kind {
        case .BookNotAvailable:
            return "Book not found"
        case .ErrorInContainer, .ErrorInOpf:
            return "Invalid book format"
        case .AuthorNameNotAvailable:
            return "Author name not available"
        case .CoverNotAvailable:
            return "Cover image not available"
        case .TitleNotAvailable:
            return "Book title not available"
        }
    }
}

/// Defines the media overlay and TTS selection
///
/// - `default`: The background is colored
/// - underline: The underlined is colored
/// - textColor: The text is colored
public enum MediaOverlayStyle: Int {
    case `default`
    case underline
    case textColor

    init() {
        self = .default
    }

    func className() -> String {
        return "mediaOverlayStyle\(self.rawValue)"
    }
}

/*** DISPLAY MODE ***/
public enum DisplayMode: Int {
    case day
    case milk
    case night
    
    init() {
        self = .day
    }
    
    func className() -> String {
        return "displayMode\(self.rawValue)"
    }
}


/// FolioReader actions delegate
@objc public protocol FolioReaderDelegate: class {

    /// Did finished loading book.
    ///
    /// - Parameters:
    ///   - folioReader: The FolioReader instance
    ///   - book: The Book instance
    @objc optional func folioReader(_ folioReader: FolioReader, didFinishedLoading book: FRBook)

    /// Called when reader did closed.
    ///
    /// - Parameter folioReader: The FolioReader instance
    @objc optional func folioReaderDidClose(_ folioReader: FolioReader)

    /// Called when reader did closed.
    @available(*, deprecated, message: "Use 'folioReaderDidClose(_ folioReader: FolioReader)' instead.")
    @objc optional func folioReaderDidClosed()
}

/// Main Library class with some useful constants and methods
open class FolioReader: NSObject {

    public override init() { }

    deinit {
        removeObservers()
    }

    /// Custom unzip path
    open var unzipPath: String?

    /// FolioReaderDelegate
    open weak var delegate: FolioReaderDelegate?

    open var readerContainer: FolioReaderContainer?
    open weak var readerAudioPlayer: FolioReaderAudioPlayer?
    open weak var readerCenter: FolioReaderCenter? {
        return self.readerContainer?.centerViewController
    }

    /// Check if reader is open
    var isReaderOpen = false

    /// Check if reader is open and ready
    var isReaderReady = false

    /// Check if layout needs to change to fit Right To Left
    var needsRTLChange: Bool {
        return true
//        return (self.readerContainer?.book.spine.isRtl == true && self.readerContainer?.readerConfig.scrollDirection == .horizontal)
    }

    public func isNight<T>(_ f: T, _ l: T) -> T {
        return (self.nightMode == true ? f : l)
    }

/*** DISPLAY MODE ***/
    public func isMilk<T>(_ f: T, _ l: T) -> T {
        return (self.milkMode == true ? f : l)
    }
    
    /// UserDefault for the current ePub file.
    var defaults: FolioReaderUserDefaults {
        return FolioReaderUserDefaults(withIdentifier: self.readerContainer?.readerConfig.identifier)
    }

    // Add necessary observers
    fileprivate func addObservers() {
        removeObservers()
        NotificationCenter.default.addObserver(self, selector: #selector(saveReaderState), name: NSNotification.Name.UIApplicationWillResignActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(saveReaderState), name: NSNotification.Name.UIApplicationWillTerminate, object: nil)
    }

    /// Remove necessary observers
    fileprivate func removeObservers() {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationWillResignActive, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationWillTerminate, object: nil)
    }
}

// MARK: - Present FolioReader

extension FolioReader {

    /// Present a Folio Reader Container modally on a Parent View Controller.
    ///
    /// - Parameters:
    ///   - parentViewController: View Controller that will present the reader container.
    ///   - epubPath: String representing the path on the disk of the ePub file. Must not be nil nor empty string.
    ///   - config: FolioReader configuration.
    ///   - shouldRemoveEpub: Boolean to remove the epub or not. Default true.
    ///   - animated: Pass true to animate the presentation; otherwise, pass false.
    open func presentReader(parentViewController: UIViewController, withEpubPath epubPath: String, andConfig config: FolioReaderConfig, shouldRemoveEpub: Bool = false, animated:
        Bool = true) {
        var readerContainer = FolioReaderContainer(withConfig: config, folioReader: self, epubPath: epubPath, removeEpub: shouldRemoveEpub)
        self.readerContainer = readerContainer
        parentViewController.present(readerContainer, animated: animated, completion: nil)
        addObservers()

        // Set the shared instance to support old version.
        FolioReader.shared = self
    }
}

// MARK: -  Getters and setters for stored values

extension FolioReader {

    public func register(defaults: [String: Any]) {
        self.defaults.register(defaults: defaults)
    }

    open var nightMode: Bool {
        get { return self.defaults.bool(forKey: kNightMode) }
        set (value) {
            self.defaults.set(value, forKey: kNightMode)
            self.defaults.set(false, forKey: "milkMode")
            NotificationCenter.default.post(name: Notification.Name(rawValue: "needRefreshPageMode"), object: nil)
        }
    }
    
    open var milkMode: Bool {
        get { return self.defaults.bool(forKey: "milkMode") }
        set (value) {
            self.defaults.set(value, forKey: "milkMode")
            self.defaults.set(false, forKey: kNightMode)
            NotificationCenter.default.post(name: Notification.Name(rawValue: "needRefreshPageMode"), object: nil)
        }
    }
    
    open var styleCss: String {
        if self.milkMode {
            if pading == 2 {
                return Bundle.frameworkBundle().path(forResource: "StyleMilk_pading2x", ofType: "css") ?? ""
            } else if pading == 3 {
                return Bundle.frameworkBundle().path(forResource: "StyleMilk_pading3x", ofType: "css") ?? ""
            }
            return Bundle.frameworkBundle().path(forResource: "StyleMilk", ofType: "css") ?? ""
        }
        
        if pading == 2 {
            return  Bundle.frameworkBundle().path(forResource: "Style_pading2x", ofType: "css") ?? ""
        } else if pading == 3 {
            return  Bundle.frameworkBundle().path(forResource: "Style_pading3x", ofType: "css") ?? ""
        }
        
        return Bundle.frameworkBundle().path(forResource: "Style", ofType: "css") ?? ""
    }
    
    func webViewFrame() -> CGRect {
        let bookmarkHeight: CGFloat = 60
        var y: CGFloat = 25 + bookmarkHeight

        var height = UIScreen.main.bounds.height
        let statusbarHeight = UIApplication.shared.statusBarFrame.size.height

        let paddingBottom: CGFloat = 59 + 26 + statusbarHeight

        if pading == 2 {
            y += UIDevice.current.userInterfaceIdiom == .pad ? 45 : 35
        } else if pading == 3 {
            y += UIDevice.current.userInterfaceIdiom == .pad ? 75 : 55
        }
        height -= y + paddingBottom

        var frame = CGRect(x: UIScreen.main.bounds.origin.x, y: y, width: UIScreen.main.bounds.width, height: height)
        return frame
    }
    
    open var pading: Int {
        get {
            guard let padingValue = self.defaults.integer(forKey: "kPading") as? Int else {
                return 1
            }
            return padingValue == 0 ? 1 : padingValue
        }
        set (value) {
            self.defaults.set(value, forKey: "kPading")
            NotificationCenter.default.post(name: Notification.Name(rawValue: "needRefreshPageMode"), object: nil)
        }
    }

    /// Check current font name. Default .andada
    open var currentFont: FolioReaderFont {
        get {
            guard
                let rawValue = self.defaults.value(forKey: kCurrentFontFamily) as? Int,
                let font = FolioReaderFont(rawValue: rawValue) else {
                    return .andada
            }

            return font
        }
        set (font) {
            self.defaults.set(font.rawValue, forKey: kCurrentFontFamily)
            _ = self.readerCenter?.currentPage?.webView.js("setFontName('\(font.cssIdentifier)')")
        }
    }
    
    

    /// Check current font size. Default .m
    open var currentFontSize: FolioReaderFontSize {
        get {
            guard
                let rawValue = self.defaults.value(forKey: kCurrentFontSize) as? Int,
                let size = FolioReaderFontSize(rawValue: rawValue) else {
                    return .m
            }

            return size
        }
        set (value) {
            self.defaults.set(value.rawValue, forKey: kCurrentFontSize)

            guard let currentPage = self.readerCenter?.currentPage else {
                return
            }

            currentPage.webView.js("setFontSize('\(currentFontSize.cssIdentifier)')")
        }
    }
    
    var currentLineHeight: Int {
        get { return self.defaults.integer(forKey: kCurrentLineHeight) }
        set (value) {
            self.defaults.set(value, forKey: kCurrentLineHeight)
        }
    }

    /// Check current audio rate, the speed of speech voice. Default 0
    open var currentAudioRate: Int {
        get { return self.defaults.integer(forKey: kCurrentAudioRate) }
        set (value) {
            self.defaults.set(value, forKey: kCurrentAudioRate)
        }
    }

    /// Check the current highlight style.Default 0
    open var currentHighlightStyle: Int {
        get { return self.defaults.integer(forKey: kCurrentHighlightStyle) }
        set (value) {
            self.defaults.set(value, forKey: kCurrentHighlightStyle)
        }
    }

    /// Check the current Media Overlay or TTS style
    open var currentMediaOverlayStyle: MediaOverlayStyle {
        get {
            guard let rawValue = self.defaults.value(forKey: kCurrentMediaOverlayStyle) as? Int,
                let style = MediaOverlayStyle(rawValue: rawValue) else {
                return MediaOverlayStyle.default
            }
            return style
        }
        set (value) {
            self.defaults.set(value.rawValue, forKey: kCurrentMediaOverlayStyle)
        }
    }

/*** DISPLAY MODE ***/
    /// Check the current Display Mode
    open var currentDisplayMode: DisplayMode {
        get {
            guard let rawValue = self.defaults.value(forKey: kDisplayMode) as? Int,
                let style = DisplayMode(rawValue: rawValue) else {
                    return DisplayMode.day
            }
            return style
        }
        set (value) {
            self.defaults.set(value.rawValue, forKey: kDisplayMode)
        }
    }

    
    
    /// Check the current scroll direction. Default .defaultVertical
    open var currentScrollDirection: Int {
        get {
             guard let value = self.defaults.value(forKey: kCurrentScrollDirection) as? Int else {
                return FolioReaderScrollDirection.defaultVertical.rawValue
            }

            return value
        }
        set (value) {
            self.defaults.set(value, forKey: kCurrentScrollDirection)

            let direction = (FolioReaderScrollDirection(rawValue: currentScrollDirection) ?? .defaultVertical)
            self.readerCenter?.setScrollDirection(direction)
        }
    }

    open var currentMenuIndex: Int {
        get { return self.defaults.integer(forKey: kCurrentTOCMenu) }
        set (value) {
            self.defaults.set(value, forKey: kCurrentTOCMenu)
        }
    }

    open var savedPositionForCurrentBook: [String: Any]? {
        get {
            guard let bookId = self.readerContainer?.book.name else {
                return nil
            }
            return self.defaults.value(forKey: bookId) as? [String : Any]
        }
        set {
            guard let bookId = self.readerContainer?.book.name else {
                return
            }
            self.defaults.set(newValue, forKey: bookId)
        }
    }
}

// MARK: - Image Cover

extension FolioReader {

    // TODO QUESTION: The static `getCoverImage` function used the shared instance before and ignored the `unzipPath` parameter.
    // Should we properly implement the parameter (what has been done now) or should change the API to only use the current FolioReader instance?

    /**
     Read Cover Image and Return an `UIImage`
     */
    open class func getCoverImage(_ epubPath: String, unzipPath: String? = nil) throws -> UIImage? {
        return try FREpubParser().parseCoverImage(epubPath, unzipPath: unzipPath)
    }

    open class func getTitle(_ epubPath: String) throws -> String? {
        return try FREpubParser().parseTitle(epubPath)
    }

    open class func getAuthorName(_ epubPath: String) throws-> String? {
        return try FREpubParser().parseAuthorName(epubPath)
    }
}

// MARK: - Exit, save and close FolioReader

extension FolioReader {

    /// Save Reader state, book, page and scroll offset.
    @objc open func saveReaderState() {
        guard isReaderOpen else {
            return
        }

        guard let bookId = self.readerContainer?.book.name, let currentPage = self.readerCenter?.currentPage else {
            return
        }

        let position = [
            "pageNumber": (self.readerCenter?.currentPageNumber ?? 0),
            "pageOffsetX": currentPage.webView.scrollView.contentOffset.x,
            "pageOffsetY": currentPage.webView.scrollView.contentOffset.y,
            "contentSizeWidth": currentPage.webView.scrollView.contentSize.width,
            "progressX" : (currentPage.webView.scrollView.contentOffset.x / currentPage.webView.scrollView.contentSize.width)
            ] as [String : Any]

        self.savedPositionForCurrentBook = position
    }

    /// Closes and save the reader current instance.
    open func close() {
        self.saveReaderState()
        self.isReaderOpen = false
        self.isReaderReady = false
        self.readerAudioPlayer?.stop(immediate: true)
        self.defaults.set(0, forKey: kCurrentTOCMenu)
        self.delegate?.folioReaderDidClose?(self)
        self.delegate?.folioReaderDidClosed?()
    }
}

// MARK: - Public static functions. All Deprecated function

@available(*, deprecated, message: "Shared instance removed. Use a local instance instead.")
extension FolioReader {

    private static var _sharedInstance = FolioReader()
    open static var shared : FolioReader {
        get { return _sharedInstance }
        set { _sharedInstance = newValue }
    }

    /// Check the current Media Overlay or TTS style
    static var currentMediaOverlayStyle: MediaOverlayStyle {
        return FolioReader.shared.currentMediaOverlayStyle
    }

/*** DISPLAY MODE ***/
    /// Check the current Display Mode
    static var currentDisplayMode: DisplayMode {
        return FolioReader.shared.currentDisplayMode
    }

    
    /// Check if current theme is Night mode
    open class var nightMode: Bool {
        get { return FolioReader.shared.nightMode }
        set { FolioReader.shared.nightMode = newValue }
    }

    /// Check if current theme is Milk mode
    open class var milkMode: Bool {
        get { return FolioReader.shared.milkMode }
        set { FolioReader.shared.milkMode = newValue }
    }

    
    /// Check current font name
    open class var currentFont: FolioReaderFont {
        get { return FolioReader.shared.currentFont }
        set { FolioReader.shared.currentFont = newValue }
    }

    /// Check current font size
    open class var currentFontSize: FolioReaderFontSize {
        get { return FolioReader.shared.currentFontSize }
        set { FolioReader.shared.currentFontSize = newValue }
    }

    /// Check the current scroll direction
    open class var currentScrollDirection: Int {
        get { return FolioReader.shared.currentScrollDirection }
        set { FolioReader.shared.currentScrollDirection = newValue }
    }

    /// Check current audio rate, the speed of speech voice
    open class var currentAudioRate: Int {
        get { return FolioReader.shared.currentAudioRate }
        set { FolioReader.shared.currentAudioRate = newValue }
    }

    /// Check if reader is open and ready
    open class var isReaderReady : Bool {
        return FolioReader.shared.isReaderReady
    }

    /// Save Reader state, book, page and scroll are saved
    @available(*, deprecated, message: "You no longer need to call `saveReaderState` for `applicationWillResignActive` and `applicationWillTerminate`. FolioReader Already handle that.")
    open class func saveReaderState() {
        FolioReader.shared.saveReaderState()
    }

    /// Closes and save the reader current instance
    open class func close() {
        FolioReader.shared.close()
    }

    /// Check the current highlight style
    open class var currentHighlightStyle: Int {
        get { return FolioReader.shared.currentHighlightStyle }
        set { FolioReader.shared.currentHighlightStyle = newValue }
    }

    /// Check if layout needs to change to fit Right To Left
    open class var needsRTLChange: Bool {
        return FolioReader.shared.needsRTLChange
    }
}

// MARK: - Global Functions

@available(*, deprecated, message: "Shared instance removed. Use a local instance instead.")
func isNight<T> (_ f: T, _ l: T) -> T {
    return FolioReader.shared.isNight(f, l)
}

@available(*, deprecated, message: "Shared instance removed. Use a local instance instead.")
func isMilk<T> (_ f: T, _ l: T) -> T {
    return FolioReader.shared.isMilk(f, l)
}

// MARK: - Scroll Direction Functions

@available(*, deprecated, message: "Shared instance removed. Use a local instance instead.")
func isDirection<T> (_ vertical: T, _ horizontal: T, _ horizontalContentVertical: T) -> T {
    return FolioReader.shared.readerContainer!.readerConfig.isDirection(vertical, horizontal, horizontalContentVertical)
}
