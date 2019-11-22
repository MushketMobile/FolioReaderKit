//
//  Comments.swift
//  Pods
//
//  Created by Admin on 17.10.17.
//
//

class Note: UIView {
    @IBOutlet weak var noteView: UITextView!
    @IBOutlet weak var exit: UIButton!
    @IBOutlet weak var save: UIButton!

    weak var folioReaderWebView: FolioReaderWebView?
    var selectedText: String?
    var highlightTuple: (String, String)?
    

    class func instanceFromNib() -> Note {
        return UINib(nibName: "Note", bundle: Bundle.frameworkBundle()).instantiate(withOwner: nil, options: nil)[0] as! Note
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        layer.borderWidth = 2.0
        layer.borderColor = UIColor.gray.cgColor
        exit.setTitle(NSLocalizedString("FilioReader.ReaderNote.Exit", comment: "FilioReader.ReaderFontsMenu: power of light name title letter 'A'"), for: .normal)
        save.setTitle(NSLocalizedString("FilioReader.ReaderNote.Save", comment: "FilioReader.ReaderFontsMenu: power of light name title letter 'A'"), for: .normal)
    }
    
    @IBAction func exit(_ sender: Any) {
        if highlightTuple == nil {
            folioReaderWebView?.remove(nil)
        }
        folioReaderWebView?.hiddenNote()
    }
    
    @IBAction func save(_ sender: Any) {
        if noteView.text.characters.count == 0 { return }
        delay(0.2) { [weak self] in
            if self?.highlightTuple != nil {
                let highlight = Highlight.byId(withConfiguration: (self?.folioReaderWebView?.readerContainer?.readerConfig) ?? FolioReaderConfig(), highlightId: self?.highlightTuple?.0 ?? "")
                
                highlight?.updateNote(note: self?.noteView.text ?? "",
                                            withConfiguration: (self?.folioReaderWebView?.readerContainer?.readerConfig) ?? FolioReaderConfig())
                self?.folioReaderWebView?.readerContainer?.centerViewController?.currentPage?.addNotesIfNeeded()
                self?.folioReaderWebView?.hiddenNote()

                return
            }
            if self?.folioReaderWebView?.createHighlightForNote(nil) == true {
                self?.folioReaderWebView?.hiddenNote()
            } else {
                UIAlertView.init(title: "Error", message: "You need to choose one paragraph", delegate: nil, cancelButtonTitle: "Ok").show()
            }
        }
    }
}
