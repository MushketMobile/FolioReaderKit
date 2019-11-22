//
//  Bookmark.swift
//  AEXML
//
//  Created by Aleksandr Vdovichenko on 3/7/18.
//

import Foundation
import RealmSwift

//values.put(BooksDBContract.BookMarkups.USER_ID, userId);
//values.put(BooksDBContract.BookMarkups.BOOK_SKU, bookSku);
//values.put(BooksDBContract.BookMarkups.BOOK_CODE, bc);
//values.put(BooksDBContract.BookMarkups.CHAPTER_INDEX, ci);
//values.put(BooksDBContract.BookMarkups.CHAPTER_TITLE, title);
//values.put(BooksDBContract.BookMarkups.PAGE_POSITION_IN_CHAPTER, ppc);
//values.put(BooksDBContract.BookMarkups.PAGE_POSITION_IN_BOOK, ppb);
//values.put(BooksDBContract.BookMarkups.PAGE_INDEX_IN_BOOK, piib);
//values.put(BooksDBContract.BookMarkups.CREATED_DATE, dateInString);

open class Bookmark: Object {
    @objc open dynamic var userId: String!
    @objc open dynamic var bookSku: String!
    @objc open dynamic var bookName: String!
    @objc open dynamic var chapterIndex: Int = 0
    @objc open dynamic var pagePositionInChapter: Float = 0.0
    @objc open dynamic var pagePositionInBook: Float = 0.0
    @objc open dynamic var pageIndexInBook: Int = 0
    @objc open dynamic var createdDateString: String = ""

    override open class func primaryKey()-> String {
        return "createdDateString"
    }
    
    open func json() -> Dictionary<String, Any> {
        return ["userId" : userId,
                "bookSku" : bookSku,
                "bookName" : bookName,
                "chapterIndex" : chapterIndex,
                "pagePositionInChapter" : pagePositionInChapter,
                "pagePositionInBook" : pagePositionInBook,
                "pageIndexInBook" : pageIndexInBook,
                "createdDateString" : createdDateString]
    }
}

extension Bookmark {
//    SkyEpub uses pagePositionInBook double value to locate the exact position in epub.
//    In Reflowable Layout in epub, there’s no fixed page index because total page number will be
//    changed according to screen size, font and font size, line space or etc.
//    So we need to think about another concept to express the one position in book for navigation
//    or bookmark.
//    pagePosition could be calculated as blow.
//    so to locate a specific position in book, you need to use pagePositionInBook concept.
//    assuming that you have 3 chapters in epub, and if you want to goto 25% of second
//    chapter.
//    Assuming that there are 3 chapters (which is defined in spine tag of opf file) in a epub and if
//    you want to goto 25% of 2nd chapter.
//    numberOfChapter = 3;
//    chapterDelta = 1/numberOfChapter;
//    chapterIndex = 1;
//    positionInChapter = 0.25;
//    pagePositionInBook = chapterDelta* chapterIndex +
//    chapterDelta*positionInChapter;
//    e.g) pagePositionInBook = (1/3)*1 + (1/3)*.25 = 0.416667f
    
