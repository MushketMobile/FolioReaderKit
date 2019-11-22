//
//  FolioReaderHighLightList.swift
//  Pods
//
//  Created by Admin on 08.09.17.
//
//

import Foundation

class FRHighlightList: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    weak var delegate: FolioReaderListDelegate?
    fileprivate var tocItems = [Highlight]()
    fileprivate var book: FRBook!
    fileprivate var readerConfig: FolioReaderConfig!
    fileprivate var folioReader: FolioReader!
    let dateFormatter = DateFormatter()
    @IBOutlet weak var backgroundImageView: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()
        configurateTable()
        
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        
        let items = Highlight.all(withConfiguration: readerConfig)
        tocItems = items
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
        self.tableView.register(UINib(nibName: "FRHighlightListCell", bundle: Bundle.frameworkBundle()), forCellReuseIdentifier: kReuseCellIdentifier)
        tableView.estimatedRowHeight = 130
        tableView.rowHeight = UITableViewAutomaticDimension
    }
    override open func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
        super.didRotate(from: fromInterfaceOrientation)
        self.view.layoutIfNeeded()
    }
    
    func remove(highlight: Highlight, indexPath: IndexPath) {
        highlight.remove(withConfiguration: readerConfig)
        tocItems.remove(at: indexPath.row)
        tableView.reloadData()
        folioReader.readerCenter?.reloadData()
    }
}

extension FRHighlightList: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tocItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: kReuseCellIdentifier) as! FRHighlightListCell
        let highlight = tocItems[indexPath.row]
        
        cell.highlightText.text = highlight.title
        cell.characterLabel.text = String(format: NSLocalizedString("%d numberChapter", comment: ""), highlight.page)
        
        cell.dateText.text = highlight.createdDateString
        
        if highlight.isNote { cell.noteText.text = highlight.note }
        else { cell.noteText.isHidden = true }
        
        cell.removeBlock = { [weak self] in
            self?.remove(highlight: highlight, indexPath: indexPath)
        }
        cell.setNeedsUpdateConstraints()
        cell.updateConstraintsIfNeeded()
        return cell
    }
}

extension FRHighlightList: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let highlight = tocItems[indexPath.row]
        
        folioReader.readerCenter?.changePageWith(page: highlight.page, andFragment: highlight.highlightId, isNoteExist: highlight.isNote)
        self.dismiss(animated: true, completion: nil)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        let highlight = tocItems[indexPath.row]
        if highlight.isNote { return 130 }
        else { return 85 }
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
}
