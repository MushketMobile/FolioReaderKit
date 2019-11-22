//
//  Progress.swift
//  Pods
//
//  Created by Aleksandr Vdovichenko on 9/5/17.
//
//

import Foundation
import RealmSwift

open class Section: Object {
    @objc open dynamic var сhapter: Int = 0
    @objc open dynamic var pages: Int = 0
}

open class ProgressModel: Object {
    @objc open dynamic var bookId: String = ""
    @objc open dynamic var landscapeWidth: Float = 0.0
    @objc open dynamic var landscapeHeight: Float = 0.0
    @objc open dynamic var portraitWidth: Float = 0.0
    @objc open dynamic var portraitHeight: Float = 0.0
    @objc open dynamic var fontName: String = ""
    @objc open dynamic var fontSize: String = ""
    @objc open dynamic var spaceLine: String = ""
    @objc open dynamic var totalPageLanscape: Int = 0
    @objc open dynamic var totalPagePortrait: Int = 0
    @objc open dynamic var pading: Int = 0

    open var sectionsLanscape = List<Section>()
    open var sectionsPortrait = List<Section>()

//    override open class func primaryKey()-> String {
//        return "highlightId"
//    }
}
