//
//  ReaderProgressManager.swift
//  Pods
//
//  Created by Aleksandr Vdovichenko on 9/5/17.
//
//

import UIKit
import RealmSwift

public class ReaderProgressManager: NSObject {
    var isLoading: Bool = false
    var needUpdate: Bool = false
    var isPortrainLoad: Bool = false
    
    var portrains: [UIWebView] = []
    var landscapes: [UIWebView] = []
    
    var portrainsUrl: [URL] = []
    var landscapesUrl: [URL] = []
    
    var portrainsContent: [String] = []
    var landscapesContent: [String] = []
    
    var pageCountPortrait: Int = 0
    var pageCountLandscape: Int = 0
    
    var pagesPortrait: [Int] = []
    var pagesLandscape: [Int] = []
    
    var persent: String {
        if isLoading == true { return "" }
        guard let model = progressModel else { return "" }
        if folioReader.readerCenter?.view.frame.size.width < folioReader.readerCenter?.view.frame.size.height {
            if model.totalPagePortrait == 0 { return "" }
            return "\(Int(currentPage * 100 / model.totalPagePortrait))%"
        } else {
            if model.totalPageLanscape == 0 { return "" }
            return "\(Int(currentPage * 100 / model.totalPageLanscape))%"
        }
        return ""
    }
    
    var persentInteger: Int {
        if isLoading == true { return 0 }
        guard let model = progressModel else { return 0 }
        if folioReader.readerCenter?.view.frame.size.width < folioReader.readerCenter?.view.frame.size.height {
            if model.totalPagePortrait == 0 { return 0 }
            return Int(currentPage * 100 / model.totalPagePortrait)
        } else {
            if model.totalPageLanscape == 0 { return 0 }
            return Int(currentPage * 100 / model.totalPageLanscape)
        }
        return 0
    }
    
    var totalPages: Int {
        if isLoading == true { return 0 }
        guard let model = progressModel else { return 0 }
        
        if folioReader.readerCenter?.view.frame.size.width < folioReader.readerCenter?.view.frame.size.height {
            return model.totalPagePortrait
        } else {
            return model.totalPageLanscape
        }
    }
    
    open var currentPage: Int {
        if isLoading == true { return 0 }
        guard let model = progressModel else { return 0 }
        guard let readerCenter = folioReader.readerCenter else { return 0 }

        var currentNumber = readerCenter.currentPageNumber == 0 ? 1 : readerCenter.currentPageNumber
        currentNumber -= 1
        
        var pagesCurrent = 0
        if folioReader.readerCenter?.view.frame.size.width < folioReader.readerCenter?.view.frame.size.height {
            for (index, section) in model.sectionsPortrait.enumerated() {
                if index == currentNumber { break }
                pagesCurrent += section.pages
            }
            
        } else {
            for (index, section) in model.sectionsLanscape.enumerated() {
                if index == currentNumber { break }
                pagesCurrent += section.pages
            }
        }

        if folioReader.needsRTLChange == true {
            let totalPages = currentTotalPages(section: currentNumber)
            guard let totalContentOffset = readerCenter.currentPage?.webView.scrollView.contentSize.width  else { return 0 }
            guard let contentOffset = readerCenter.currentPage?.webView.scrollView.contentOffset.x  else { return 0 }
            let currentPage = Int((totalContentOffset - contentOffset) / readerCenter.pageWidth)
            pagesCurrent += Int((totalContentOffset - contentOffset) / readerCenter.pageWidth)
        } else {
            pagesCurrent += folioReader.readerCenter?.pageIndicatorView?.currentPage ?? 1
        }
        
        return pagesCurrent
    }
    
    var currentPagesTitle: String {
        if isLoading == true { return "" }
        guard let model = progressModel else { return "" }
        if folioReader.readerCenter?.view.frame.size.width < folioReader.readerCenter?.view.frame.size.height {
            return "\(currentPage)/\(model.totalPagePortrait)"
        } else {
            return "\(currentPage)/\(model.totalPageLanscape)"
        }
        return ""
    }
    
    open var allCountPages: Int {
        if isLoading == true { return 0 }
        guard let model = progressModel else { return 0 }
        var pagesCurrent = 0

        if folioReader.readerCenter?.view.frame.size.width < folioReader.readerCenter?.view.frame.size.height {
            for (index, section) in model.sectionsPortrait.enumerated() {
                pagesCurrent += section.pages
            }
        } else {
            for (index, section) in model.sectionsLanscape.enumerated() {
                pagesCurrent += section.pages
            }
        }
        
        return pagesCurrent
    }
    
