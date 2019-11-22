//
//  FolioReaderChapterList.swift
//  FolioReaderKit
//
//  Created by Heberti Almeida on 15/04/15.
//  Copyright (c) 2015 Folio Reader. All rights reserved.
//

import UIKit

/// Table Of Contents delegate
@objc protocol FolioReaderListDelegate: class {
    /**
     Notifies when the user selected some item on menu.
     */
    func selectItemList(didSelectRowAtIndexPath indexPath: IndexPath, withTocReference reference: FRTocReference)

    /**
     Notifies when chapter list did totally dismissed.
     */
    func dismissList()
}


class FolioReaderChapterList: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    weak var delegate: FolioReaderListDelegate?
    fileprivate var tocItems = [FRTocReference]()
    fileprivate var book: FRBook!
    fileprivate var readerConfig: FolioReaderConfig!
    fileprivate var folioReader: FolioReader!
    @IBOutlet weak var backgroundImageView: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()
        configurateTable()
        tocItems = book.flatTableOfContents
        updateBackgroundImage()
    }
    
    func updateBackgroundImage() {
        if DeviceType.IS_IPAD, UIApplication.shared.statusBarOrientation.isLandscape {
            backgroundImageView.image = #imageLiteral(resourceName: "background_image_landscape")
        } else if DeviceType.IS_IPHONE_X {
            backgroundImageView.image = #imageLiteral(resourceName: "background_image_X")
        } else {
            backgroundImageView.image = #imageLiteral(resourceName: "background_image")
        }
    }
    
    open func add(folioReader: FolioReader,
                  readerConfig: FolioReaderConfig,
                  book: FRBook,
                  delegate: FolioReaderListDelegate?) {
        self.readerConfig = readerConfig
        self.folioReader = folioReader
        self.delegate = delegate
        self.book = book
    }
    
    private func configurateTable() {
        self.tableView.register(UINib(nibName: "FolioReaderChapterListCell", bundle: Bundle.frameworkBundle()), forCellReuseIdentifier: kReuseCellIdentifier)
    }
    
    override open func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
        super.didRotate(from: fromInterfaceOrientation)
        self.view.layoutIfNeeded()
    }
}

extension FolioReaderChapterList: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tocItems.count
    }

     func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: kReuseCellIdentifier) as! FolioReaderChapterListCell
        cell.setup(withConfiguration: readerConfig)
        let tocReference = tocItems[indexPath.row]
        cell.indexLabel.text = tocReference.title.trimmingCharacters(in: .whitespacesAndNewlines)
        cell.characterLabel.text = String(format: NSLocalizedString("%d numberChapter", comment: ""), indexPath.row + 1)

        return cell
    }
}

extension FolioReaderChapterList: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let tocReference = tocItems[indexPath.row]
        delegate?.selectItemList(didSelectRowAtIndexPath: indexPath, withTocReference: tocReference)
        tableView.deselectRow(at: indexPath, animated: true)
        dismiss { self.delegate?.dismissList() }
    }
}
