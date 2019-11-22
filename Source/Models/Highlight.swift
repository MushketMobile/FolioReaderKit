//
//  Highlight.swift
//  FolioReaderKit
//
//  Created by Heberti Almeida on 11/08/15.
//  Copyright (c) 2015 Folio Reader. All rights reserved.
//

import Foundation
import RealmSwift

/// A Highlight object
open class Highlight: Object {
    @objc open dynamic var bookId: String!
    @objc open dynamic var userId: String!
    @objc open dynamic var content: String!
    @objc open dynamic var contentPost: String!
    @objc open dynamic var contentPre: String!
    @objc open dynamic var createdDateString: String!
    @objc open dynamic var highlightId: String!
    @objc open dynamic var page: Int = 0
    @objc open dynamic var pages: Int = 0
    @objc open dynamic var type: Int = 0
    @objc open dynamic var startOffset: Int = -1
    @objc open dynamic var endOffset: Int = -1
    @objc open dynamic var bookmarkServerId: Int = -1
    @objc open dynamic var title: String!
    @objc open dynamic var note: String!
    @objc open dynamic var isNote = false

    override open class func primaryKey()-> String {
        return "highlightId"
    }
    
    open func json() -> Dictionary<String, Any> {
        return ["userId" : userId,
                "bookId" : bookId,
                "content" : content,
                "contentPost" : contentPost,
                "contentPre" : contentPre,
                "createdDateString" : createdDateString,
                "highlightId" : highlightId,
                "page" : page,
                "pages" : pages,
                "type" : type,
                "startOffset" : startOffset,
                "endOffset" : endOffset,
                "bookmarkServerId" : bookmarkServerId,
                "title" : title,
                "note" : note,
                "isNote" : isNote]
    }
}

extension Results {
    func toArray<T>(_ ofType: T.Type) -> [T] {
        return compactMap { $0 as? T }
    }
}