    func currentTotalPages(section: Int) -> Int {
        if isLoading == true { return 0 }
        guard let model = progressModel else { return 0 }
        if folioReader.readerCenter?.view.frame.size.width < folioReader.readerCenter?.view.frame.size.height {
            if section < model.sectionsPortrait.count {
                return model.sectionsPortrait[section].pages
            }
        } else {
            if section < model.sectionsLanscape.count {
                return model.sectionsLanscape[section].pages
            }
        }
        return 0
    }
    
    func getBookPageToScroll(for page: Int) -> (Int, Int) {
        if isLoading == true { return (0,0) }
        guard let model = progressModel else { return (0,0) }
        let currentNumber = folioReader.readerCenter?.currentPageNumber
        
        var chapter = 0
        var pagesCurrent = 0
        
        if folioReader.readerCenter?.view.frame.size.width < folioReader.readerCenter?.view.frame.size.height {
            for (index, section) in model.sectionsPortrait.enumerated() {
                chapter = section.сhapter
                for index2 in 0..<section.pages {
                    pagesCurrent += 1
                    if pagesCurrent == page {
                            return (chapter, index2 + 1)
                    }
                }
            }
            
        } else {
            for (index, section) in model.sectionsLanscape.enumerated() {
                chapter = section.сhapter
                for index2 in 0..<section.pages {
                    pagesCurrent += 1
                    if pagesCurrent == page {
                        return (chapter, index2 + 1)
                    }
                }
            }
        }
        return (0,0)
    }
    

    var progressModel: ProgressModel?
    fileprivate var folioReader: FolioReader

    var pageHeight: CGFloat {
        if isPortrainLoad {
            return UIScreen.main.bounds.width > UIScreen.main.bounds.height ? UIScreen.main.bounds.width : UIScreen.main.bounds.height
        }
        return UIScreen.main.bounds.width < UIScreen.main.bounds.height ? UIScreen.main.bounds.width : UIScreen.main.bounds.height
    }
    
    var pageWidth: CGFloat {
        if isPortrainLoad {
            return UIScreen.main.bounds.width < UIScreen.main.bounds.height ? UIScreen.main.bounds.width : UIScreen.main.bounds.height
        }
        return UIScreen.main.bounds.width > UIScreen.main.bounds.height ? UIScreen.main.bounds.width : UIScreen.main.bounds.height
    }
    
    
    init(folioReader: FolioReader) {
        self.folioReader = folioReader
    }
    
    func updateIfNeeded() {
        if isLoading == true { return }
        guard let readerConfig = folioReader.readerContainer?.readerConfig else { return }
        if let model = ProgressModel.find(withConfiguration:readerConfig,
                                          bookId: folioReader.readerContainer?.readerConfig.bookSku ?? "",
                                          fontSize: folioReader.currentFontSize.cssIdentifier,
                                          fontName: folioReader.currentFont.cssIdentifier,
                                          spaceLine: folioReader.currentLineHeight,
                                          pading: folioReader.pading) {
            progressModel = model
            folioReader.readerCenter?.progressView?.configurateScroll()
//            needUpdateUI()
            return
        }
        
        isPortrainLoad = true
        isLoading = true
        isPortrainLoad = true
        createWebView(with: webViewFrame())
        isPortrainLoad = false
        createWebView(with: webViewFrame())
        isPortrainLoad = true
        loadNext()
    }
    
    func clearAndUpdateIfNeeded() {
        if isLoading == true {
            needUpdate = true
            return
            
        }
        clear()
        updateIfNeeded()
    }
    
    func clear() {
        portrains.removeAll()
        portrainsUrl.removeAll()
        portrainsContent.removeAll()
        landscapes.removeAll()
        landscapesUrl.removeAll()
        landscapesContent.removeAll()
        pagesPortrait.removeAll()
        pagesLandscape.removeAll()
        
        isPortrainLoad = false
        isLoading = false
        pageCountLandscape = 0
        pageCountPortrait = 0
    }
    
    func webViewFrame() -> CGRect {
        let bookmarkHeight: CGFloat = 60
        var y: CGFloat = 25 + bookmarkHeight
        var height = pageHeight
        let statusbarHeight = UIApplication.shared.statusBarFrame.size.height
        
        let padding: CGFloat = 59 + 26 + statusbarHeight

        if folioReader.pading == 2 {
            y += UIDevice.current.userInterfaceIdiom == .pad ? 45 : 35
        } else if folioReader.pading == 3 {
            y += UIDevice.current.userInterfaceIdiom == .pad ? 75 : 55
        }
        
        height -= y + padding
        var frame = CGRect(x: UIScreen.main.bounds.origin.x, y: y, width: pageWidth, height: height)
        return frame
    }
    
