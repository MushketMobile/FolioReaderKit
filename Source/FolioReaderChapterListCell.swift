//
//  FolioReaderChapterListCell.swift
//  FolioReaderKit
//
//  Created by Heberti Almeida on 07/05/15.
//  Copyright (c) 2015 Folio Reader. All rights reserved.
//

class FolioReaderChapterListCell: UITableViewCell {
    @IBOutlet weak var binButton: UIButton!
    @IBOutlet weak var bookmarkButton: UIButton!
    @IBOutlet weak var indexLabel: UILabel!
    @IBOutlet weak var characterLabel: UILabel!

    func setup(withConfiguration readerConfig: FolioReaderConfig) {
        indexLabel.textColor = readerConfig.menuTextColor
    }
}
