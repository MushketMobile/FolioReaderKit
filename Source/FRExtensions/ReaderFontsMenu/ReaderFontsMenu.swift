//
//  ReaderFontsSettings.swift
//  Pods
//
//  Created by Admin on 31.08.17.
//
//

import Foundation

enum FontSizeState {
    case one
    case two
    case three
    case four
    case five
    case six
    case seven
    case eight
    case nine
}

class ReaderFontsMenu: UIView, UIGestureRecognizerDelegate {
    weak var folioReaderFontsMenu: FolioReaderFontsMenu?
    
    @IBOutlet weak var fontsMenuGestureRecognizer: UITapGestureRecognizer!
    @IBOutlet weak var tapCloseView: UIView!
    @IBOutlet weak var fontsMenuView: UIView!
    @IBOutlet weak var screenBrightnessSlider: UISlider!
    @IBOutlet weak var fontSizeStepper: UIStepper!
    @IBOutlet weak var fontChoiceSlider: UISlider!
    @IBOutlet weak var fontDavid: UIButton!
    @IBOutlet weak var fontFrankRuhel: UIButton!
    @IBOutlet weak var fontHadasim: UIButton!
    @IBOutlet weak var fontShofar: UIButton!
    @IBOutlet weak var fontSizeOne: UIView!
    @IBOutlet weak var fontSizeTwo: UIView!
    @IBOutlet weak var fontSizeThree: UIView!
    @IBOutlet weak var fontSizeFour: UIView!
    @IBOutlet weak var fontSizeFive: UIView!
    @IBOutlet weak var fontSizeSix: UIView!
    @IBOutlet weak var fontSizeSeven: UIView!
    @IBOutlet weak var fontSizeEight: UIView!
    @IBOutlet weak var fontSizeNine: UIView!

    @IBOutlet weak var whiteBackgroundButton: UIButton!
    @IBOutlet weak var blackBackgroundButton: UIButton!
    @IBOutlet weak var milkBackgroundButton: UIButton!
    @IBOutlet weak var bigCellButton: UIButton!
    @IBOutlet weak var middleCellButton: UIButton!
    @IBOutlet weak var smallCellButton: UIButton!
    @IBOutlet weak var bigFrameButton: UIButton!
    @IBOutlet weak var middleFrameButton: UIButton!
    @IBOutlet weak var smallFrameButton: UIButton!

    var fontSizeState: FontSizeState = .three { didSet { updateIndicator() }}

    class func instanceFromNib(nibName: String) -> ReaderFontsMenu {
        return UINib(nibName: nibName, bundle: Bundle.main).instantiate(withOwner: nil, options: nil)[0] as! ReaderFontsMenu
    }
    