    fileprivate func needUpdateUI() {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "com.app.GetBooksApp.Notification.Name.Progress.update"),
                                        object: nil,
                                        userInfo: nil)
    }
    
    private func saveData() {
        var progress = ProgressModel()
        progress.bookId = folioReader.readerContainer?.readerConfig.bookSku ?? ""
        progress.landscapeWidth = Float(pageWidth)
        progress.landscapeHeight = Float(pageHeight)
        progress.portraitWidth = Float(pageHeight)
        progress.portraitHeight = Float(pageWidth)
        progress.fontName = folioReader.currentFont.cssIdentifier
        progress.fontSize = folioReader.currentFontSize.cssIdentifier
        progress.totalPageLanscape = pageCountLandscape
        progress.totalPagePortrait = pageCountPortrait
        progress.pading = folioReader.pading
        var spaceType = "lineHeightOne"
        if folioReader.currentLineHeight == 1 { spaceType = "lineHeightTwo" }
        else if folioReader.currentLineHeight == 2 { spaceType = "lineHeightThree" }
        progress.spaceLine = spaceType
        
        for (index, element) in pagesLandscape.enumerated() {
            let section = Section()
            section.сhapter = index + 1
            section.pages = element
            progress.sectionsLanscape.append(section)
        }
        
        for (index, element) in pagesPortrait.enumerated() {
            let section = Section()
            section.сhapter = index + 1
            section.pages = element
            progress.sectionsPortrait.append(section)
        }
        
        do {
            let realm = try Realm(configuration: (folioReader.readerContainer?.readerConfig.realmConfiguration)!)
            realm.beginWrite()
            realm.add(progress, update: false)
            try realm.commitWrite()
            progressModel = progress
            clear()
            folioReader.readerCenter?.progressView?.configurateScroll()
            needUpdateUI()
            
            if needUpdate {
                needUpdate = false
                updateIfNeeded()
                
            }
        } catch let error as NSError {
            print("Error on persist highlight: \(error)")
        }
    }
    
    fileprivate func loadNext() {
        if isPortrainLoad {
            guard let webView = portrains.first,
                let url = portrainsUrl.first,
                let content = portrainsContent.first else {
                    isPortrainLoad = false
                    loadNext()
                    return
            }
            folioReader.readerContainer?.view.insertSubview(webView, at:0)
            webView.loadHTMLString(content, baseURL: url)
        } else {
            guard let webView = landscapes.first,
                let url = landscapesUrl.first,
                let content = landscapesContent.first else {
                    saveData()
                    return
            }
            folioReader.readerContainer?.view.insertSubview(webView, at:0)
            webView.loadHTMLString(content, baseURL: url)
        }
    }
    
    private func createWebView(with rect: CGRect) {
        var index = 1
        folioReader.readerContainer?.book.spine.spineReferences.map({
            
            var html = try? String(contentsOfFile: $0.resource.fullHref, encoding: String.Encoding.utf8)
            
            let webView = FolioReaderWebView.init(frame: rect, readerContainer: folioReader.readerContainer!)
            webView.delegate = self
            webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            webView.dataDetectorTypes = .link
            webView.scrollView.showsVerticalScrollIndicator = false
            webView.scrollView.showsHorizontalScrollIndicator = false
            webView.backgroundColor = UIColor.clear
            webView.setupScrollDirection()
            let mediaOverlayStyleColors = "\"\(folioReader.readerContainer?.readerConfig.mediaOverlayColor.hexString(false))\", \"\(folioReader.readerContainer?.readerConfig.mediaOverlayColor.highlightColor().hexString(false))\""
            
            // Inject CSS
            let jsFilePath = Bundle.frameworkBundle().path(forResource: "Bridge", ofType: "js")
            let cssFilePath = folioReader.styleCss
            let cssTag = "<link rel=\"stylesheet\" type=\"text/css\" href=\"\(cssFilePath)\">"
            let jsTag = "<script type=\"text/javascript\" src=\"\(jsFilePath!)\"></script>" +
            "<script type=\"text/javascript\">setMediaOverlayStyleColors(\(mediaOverlayStyleColors))</script>"
            
            let toInject = "\n\(cssTag)\n\(jsTag)\n</head>"
            html = html?.replacingOccurrences(of: "</head>", with: toInject)
            
            // Font class name
            folioReader.currentFont.cssIdentifier
            var classes = folioReader.currentFont.cssIdentifier
            classes += " " + folioReader.currentMediaOverlayStyle.className()
            
            // Night mode
            if folioReader.milkMode { classes += " milkMode"
            } else if folioReader.nightMode {  classes += " nightMode"
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
            html = html?.replacingOccurrences(of: "<html ", with: "<html class=\"\(classes)\"")

            let tempHtmlContent = htmlContentWithInsertHighlights(html!, pageNumber: NSNumber.init(value: index))

            webView.alpha = 0
            //            self.view.insertSubview(webView, at:0)

            if isPortrainLoad {
                portrains.append(webView)
                portrainsUrl.append(URL(fileURLWithPath: ($0.resource.fullHref as NSString).deletingLastPathComponent))
                portrainsContent.append(tempHtmlContent)
            } else {
                landscapes.append(webView)
                landscapesUrl.append(URL(fileURLWithPath: ($0.resource.fullHref as NSString).deletingLastPathComponent))
                landscapesContent.append(tempHtmlContent)
            }
        })
    }
    
    fileprivate func htmlContentWithInsertHighlights(_ htmlContent: String, pageNumber: NSNumber) -> String {
        var tempHtmlContent = htmlContent as NSString
        // Restore highlights
        
        let highlights = Highlight.all(withConfiguration: (folioReader.readerContainer?.readerConfig)!,
                                               andPage: pageNumber)
        
        if (highlights.count > 0) {
            for item in highlights {
                let style = HighlightStyle.classForStyle(item.type)
                if let title = item.title {
                    var tag = "<highlight id=\"\(item.highlightId!)\" onclick=\"callHighlightURL(this);\" class=\"\(style)\">\(title)</highlight>"
//                    let arrayEllements = title.words
                    
//                    if arrayEllements.count > 1 {
//                        guard let contentPre = item.contentPre else { continue }
//                        guard let contentPost = item.contentPost else { continue }
//
//                        let range: NSRange = tempHtmlContent.range(of: contentPre, options: .literal)
//                        let range2: NSRange = tempHtmlContent.range(of: contentPost, options: .literal)
//                        if range.location != NSNotFound, range2.location != NSNotFound  {
//                            let newRange = NSRange(location: range.location + range.length, length: range2.location - (range.location + range.length))
//                            tempHtmlContent = tempHtmlContent.replacingCharacters(in: newRange, with: tag) as NSString
//                        } else {
//                            print("highlight range not found")
//                        }
//                    } else {
                        guard let contentPre = item.contentPre else { continue }
                        let range: NSRange = tempHtmlContent.range(of: contentPre, options: .literal)
                        if range.location != NSNotFound {
                            let newRange = NSRange(location: range.location+range.length, length: title.characters.count)
                            tempHtmlContent = tempHtmlContent.replacingCharacters(in: newRange, with: tag) as NSString
//                        }
                    }
                }
            }
        }
        return tempHtmlContent as String
    }
}

