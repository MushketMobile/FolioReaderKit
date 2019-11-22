//
//  HighlightMenu.swift
//  Pods
//
//  Created by Admin on 11.09.17.
//
//

import Foundation

class HighlightMenu: UIView {
    
    weak var folioReaderWebView: FolioReaderWebView?
    var selectedText: String? {
        return folioReaderWebView?.js("getSelectedText()") as? String
    }

    class func instanceFromNib() -> HighlightMenu {
        return UINib(nibName: "HighlightMenu", bundle: Bundle.frameworkBundle()).instantiate(withOwner: nil, options: nil)[0] as! HighlightMenu
    }
  
    class func colorMenuInstanceFromNib() -> HighlightMenu {
        return UINib(nibName: "ColorMenuDelete", bundle: Bundle.frameworkBundle()).instantiate(withOwner: nil, options: nil)[0] as! HighlightMenu
    }
    
    @IBAction func chooseColor(_ sender: Any) {
        delay(0.2) { [weak self] in
            if self?.folioReaderWebView?.highlight(nil) == true, let center = self?.center {
                let point = CGPoint(x: center.x, y: (self?.frame.minY)! - 16)
                self?.folioReaderWebView?.showHilightMenu(touchPoint: point)
            } else {

                UIAlertView.init(title: String(format: NSLocalizedString("Alert.Common.error", comment: "")), message: String(format: NSLocalizedString("Alert.Common.paragraphHighlight", comment: "")), delegate: nil, cancelButtonTitle: NSLocalizedString("Alert.Common.ok", comment: "")).show()
            }
        }
    }
    
    @IBAction func addNote(_ sender: Any) {
        delay(0.2) { [weak self] in
            if self?.folioReaderWebView?.highlightForNote(nil) == true {
                self?.folioReaderWebView?.showNote()
                self?.folioReaderWebView?.noteWindow?.noteView.isEditable = true
                self?.folioReaderWebView?.noteWindow?.noteView.becomeFirstResponder()
            } else {
                UIAlertView.init(title: "Error", message: "You need to choose one paragraph", delegate: nil, cancelButtonTitle: "Ok").show()
            }
        }
    }
    
    @IBAction func deleteHighlight(_ sender: Any) {
        folioReaderWebView?.remove(nil)
        folioReaderWebView?.hiddenMenu()
    }
    
    @IBAction func shareAction(_ sender: Any) {
        var shareText = selectedText
        if shareText == nil {
            if let highlightId = folioReaderWebView?.js("removeThisHighlight()"),
                let highlight = Highlight.byId(withConfiguration: folioReaderWebView?.readerContainer?.readerConfig ?? FolioReaderConfig(), highlightId: highlightId) {
                shareText = highlight.content
            } else {
                return
            }
        }
        let userInfo = ["selectedText" : shareText]
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "com.app.GetBooksApp.Notification.Name.Facebook.share"),
                                        object: nil,
                                        userInfo: userInfo)
        folioReaderWebView?.hiddenMenu()
    }
    
    @IBAction func yellowHighlight(_ sender: Any) {
        folioReaderWebView?.setYellow(nil)
        folioReaderWebView?.hiddenMenu()
    }
    
    @IBAction func blueHighlight(_ sender: Any) {
        folioReaderWebView?.setBlue(nil)
        folioReaderWebView?.hiddenMenu()
    }
    
    @IBAction func greenHighlight(_ sender: Any) {
        folioReaderWebView?.setGreen(nil)
        folioReaderWebView?.hiddenMenu()
    }
    
    @IBAction func pinkHighlight(_ sender: Any) {
        folioReaderWebView?.setPink(nil)
        folioReaderWebView?.hiddenMenu()
    }
}
