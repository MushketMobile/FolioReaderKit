
import UIKit

struct SearchModel {
    var page: Int!
    var title: String!
    var chapter: Int!
    var description: String!
    var highlight: Highlight!
}

class FolioReaderSearchViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var searchingLabel: UILabel!
    @IBOutlet weak var activity: UIActivityIndicatorView!
    @IBOutlet weak var backgroundImageView: UIImageView!

    fileprivate var items: [SearchModel] = []
    
    fileprivate var tempPage: Int = 0
    weak var readerCenter: FolioReaderCenter!
    var searchText: String?
    
    func add(folioReaderCenter: FolioReaderCenter) {
        readerCenter = folioReaderCenter
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        titleLabel.text = NSLocalizedString("FilioReader.FolioReaderSearch.searchResult", comment: "FilioReader.FolioReaderSearch: title 'Search result'")
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 120
        setCloseButton(withConfiguration: nil)
        configurateTable()
        searchInThisBook()
        updateBackgroundImage()
    }
    
    func updateBackgroundImage() {
        if DeviceType.IS_IPAD, UIApplication.shared.statusBarOrientation.isLandscape {
            backgroundImageView.image = #imageLiteral(resourceName: "background_image_landscape")
        } else if DeviceType.IS_IPHONE_X {
            backgroundImageView.image = #imageLiteral(resourceName: "background_image_X")
        } else {
            backgroundImageView.image = #imageLiteral(resourceName: "background_image")
        }
    }

    private func configurateTable() {
        self.tableView.register(UINib(nibName: "FolioReaderSearchCell",
                                      bundle: Bundle.frameworkBundle()),
                                forCellReuseIdentifier: "FolioReaderSearchCell")
    }
    
    func searchInThisBook(){
        guard var text = searchText else { return }

        
        searchingLabel.text = NSLocalizedString("searching", comment: "")
        
            var tmpItems: [SearchModel] = []
            for index in self.tempPage ..< self.readerCenter.totalPages {
                
                guard let resource = self.readerCenter.book.spine.spineReferences[index].resource else { continue }
                guard let html = try? String(contentsOfFile: resource.fullHref, encoding: String.Encoding.utf8) else { continue }
                guard let startIndex = html.index(of: "<body") else { continue }
                guard let endIndex = html.endIndex(of: "</body>") else { continue }
                guard let htmlBody = html.substring(with: startIndex..<endIndex) as? NSString else { continue }
                var contentPre = ""
                var contentPost = ""
                
                var longMatchStr =  ""

                    let ranges = (htmlBody as! String).ranges(of: text, options: .literal)
                    var searchIndex = 0
                    ranges.forEach({ (rangeTmp) in

                        let range = (htmlBody as! String).nsRange(from: rangeTmp)
                        contentPre = htmlBody.substring(with: NSRange(location: range.location-kHighlightRange, length: kHighlightRange))
                        contentPost = htmlBody.substring(with: NSRange(location: range.location + range.length, length: kHighlightRange))
                        
                        let model = self.createSearchHightight(text: text, contentPre: contentPre, contentPost: contentPost, index: index, resourceId: resource.id, searchId: "search_id_\(searchIndex)")
                        tmpItems.append(model)
                        searchIndex += 1
                    })
                    
                }
        
            if(tmpItems.count > 0){
                    self.items.append(contentsOf: tmpItems)
                    self.tableView.reloadData()
                    self.activity.stopAnimating()
                    self.searchingLabel.isHidden = true
            }else {
                if(self.tempPage < self.readerCenter.totalPages){
                        self.tempPage += 1
                        self.searchInThisBook()
                }else{
                    if(tmpItems.count == 0 ) {
                            self.activity.stopAnimating()
                            self.searchingLabel.isHidden = false
                            self.searchingLabel.text = NSLocalizedString("no_search_result", comment: "")
                    }
                }
            }
    }
    
    func createSearchHightight(text: String, contentPre: String, contentPost: String, index: Int, resourceId: String, searchId: String) -> SearchModel {
        var chapter = 0
        var currentChapter = 1
        self.readerCenter.book.flatTableOfContents.forEach({
            chapter += 1
            if $0.resource?.id == resourceId {
                currentChapter = chapter
            }
        })
        
        let longString = self.stripTagsFromStr(contentPre) + " " + text + self.stripTagsFromStr(contentPost)
        var model = SearchModel()
        model.page = index + 1
        model.description = longString ?? text
        model.title = String(format: NSLocalizedString("%d numberChapter", comment: ""), currentChapter)
        model.chapter = currentChapter
        
        let highlight = Highlight()
        highlight.highlightId = searchId
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = readerCenter.readerContainer?.readerConfig.localizedHighlightsDateFormat ?? ""
        highlight.userId = readerCenter.readerContainer?.readerConfig.userId ?? ""
        dateFormatter.locale = Locale.current
        highlight.createdDateString = dateFormatter.string(from: Foundation.Date())
        highlight.content = text
        highlight.title = text
        highlight.contentPre = Highlight.removeSentenceSpam(contentPre)
        highlight.contentPost = Highlight.removeSentenceSpam(contentPost)
        highlight.page = index + 1
        highlight.bookId = readerCenter.readerContainer?.readerConfig.bookSku
        model.highlight = highlight
        return model
    }
    
    override open func willRotate(to toInterfaceOrientation: UIInterfaceOrientation, duration: TimeInterval) {
        super.willRotate(to: toInterfaceOrientation, duration: duration)
        readerCenter.willRotate(to: toInterfaceOrientation, duration: duration)
    }
    
    override open func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
        super.didRotate(from: fromInterfaceOrientation)
        self.view.layoutIfNeeded()
        readerCenter.didRotate(from: fromInterfaceOrientation)
        readerCenter.needReload = true

    }
    
    func stripTagsFromStr(_ htmlStr:String)-> String {
        var htmlStr = htmlStr
        htmlStr = htmlStr.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression, range: nil)
        htmlStr = htmlStr.replacingOccurrences(of: "<[^>]*", with: "", options: .regularExpression, range: nil)
        htmlStr = htmlStr.replacingOccurrences(of: "[^<]*>", with: "", options: .regularExpression, range: nil)
        
        return htmlStr.trimmingCharacters(in: CharacterSet.whitespaces)
    }
    
    //#pragma mark - UITableView DataSource
    
    func tableView(_ table: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ table: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = table.dequeueReusableCell(withIdentifier: "FolioReaderSearchCell", for: indexPath) as! FolioReaderSearchCell
        let model = items[indexPath.row]
        cell.characterLabel.text = model.title
         //"%d Chapter"
        cell.searchText.text = model.description
        return cell
    }
    
    func tableView(_ table: UITableView, didSelectRowAt indexPath:IndexPath) {
        let model = items[indexPath.row]
        let chapter = model.chapter
        
        guard let thePage = model.page else { return }

        readerCenter.currentPage?.searchHighlights = items.filter{ $0.chapter == chapter }.map{ $0.highlight }
        readerCenter.reloadData()

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.readerCenter.changePageWith(page: thePage, andFragment: model.highlight.highlightId, isNoteExist: model.highlight.isNote)
                    self.dismiss(animated: true, completion: nil)
                }
        }

}