extension ReaderProgressManager: UIWebViewDelegate {

    open func webViewDidFinishLoad(_ webView: UIWebView) {
        if isLoading == false { return }
        let contentSize = webView.scrollView.contentSize.forDirection(withConfiguration: (folioReader.readerContainer?.readerConfig)!)
        let pages = Int(contentSize / webView.frame.width)
        
        webView.removeFromSuperview()
        if isPortrainLoad {
            pageCountPortrait += pages
            if portrains.count > 0 { portrains.removeFirst() }
            if portrainsUrl.count > 0 { portrainsUrl.removeFirst() }
            if portrainsContent.count > 0 {
                portrainsContent.removeFirst()
                pagesPortrait.append(pages)
            }
            
            print("All pages: \(pageCountPortrait) == pages: \(pages) == ContentSize: \(contentSize)")
        } else {
            pageCountLandscape += pages
            if landscapes.count > 0 { landscapes.removeFirst() }
            if landscapesUrl.count > 0 { landscapesUrl.removeFirst() }
            if landscapesContent.count > 0 {
                landscapesContent.removeFirst()
                pagesLandscape.append(pages)
            }

            print("All pages: \(pageCountLandscape) == pages: \(pages) == ContentSize: \(contentSize)")
        }
        loadNext()
    }

}
