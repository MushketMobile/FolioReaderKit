//
//  FolioReaderHighLightListCell.swift
//  Pods
//
//  Created by Admin on 08.09.17.
//
//

import Foundation

class FRHighlightListCell: UITableViewCell {
    @IBOutlet weak var highlightText: UILabel!
    @IBOutlet weak var characterLabel: UILabel!
    @IBOutlet weak var dateText: UILabel!
    
    @IBOutlet weak var noteText: UILabel!
    var removeBlock: (() -> Void) = {}

    @IBAction func deleteHighlight(_ sender: Any) {
        removeBlock()
    }
}
