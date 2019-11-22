//
//  ReaderSearchBar.swift
//  Pods
//
//  Created by Aleksandr Vdovichenko on 9/11/17.
//
//

class ReaderSearchBar: UIView {
    @IBOutlet weak var searchTextFiled: UITextField!
    @IBOutlet weak var searchButton: UIButton!

    weak var folioReaderCenter: FolioReaderCenter?
    
    class func instanceFromNib() -> ReaderSearchBar {
        return UINib(nibName: "ReaderSearchBar", bundle: Bundle.frameworkBundle()).instantiate(withOwner: nil, options: nil)[0] as! ReaderSearchBar
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        let path = UIBezierPath(roundedRect: searchButton.bounds, byRoundingCorners: [.topLeft, .bottomLeft], cornerRadii: CGSize(width: 20, height: 20))
        let maskLayer = CAShapeLayer()
        
        maskLayer.path = path.cgPath
        searchButton.layer.mask = maskLayer
    }
    
    @IBAction func searchTapped(_ sender: Any) {
        guard let text = searchTextFiled.text else { return }
        if text.characters.count == 0 { return }
        folioReaderCenter?.search(text: text)
    }

}
