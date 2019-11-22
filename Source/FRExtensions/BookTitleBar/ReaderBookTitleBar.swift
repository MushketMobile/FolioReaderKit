//
//  ReaderBookTitleBar.swift
//  Pods
//
//  Created by Admin on 13.09.17.
//
//

import Foundation

class ReaderBookTitleBar: UIView {
    
    weak var folioReaderCenter: FolioReaderCenter?
    
    @IBOutlet weak var bookTitle: UILabel!
    
    class func instanceFromNib() -> ReaderBookTitleBar {
        return UINib(nibName: "ReaderBookTitleBar", bundle: Bundle.frameworkBundle()).instantiate(withOwner: nil, options: nil)[0] as! ReaderBookTitleBar
    }
}