    func setupUI(readerView: UIView) {
        fontsMenuView.layer.borderWidth = 0.5
        fontsMenuView.layer.borderColor = UIColor.black.cgColor

        fontSizeStepper.layer.cornerRadius = 15.0
        fontSizeStepper.layer.borderWidth = 1.5
        fontSizeStepper.layer.borderColor = UIColor(rgba: "#CAE0FF").cgColor
        fontSizeStepper.layer.masksToBounds = true
        fontSizeStepper.setIncrementImage(#imageLiteral(resourceName: "plus_book_settings"), for: .normal)
        fontSizeStepper.setDecrementImage(#imageLiteral(resourceName: "minus_book_settings"), for: .normal)

        fontChoiceSlider.transform = CGAffineTransform(rotationAngle: CGFloat(-M_PI_2))
        screenBrightnessSlider.value = Float(UIScreen.main.brightness)
        updateIndicator()
        updateButtonStates()
    }
    
    func updateIndicator() {
        
        switch fontSizeState {
        case .one:
            fontSizeOne.backgroundColor = folioReaderFontsMenu?.readerConfig?.fontSizeIndicatorOn
            fontSizeTwo.backgroundColor = folioReaderFontsMenu?.readerConfig?.fontSizeIndicatorOff
            fontSizeThree.backgroundColor = folioReaderFontsMenu?.readerConfig?.fontSizeIndicatorOff
            fontSizeFour.backgroundColor = folioReaderFontsMenu?.readerConfig?.fontSizeIndicatorOff
            fontSizeFive.backgroundColor = folioReaderFontsMenu?.readerConfig?.fontSizeIndicatorOff
            fontSizeSix.backgroundColor = folioReaderFontsMenu?.readerConfig?.fontSizeIndicatorOff
            fontSizeSeven.backgroundColor = folioReaderFontsMenu?.readerConfig?.fontSizeIndicatorOff
            fontSizeEight.backgroundColor = folioReaderFontsMenu?.readerConfig?.fontSizeIndicatorOff
            fontSizeNine.backgroundColor = folioReaderFontsMenu?.readerConfig?.fontSizeIndicatorOff
        case .two:
            fontSizeOne.backgroundColor = folioReaderFontsMenu?.readerConfig?.fontSizeIndicatorOff
            fontSizeTwo.backgroundColor = folioReaderFontsMenu?.readerConfig?.fontSizeIndicatorOn
            fontSizeThree.backgroundColor = folioReaderFontsMenu?.readerConfig?.fontSizeIndicatorOff
            fontSizeFour.backgroundColor = folioReaderFontsMenu?.readerConfig?.fontSizeIndicatorOff
            fontSizeFive.backgroundColor = folioReaderFontsMenu?.readerConfig?.fontSizeIndicatorOff
            fontSizeSix.backgroundColor = folioReaderFontsMenu?.readerConfig?.fontSizeIndicatorOff
            fontSizeSeven.backgroundColor = folioReaderFontsMenu?.readerConfig?.fontSizeIndicatorOff
            fontSizeEight.backgroundColor = folioReaderFontsMenu?.readerConfig?.fontSizeIndicatorOff
            fontSizeNine.backgroundColor = folioReaderFontsMenu?.readerConfig?.fontSizeIndicatorOff

        case .three:
            fontSizeOne.backgroundColor = folioReaderFontsMenu?.readerConfig?.fontSizeIndicatorOff
            fontSizeTwo.backgroundColor = folioReaderFontsMenu?.readerConfig?.fontSizeIndicatorOff
            fontSizeThree.backgroundColor = folioReaderFontsMenu?.readerConfig?.fontSizeIndicatorOn
            fontSizeFour.backgroundColor = folioReaderFontsMenu?.readerConfig?.fontSizeIndicatorOff
            fontSizeFive.backgroundColor = folioReaderFontsMenu?.readerConfig?.fontSizeIndicatorOff
            fontSizeSix.backgroundColor = folioReaderFontsMenu?.readerConfig?.fontSizeIndicatorOff
            fontSizeSeven.backgroundColor = folioReaderFontsMenu?.readerConfig?.fontSizeIndicatorOff
            fontSizeEight.backgroundColor = folioReaderFontsMenu?.readerConfig?.fontSizeIndicatorOff
            fontSizeNine.backgroundColor = folioReaderFontsMenu?.readerConfig?.fontSizeIndicatorOff

        case .four:
            fontSizeOne.backgroundColor = folioReaderFontsMenu?.readerConfig?.fontSizeIndicatorOff
            fontSizeTwo.backgroundColor = folioReaderFontsMenu?.readerConfig?.fontSizeIndicatorOff
            fontSizeThree.backgroundColor = folioReaderFontsMenu?.readerConfig?.fontSizeIndicatorOff
            fontSizeFour.backgroundColor = folioReaderFontsMenu?.readerConfig?.fontSizeIndicatorOn
            fontSizeFive.backgroundColor = folioReaderFontsMenu?.readerConfig?.fontSizeIndicatorOff
            fontSizeSix.backgroundColor = folioReaderFontsMenu?.readerConfig?.fontSizeIndicatorOff
            fontSizeSeven.backgroundColor = folioReaderFontsMenu?.readerConfig?.fontSizeIndicatorOff
            fontSizeEight.backgroundColor = folioReaderFontsMenu?.readerConfig?.fontSizeIndicatorOff
            fontSizeNine.backgroundColor = folioReaderFontsMenu?.readerConfig?.fontSizeIndicatorOff

        case .five:
            fontSizeOne.backgroundColor = folioReaderFontsMenu?.readerConfig?.fontSizeIndicatorOff
            fontSizeTwo.backgroundColor = folioReaderFontsMenu?.readerConfig?.fontSizeIndicatorOff
            fontSizeThree.backgroundColor = folioReaderFontsMenu?.readerConfig?.fontSizeIndicatorOff
            fontSizeFour.backgroundColor = folioReaderFontsMenu?.readerConfig?.fontSizeIndicatorOff
            fontSizeFive.backgroundColor = folioReaderFontsMenu?.readerConfig?.fontSizeIndicatorOn
            fontSizeSix.backgroundColor = folioReaderFontsMenu?.readerConfig?.fontSizeIndicatorOff
            fontSizeSeven.backgroundColor = folioReaderFontsMenu?.readerConfig?.fontSizeIndicatorOff
            fontSizeEight.backgroundColor = folioReaderFontsMenu?.readerConfig?.fontSizeIndicatorOff
            fontSizeNine.backgroundColor = folioReaderFontsMenu?.readerConfig?.fontSizeIndicatorOff

        case .six:
            fontSizeOne.backgroundColor = folioReaderFontsMenu?.readerConfig?.fontSizeIndicatorOff
            fontSizeTwo.backgroundColor = folioReaderFontsMenu?.readerConfig?.fontSizeIndicatorOff
            fontSizeThree.backgroundColor = folioReaderFontsMenu?.readerConfig?.fontSizeIndicatorOff
            fontSizeFour.backgroundColor = folioReaderFontsMenu?.readerConfig?.fontSizeIndicatorOff
            fontSizeFive.backgroundColor = folioReaderFontsMenu?.readerConfig?.fontSizeIndicatorOff
            fontSizeSix.backgroundColor = folioReaderFontsMenu?.readerConfig?.fontSizeIndicatorOn
            fontSizeSeven.backgroundColor = folioReaderFontsMenu?.readerConfig?.fontSizeIndicatorOff
            fontSizeEight.backgroundColor = folioReaderFontsMenu?.readerConfig?.fontSizeIndicatorOff
            fontSizeNine.backgroundColor = folioReaderFontsMenu?.readerConfig?.fontSizeIndicatorOff

        case .seven:
            fontSizeOne.backgroundColor = folioReaderFontsMenu?.readerConfig?.fontSizeIndicatorOff
            fontSizeTwo.backgroundColor = folioReaderFontsMenu?.readerConfig?.fontSizeIndicatorOff
            fontSizeThree.backgroundColor = folioReaderFontsMenu?.readerConfig?.fontSizeIndicatorOff
            fontSizeFour.backgroundColor = folioReaderFontsMenu?.readerConfig?.fontSizeIndicatorOff
            fontSizeFive.backgroundColor = folioReaderFontsMenu?.readerConfig?.fontSizeIndicatorOff
            fontSizeSix.backgroundColor = folioReaderFontsMenu?.readerConfig?.fontSizeIndicatorOff
            fontSizeSeven.backgroundColor = folioReaderFontsMenu?.readerConfig?.fontSizeIndicatorOn
            fontSizeEight.backgroundColor = folioReaderFontsMenu?.readerConfig?.fontSizeIndicatorOff
            fontSizeNine.backgroundColor = folioReaderFontsMenu?.readerConfig?.fontSizeIndicatorOff

        case .eight:
            fontSizeOne.backgroundColor = folioReaderFontsMenu?.readerConfig?.fontSizeIndicatorOff
            fontSizeTwo.backgroundColor = folioReaderFontsMenu?.readerConfig?.fontSizeIndicatorOff
            fontSizeThree.backgroundColor = folioReaderFontsMenu?.readerConfig?.fontSizeIndicatorOff
            fontSizeFour.backgroundColor = folioReaderFontsMenu?.readerConfig?.fontSizeIndicatorOff
            fontSizeFive.backgroundColor = folioReaderFontsMenu?.readerConfig?.fontSizeIndicatorOff
            fontSizeSix.backgroundColor = folioReaderFontsMenu?.readerConfig?.fontSizeIndicatorOff
            fontSizeSeven.backgroundColor = folioReaderFontsMenu?.readerConfig?.fontSizeIndicatorOff
            fontSizeEight.backgroundColor = folioReaderFontsMenu?.readerConfig?.fontSizeIndicatorOn
            fontSizeNine.backgroundColor = folioReaderFontsMenu?.readerConfig?.fontSizeIndicatorOff

        case .nine:
            fontSizeOne.backgroundColor = folioReaderFontsMenu?.readerConfig?.fontSizeIndicatorOff
            fontSizeTwo.backgroundColor = folioReaderFontsMenu?.readerConfig?.fontSizeIndicatorOff
            fontSizeThree.backgroundColor = folioReaderFontsMenu?.readerConfig?.fontSizeIndicatorOff
            fontSizeFour.backgroundColor = folioReaderFontsMenu?.readerConfig?.fontSizeIndicatorOff
            fontSizeFive.backgroundColor = folioReaderFontsMenu?.readerConfig?.fontSizeIndicatorOff
            fontSizeSix.backgroundColor = folioReaderFontsMenu?.readerConfig?.fontSizeIndicatorOff
            fontSizeSeven.backgroundColor = folioReaderFontsMenu?.readerConfig?.fontSizeIndicatorOff
            fontSizeEight.backgroundColor = folioReaderFontsMenu?.readerConfig?.fontSizeIndicatorOff
            fontSizeNine.backgroundColor = folioReaderFontsMenu?.readerConfig?.fontSizeIndicatorOn
        default:
            break
        }
    }
    
    func updateButtonStates() {
        blackBackgroundButton.isSelected = folioReaderFontsMenu?.folioReader?.nightMode ?? false
        milkBackgroundButton.isSelected = folioReaderFontsMenu?.folioReader?.milkMode ?? false
        whiteBackgroundButton.isSelected = (folioReaderFontsMenu?.folioReader?.nightMode == false && folioReaderFontsMenu?.folioReader?.milkMode == false) ?? false
        bigCellButton.isSelected = folioReaderFontsMenu?.folioReader?.currentLineHeight == 2
        middleCellButton.isSelected = folioReaderFontsMenu?.folioReader?.currentLineHeight == 1
        smallCellButton.isSelected = folioReaderFontsMenu?.folioReader?.currentLineHeight == 0
        bigFrameButton.isSelected = folioReaderFontsMenu?.folioReader?.pading == 1
        middleFrameButton.isSelected = folioReaderFontsMenu?.folioReader?.pading == 2
        smallFrameButton.isSelected = folioReaderFontsMenu?.folioReader?.pading == 3
    }
    
    @IBAction func switchDayMode(_ sender: Any) {
        folioReaderFontsMenu?.setupDayMode()
        updateButtonStates()
    }
    
    @IBAction func switchMilkMode(_ sender: Any) {
        folioReaderFontsMenu?.setupMilkMode()
        updateButtonStates()
    }
    
    @IBAction func switchNightMode(_ sender: Any) {
        folioReaderFontsMenu?.setupNightMode()
        updateButtonStates()
    }
    
    @IBAction func setupBrightness(_ sender: UISlider) {
        UIScreen.main.brightness = CGFloat(sender.value)
    }
    
    @IBAction func lineOneTapped(_ sender: Any) {
        guard let currentPage = folioReaderFontsMenu?.folioReader?.readerCenter?.currentPage else { return }
        currentPage.webView.js("setLineHeight('lineHeightOne')")
        folioReaderFontsMenu?.folioReader?.currentLineHeight = 0
        NotificationCenter.default.post(name: Notification.Name(rawValue: "needRefreshPageMode"), object: nil)
        updateButtonStates()
        folioReaderFontsMenu?.updatePopUpState()
    }
    
    @IBAction func lineTwoTapped(_ sender: Any) {
        guard let currentPage = folioReaderFontsMenu?.folioReader?.readerCenter?.currentPage else { return }
        currentPage.webView.js("setLineHeight('lineHeightTwo')")
        folioReaderFontsMenu?.folioReader?.currentLineHeight = 1
        NotificationCenter.default.post(name: Notification.Name(rawValue: "needRefreshPageMode"), object: nil)
        updateButtonStates()
        folioReaderFontsMenu?.updatePopUpState()
    }
    
    @IBAction func lineThreeTapped(_ sender: Any) {
        guard let currentPage = folioReaderFontsMenu?.folioReader?.readerCenter?.currentPage else { return }
        currentPage.webView.js("setLineHeight('lineHeightThree')")
        folioReaderFontsMenu?.folioReader?.currentLineHeight = 2
        NotificationCenter.default.post(name: Notification.Name(rawValue: "needRefreshPageMode"), object: nil)
        updateButtonStates()
        folioReaderFontsMenu?.updatePopUpState()
    }

    @IBAction func closeFontsMenu(_ sender: Any) {
        let tapPoint = fontsMenuGestureRecognizer.location(in: tapCloseView)
        if !tapCloseView.frame.contains(tapPoint) { return }
    }
    
    @IBAction func pading1xTapped(_ sender: Any) {
        folioReaderFontsMenu?.folioReader?.pading = 3
        updateButtonStates()
        folioReaderFontsMenu?.updatePopUpState()
    }
    
    @IBAction func pading2xTapped(_ sender: Any) {
        folioReaderFontsMenu?.folioReader?.pading = 2
        updateButtonStates()
        folioReaderFontsMenu?.updatePopUpState()
    }
    
    @IBAction func pading3xTapped(_ sender: Any) {
        folioReaderFontsMenu?.folioReader?.pading = 1
        updateButtonStates()
        folioReaderFontsMenu?.updatePopUpState()
    }

    @IBAction func changeFontSize(_ sender: UIStepper) {
        switch Int(sender.value) {
        case 0: fontSizeState = .one
        case 1: fontSizeState = .two
        case 2: fontSizeState = .three
        case 3: fontSizeState = .four
        case 4: fontSizeState = .five
        case 5: fontSizeState = .six
        case 6: fontSizeState = .seven
        case 7: fontSizeState = .eight
        case 8: fontSizeState = .nine
        default:
            break
        }
    }
}
