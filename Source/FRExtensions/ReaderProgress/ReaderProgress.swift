//
//  ReaderProgress.swift
//  Pods
//
//  Created by Aleksandr Vdovichenko on 9/4/17.
//
//

open class ReaderProgress: UIView {
    @IBOutlet weak var progressLabel: UILabel!
    @IBOutlet weak var countLabel: UILabel!
    @IBOutlet weak var slider: UISlider!
    @IBOutlet weak var loadingView: UIView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    weak var folioReaderCenter: FolioReaderCenter?
    
    class func instanceFromNib() -> ReaderProgress {
        return UINib(nibName: "ReaderProgress", bundle: Bundle.frameworkBundle()).instantiate(withOwner: nil, options: nil)[0] as! ReaderProgress
    }
    
    override open func awakeFromNib() {
        super.awakeFromNib()
        slider.addTarget(self, action: #selector(sliderDidEndSliding), for: [.touchUpInside, .touchUpOutside])
        slider.transform = CGAffineTransform(scaleX: -1, y: 1)
    }
    
    func addObservers() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(updateUI),
                                               name: NSNotification.Name(rawValue: "com.app.GetBooksApp.Notification.Name.Progress.update"),
                                               object: nil)
    }
    
    @objc func sliderDidEndSliding() {
        let value = Int(slider.value)
        let optional = folioReaderCenter?.readerProgressManager?.getBookPageToScroll(for:value)
        guard let internalPage = optional?.1  else { return }
        folioReaderCenter?.changePageTo(chapter: (optional?.0)!, page: internalPage)
    }
    
    func configurateScroll() {
        slider.minimumValue = 1.0
        guard let totalPages = folioReaderCenter?.readerProgressManager?.totalPages else { return }
        slider.maximumValue = Float(totalPages)
    }
    
    @objc func updateUI() {
        guard let reader = folioReaderCenter else { return }
        guard let progressManager = reader.readerProgressManager else { return }

        if progressManager.isLoading == true {
            loadingView.isHidden = false
            if reader.popUpShouldHide {
                reader.presentPopUpView()
            }
        } else {
            guard let currentPage = folioReaderCenter?.readerProgressManager?.currentPage else { return }
            progressLabel.text = folioReaderCenter?.readerProgressManager?.persent
            countLabel.text = folioReaderCenter?.readerProgressManager?.currentPagesTitle
            slider.value = Float(currentPage)
            loadingView.isHidden = true
            reader.closePopUpView()
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "com.app.GetBooksApp.Notification.Name.Book.update"),
                                            object: nil,
                                            userInfo: nil)
        }
    }
    
    @IBAction func sliderChanged(_ sender: UISlider) {
        guard let totalPages = folioReaderCenter?.readerProgressManager?.totalPages, totalPages > 0 else { return }
        if sender.value < 1 { return }
        countLabel.text = "\(Int(sender.value))/\(totalPages)"
        progressLabel.text = "\(Int(Int(sender.value) * 100 / totalPages))%"
    }
}
