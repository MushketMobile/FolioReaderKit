//
//  ReaderNavigationBar.swift
//  Pods
//
//  Created by Admin on 30.08.17.
//
//

import Foundation

class ReaderNavBar: UIView {

    weak var folioReaderCenter: FolioReaderCenter?
    weak var readerFontsMenu: FolioReaderFontsMenu?
    weak var pageViewController: PageViewController?
    weak var folioReaderWebView: FolioReaderWebView?
    
    class func instanceFromNib() -> ReaderNavBar {
        return UINib(nibName: "ReaderNavBar", bundle: Bundle.main).instantiate(withOwner: nil, options: nil)[0] as! ReaderNavBar
    }

    @IBAction func setupReaderSettings(_ sender: Any) {
        folioReaderCenter?.presentFontsMenu()
    }
    
    @IBAction func searchAction(_ sender: Any) {
        folioReaderCenter?.presentSearch()
    }
    
    @IBAction func actionBtn(_ sender: Any) {
        folioReaderCenter?.presentChapterList()
    }

    @IBAction func closeReader(_ sender: Any) {
        folioReaderCenter?.closeReader()
    }
}
