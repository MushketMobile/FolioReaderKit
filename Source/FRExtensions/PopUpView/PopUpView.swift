//
//  PopUpView.swift
//  FolioReaderKit
//
//  Created by Administrator on 24.01.2018.
//

import Foundation

class PopUpView: UIView {
    
    @IBOutlet weak var popUpView: UIView!
    @IBOutlet weak var popUpTitle: UILabel!
    @IBOutlet weak var popUpLabel: UILabel!
    
    weak var folioReaderCenter: FolioReaderCenter?
    
    class func instanceFromNib() -> PopUpView {
        return UINib(nibName: "PopUpView", bundle: Bundle.frameworkBundle()).instantiate(withOwner: nil, options: nil)[0] as! PopUpView
    }
    
}