    static func save(_ readerCenter: FolioReaderCenter, completion: Completion?) {
        guard let readerConfig = readerCenter.readerContainer?.readerConfig, let readerProgressManager = readerCenter.readerProgressManager  else { return }
        var bookMark = Bookmark()
        bookMark.userId = readerConfig.userId
        bookMark.bookSku = readerConfig.bookSku
        bookMark.bookName = readerConfig.bookTitle ?? ""
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = readerConfig.localizedHighlightsDateFormat
        dateFormatter.locale = Locale.current
        bookMark.createdDateString = dateFormatter.string(from: Foundation.Date())
        
        let currentPage = readerProgressManager.currentPage
        bookMark.pageIndexInBook = currentPage
        
        let chapterIndex = readerCenter.currentPageNumber - 1
        bookMark.chapterIndex = chapterIndex

        let pageWidth = Float(readerCenter.pageWidth)
        let pagesInChapter = Float(readerProgressManager.currentTotalPages(section: chapterIndex))
        
        guard let pageWebView = readerCenter.currentPage else { return }
        let contentOffsetY = Float(pageWebView.webView.scrollView.contentSize.width - pageWebView.webView.scrollView.contentOffset.x)
        let tempWidth: Float = pagesInChapter * pageWidth
        if contentOffsetY > 0 && tempWidth > 0  {
            bookMark.pagePositionInChapter = Float(contentOffsetY/tempWidth)
        }

        let totalPages = readerProgressManager.allCountPages
        if totalPages > 0 {
            bookMark.pagePositionInBook = Float(Float(currentPage)/Float(totalPages))
        }
        do {
            let realm = try Realm(configuration: readerConfig.realmConfiguration)
            realm.beginWrite()
            realm.add(bookMark, update: true)
            try realm.commitWrite()
            completion?(nil)
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "com.app.GetBooksApp.Notification.Name.Bookmark.add"),
                                            object: nil,
                                            userInfo: ["bookmark": bookMark])
        } catch let error as NSError {
            print("Error on persist highlight: \(error)")
            completion?(error)
        }
    }
    
    open static func allOld(withConfiguration readerConfig: FolioReaderConfig) -> [Bookmark] {
        var bookmarks: [Bookmark] = []
        
        var predicate = NSPredicate(format: "bookSku = %@ AND userId = %@", readerConfig.bookSku, readerConfig.userId)
        
        do {
            let realm = try Realm(configuration: readerConfig.realmConfiguration)
            bookmarks = realm.objects(Bookmark.self).filter(predicate).toArray(Bookmark.self)
            return bookmarks
        } catch let error as NSError {
            print("Error on fetch all by book Id: \(error)")
            return []
        }
    }
    
    open static func all(withConfiguration readerConfig: FolioReaderConfig) -> [Bookmark] {
        var bookmarks: [Bookmark] = []
        
        var predicate = NSPredicate(format: "bookSku = %@ AND userId = %@", readerConfig.bookSku, readerConfig.userId)
       
        do {
            let realm = try Realm(configuration: readerConfig.realmConfiguration)
            bookmarks = realm.objects(Bookmark.self).filter(predicate).toArray(Bookmark.self)
            return bookmarks
        } catch let error as NSError {
            print("Error on fetch all by book Id: \(error)")
            return []
        }
    }
    
    static func all(withConfiguration readerConfig: FolioReaderConfig, andChapterIndex chapterIndex: Int) -> [Bookmark] {
        var bookmarks: [Bookmark] = []
        var predicate = NSPredicate(format: "bookSku = %@ AND userId = %@ AND chapterIndex = \(chapterIndex)", readerConfig.bookSku, readerConfig.userId)
        do {
            let realm = try Realm(configuration: readerConfig.realmConfiguration)
            bookmarks = realm.objects(Bookmark.self).filter(predicate).toArray(Bookmark.self)
            return bookmarks
        } catch let error as NSError {
            print("Error on fetch all by book Id: \(error)")
            return []
        }
    }
    
    func remove(withConfiguration readerConfig: FolioReaderConfig, completion: Completion? = nil) {
        do {
            guard let realm = try? Realm(configuration: readerConfig.realmConfiguration) else { return }
            try realm.write {
                realm.delete(self)
                try realm.commitWrite()
                completion?(nil)
            }
        } catch let error as NSError {
            print("Error on remove highlight: \(error)")
            completion?(error)
        }
    }
    
    static func remove(bookmarkWithUpdateDate date: String, withConfiguration readerConfig: FolioReaderConfig){
        var predicate = NSPredicate(format: "createdDateString = %@", date)
        do {
            let realm = try Realm(configuration: readerConfig.realmConfiguration)
            guard let bookmark = realm.objects(Bookmark.self).filter(predicate).toArray(Bookmark.self).first else { return }
            try realm.write {
                realm.delete(bookmark)
                try realm.commitWrite()
            }
        } catch let error as NSError {
            print("Error on fetch all by book Id: \(error)")
        }
    }
}
