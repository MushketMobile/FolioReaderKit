//
//  FolioReaderBookmarkList.swift
//  Pods
//
//  Created by Admin on 08.09.17.
//
//

import UIKit

struct BookmarkStruct {
    var pagePositionInBook: Float = 0.0
    var chapterIndex: Int = 0
    var pagePositionInChapter: Float = 0.0
    var createdDateString: String = ""
}

class FolioReaderBookmarkList: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    weak var delegate: FolioReaderListDelegate?
    fileprivate var tocItems = [BookmarkStruct]()
    fileprivate var book: FRBook!
    fileprivate var readerConfig: FolioReaderConfig!
    fileprivate var folioReader: FolioReader!
    @IBOutlet weak var backgroundImageView: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()
        configurateTable()
        tocItems = Bookmark.all(withConfiguration: readerConfig).map{ BookmarkStruct.init(pagePositionInBook: $0.pagePositionInBook, chapterIndex: $0.chapterIndex, pagePositionInChapter: $0.pagePositionInChapter, createdDateString: $0.createdDateString) }
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
    
    open func add(folioReader: FolioReader,
                  readerConfig: FolioReaderConfig,
                  book: FRBook,
                  delegate: FolioReaderListDelegate?) {
        self.readerConfig = readerConfig
        self.folioReader = folioReader
        self.delegate = delegate
        self.book = book
    }
    
    private func configurateTable() {
        self.tableView.register(UINib(nibName: "FolioReaderBookmarkListCell", bundle: Bundle.frameworkBundle()), forCellReuseIdentifier: kReuseCellIdentifier)
    }
    
    override open func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
        super.didRotate(from: fromInterfaceOrientation)
        view.layoutIfNeeded()
    }
    
    func remove(bookmark: BookmarkStruct, indexPath: IndexPath) {
        Bookmark.remove(bookmarkWithUpdateDate: bookmark.createdDateString, withConfiguration: readerConfig)
        tocItems.remove(at: indexPath.row)
        tableView.reloadData()
        folioReader.readerCenter?.currentPage?.checkBookMarks()
    }
}

extension FolioReaderBookmarkList: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tocItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: kReuseCellIdentifier) as! FolioReaderBookmarkListCell
        let bookmark = tocItems[indexPath.row]
        
        let allCountPages = folioReader.readerCenter?.readerProgressManager?.allCountPages ?? 1
        let pagePositionInBook = Int(Float(allCountPages) * bookmark.pagePositionInBook)

        cell.bookmarkTitle.text = String(format: NSLocalizedString("%d pages", comment: ""), pagePositionInBook)
        cell.characterLabel.text = String(format: NSLocalizedString("%d numberChapter", comment: ""), bookmark.chapterIndex)
        cell.removeBlock = { [weak self] in
            self?.remove(bookmark: bookmark, indexPath: indexPath)
        }
        return cell
    }
}

extension FolioReaderBookmarkList: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let bookmark = tocItems[indexPath.row]

        folioReader.readerCenter?.goToBookMark(bookmark: bookmark)
        self.dismiss(animated: true, completion: nil)
    }
}