extension String {
    func index(of string: String, options: CompareOptions = .literal) -> Index? {
        return range(of: string, options: options)?.lowerBound
    }
    func endIndex(of string: String, options: CompareOptions = .literal) -> Index? {
        return range(of: string, options: options)?.upperBound
    }
    func indexes(of string: String, options: CompareOptions = .literal) -> [Index] {
        var result: [Index] = []
        var start = startIndex
        while let range = range(of: string, options: options, range: start..<endIndex) {
            result.append(range.lowerBound)
            start = range.upperBound
        }
        return result
    }
    func ranges(of string: String, options: CompareOptions = .literal) -> [Range<Index>] {
        var result: [Range<Index>] = []
        var start = startIndex
        while let range = range(of: string, options: options, range: start..<endIndex) {
            result.append(range)
            start = range.upperBound
        }
        return result
    }
    
    func substring(from: Int?, to: Int?) -> String {
        if let start = from {
            guard start < self.characters.count else {
                return ""
            }
        }
        
        if let end = to {
            guard end >= 0 else {
                return ""
            }
        }
        
        if let start = from, let end = to {
            guard end - start >= 0 else {
                return ""
            }
        }
        
        let startIndex: String.Index
        if let start = from, start >= 0 {
            startIndex = self.index(self.startIndex, offsetBy: start)
        } else {
            startIndex = self.startIndex
        }
        
        let endIndex: String.Index
        if let end = to, end >= 0, end < self.characters.count {
            endIndex = self.index(self.startIndex, offsetBy: end + 1)
        } else {
            endIndex = self.endIndex
        }
        
        return String(self[startIndex ..< endIndex])
    }
    
    func substring(from: Int) -> String {
        return self.substring(from: from, to: nil)
    }
    
    func substring(to: Int) -> String {
        return self.substring(from: nil, to: to)
    }
    
    func substring(from: Int?, length: Int) -> String {
        guard length > 0 else {
            return ""
        }
        
        let end: Int
        if let start = from, start > 0 {
            end = start + length - 1
        } else {
            end = length - 1
        }
        
        return self.substring(from: from, to: end)
    }
    
    func substring(length: Int, to: Int?) -> String {
        guard let end = to, end > 0, length > 0 else {
            return ""
        }
        
        let start: Int
        if let end = to, end - length > 0 {
            start = end - length + 1
        } else {
            start = 0
        }
        
        return self.substring(from: start, to: to)
    }
}

extension String {
    
    func ranges(of substring: String, options: CompareOptions = [], locale: Locale? = nil) -> [Range<Index>] {
        var ranges: [Range<Index>] = []
        while let range = self.range(of: substring, options: options, range: (ranges.last?.upperBound ?? self.startIndex)..<self.endIndex, locale: locale) {
            ranges.append(range)
        }
        return ranges
    }
    
        func nsRange(from range: Range<Index>) -> NSRange {
            return NSRange(range, in: self)
        }
}

