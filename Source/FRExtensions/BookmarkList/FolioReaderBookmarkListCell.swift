//
//  FolioReaderBookmarkListCell.swift
//  Pods
//
//  Created by Admin on 08.09.17.
//
//

class FolioReaderBookmarkListCell: UITableViewCell {
    @IBOutlet weak var bookmarkTitle: UILabel!
    @IBOutlet weak var characterLabel: UILabel!
    var removeBlock: (() -> Void) = {}
    
    @IBAction func deleteBookmarkAction(_ sender: Any) {
        removeBlock()
    }
}
