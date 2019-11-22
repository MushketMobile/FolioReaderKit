//
//  FolioReaderFontsMenu.swift
//  FolioReaderKit
//
//  Created by Heberti Almeida on 27/08/15.
//  Copyright (c) 2015 Folio Reader. All rights reserved.
//

import UIKit
import FolioReaderKit

public enum FolioReaderFont: Int {
    case andada = 0
    case lato
    case lora
    case raleway

    public static func folioReaderFont(fontName: String) -> FolioReaderFont? {
        var font: FolioReaderFont?
        switch fontName {
/***    case "andada": font = .andada
        case "lato": font = .lato
        case "lora": font = .lora
        case "raleway": font = .raleway
***/
        case "david": font = .andada
        case "frankRuhel": font = .lato
        case "hadasim": font = .lora
        case "shofar": font = .raleway
        
        
        default: break
        }
        return font
    }

    public var cssIdentifier: String {
        switch self {
        case .andada: return "andada"
        case .lato: return "lato"
        case .lora: return "lora"
        case .raleway: return "raleway"
        }
    }
}

public enum FolioReaderFontSize: Int {
    case xs = 0
    case s
    case m
    case l
    case xl
    case xxl
    case xxxl
    case xxxxl
    case gl
    
    public static func folioReaderFontSize(fontSizeStringRepresentation: String) -> FolioReaderFontSize? {
        var fontSize: FolioReaderFontSize?
        switch fontSizeStringRepresentation {
        case "textSizeOne": fontSize = .xs
        case "textSizeTwo": fontSize = .s
        case "textSizeThree": fontSize = .m
        case "textSizeFour": fontSize = .l
        case "textSizeFive": fontSize = .xl
        case "textSizeSix": fontSize = .xxl
        case "textSizeSeven": fontSize = .xxxl
        case "textSizeEight": fontSize = .xxxxl
        case "textSizeNine": fontSize = .gl

        default: break
        }
        return fontSize
    }

    public var cssIdentifier: String {
        switch self {
        case .xs: return "textSizeOne"
        case .s: return "textSizeTwo"
        case .m: return "textSizeThree"
        case .l: return "textSizeFour"
        case .xl: return "textSizeFive"
        case .xxl: return "textSizeSix"
        case .xxxl: return "textSizeSeven"
        case .xxxxl: return "textSizeEight"
        case .gl: return "textSizeNine"
        }
    }
}

class FolioReaderFontsMenu: UIViewController, SMSegmentViewDelegate, UIGestureRecognizerDelegate {
    var menuView: UIView!

    weak var readerConfig: FolioReaderConfig?
    weak var folioReader: FolioReader?
    weak var folioReaderCenter: FolioReaderCenter?
    
    var fontsMenuView: ReaderFontsMenu?
    var fontsMenuShouldHide = false
    
    init(folioReader: FolioReader, readerConfig: FolioReaderConfig, readerCenter: FolioReaderCenter, nib: String) {
        self.readerConfig = readerConfig
        self.folioReader = folioReader
        self.folioReaderCenter = readerCenter
        fontsMenuView = ReaderFontsMenu.instanceFromNib(nibName: nib)

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        fontsMenuView?.frame = self.view.frame
        fontsMenuView?.layoutIfNeeded()
        fontsMenuView?.folioReaderFontsMenu = self
        fontsMenuView?.setupUI(readerView: self.view)
        
        setupFontSize()
        setupFontFamily()
        actionFontsMenuView()

        fontsMenuView?.fontSizeStepper.addTarget(self, action: #selector(stepperValueChanged), for: .valueChanged)
        fontsMenuView?.fontDavid.addTarget(self, action: #selector(setupFontDavid), for: .touchUpInside)
        fontsMenuView?.fontFrankRuhel.addTarget(self, action: #selector(setupFontFrankRuhel), for: .touchUpInside)
        fontsMenuView?.fontHadasim.addTarget(self, action: #selector(setupFontHadasim), for: .touchUpInside)
        fontsMenuView?.fontShofar.addTarget(self, action: #selector(setupFontShofar), for: .touchUpInside)
        
        fontsMenuView?.fontsMenuGestureRecognizer.addTarget(self, action: #selector(recognizeFontsMenuViewAction))
        
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        dismissFontsMenuView()
    }

    func updatePopUpState() {
        folioReaderCenter?.popUpShouldHide = true
    }
    
    func setupFontSize() {
        if let size = folioReader?.defaults.value(forKey: kCurrentFontSize) as? Int {
            fontsMenuView?.fontSizeStepper.value = Double(size)
            switch size {
            case 0: fontsMenuView?.fontSizeState = .one
            case 1: fontsMenuView?.fontSizeState = .two
            case 3: fontsMenuView?.fontSizeState = .four
            case 4: fontsMenuView?.fontSizeState = .five
            case 5: fontsMenuView?.fontSizeState = .six
            case 6: fontsMenuView?.fontSizeState = .seven
            case 7: fontsMenuView?.fontSizeState = .eight
            case 8: fontsMenuView?.fontSizeState = .nine

            default:
                fontsMenuView?.fontSizeState = .three
            }
        }
    }
    
    func setupFontFamily() {
        if let fontFamily = folioReader?.defaults.value(forKey: kCurrentFontFamily) as? Int {
            switch fontFamily {
            case 1: fontsMenuView?.fontFrankRuhel.setTitleColor(readerConfig?.fontSelected, for: .normal)
            case 2: fontsMenuView?.fontHadasim.setTitleColor(readerConfig?.fontSelected, for: .normal)
            case 3: fontsMenuView?.fontShofar.setTitleColor(readerConfig?.fontSelected, for: .normal)
            default:
                fontsMenuView?.fontDavid.setTitleColor(readerConfig?.fontSelected, for: .normal)
            }
        }
    }

    
    @objc func recognizeFontsMenuViewAction() {
        guard let tapPoint = fontsMenuView?.fontsMenuGestureRecognizer.location(in: fontsMenuView?.tapCloseView) else { return }
        if fontsMenuView?.fontsMenuView.frame.contains(tapPoint) == true { return }
        actionFontsMenuView()
    }

    func actionFontsMenuView() {
        if fontsMenuShouldHide {
            dismissFontsMenuView()
        } else {
            presentFontsMenuView()
        }
    }
    
    func presentFontsMenuView() {
        UIView.animate(withDuration: 0.3,
                       delay: 0.0,
                       options: .curveEaseIn,
                       animations: { self.view.backgroundColor = UIColor.black.withAlphaComponent(0.0) },
                       completion: {[weak self] _ in
                        self?.fontsMenuShouldHide = true
                        self?.view.addSubview((self?.fontsMenuView!)!)})
    }
    
    func dismissFontsMenuView() {
        UIView.animate(withDuration: 0.3,
                       delay: 0.0,
                       options: .curveEaseOut,
                       animations: { self.view.backgroundColor = UIColor.black.withAlphaComponent(0.0) },
                       completion: {[weak self] _ in
                        self?.fontsMenuShouldHide = false
                        self?.fontsMenuView?.removeFromSuperview()
                        self?.fontsMenuView = nil
                        self?.folioReaderCenter?.readerProgressManager?.clearAndUpdateIfNeeded()
                        self?.folioReaderCenter?.progressView?.updateUI()
                        self?.folioReaderCenter?.folioReaderFontsMenu = nil
                        self?.dismiss()})
    }
    
    // MARK: - SMSegmentView delegate

    func segmentView(_ segmentView: SMSegmentView, didSelectSegmentAtIndex index: Int) {
        guard (self.folioReader?.readerCenter?.currentPage) != nil else { return }

        if segmentView.tag == 1 {

            self.folioReader?.nightMode = Bool(index == 1)
            

            UIView.animate(withDuration: 0.6, animations: {
                self.menuView.backgroundColor = ((self.folioReader?.nightMode)! ? self.readerConfig?.nightModeBackground : UIColor.white)
            })

        } else if segmentView.tag == 2 {

            self.folioReader?.currentFont = FolioReaderFont(rawValue: index)!

        }  else if segmentView.tag == 3 {

            guard self.folioReader?.currentScrollDirection != index else {
                return
            }

            self.folioReader?.currentScrollDirection = index
        }
    }

    func setupDayMode() {
        folioReader?.nightMode = false
    }
    
    func setupNightMode() {
        folioReader?.nightMode = true
    }
    
    func setupMilkMode() {
        folioReader?.milkMode = true
    }
    
    //MARK: - FontSize Stepper changed
    
    @objc func stepperValueChanged() {
        let size = Int((fontsMenuView?.fontSizeStepper.value)!)
        guard (self.folioReader?.readerCenter?.currentPage != nil),
            let fontSize = FolioReaderFontSize(rawValue: size) else {
            return
        }
        self.folioReader?.currentFontSize = fontSize
        updatePopUpState()
    }
    
    //MARK: - Font
    @objc func setupFontDavid() {
        self.folioReader?.currentFont = FolioReaderFont(rawValue: 0)!
        fontsMenuView?.fontDavid.setTitleColor(readerConfig?.fontSelected, for: .normal)
        fontsMenuView?.fontFrankRuhel.setTitleColor(.white, for: .normal)
        fontsMenuView?.fontHadasim.setTitleColor(.white, for: .normal)
        fontsMenuView?.fontShofar.setTitleColor(.white, for: .normal)
        updatePopUpState()
    }
    
    @objc func setupFontFrankRuhel() {
        self.folioReader?.currentFont = FolioReaderFont(rawValue: 1)!
        fontsMenuView?.fontDavid.setTitleColor(.white, for: .normal)
        fontsMenuView?.fontFrankRuhel.setTitleColor(readerConfig?.fontSelected, for: .normal)
        fontsMenuView?.fontHadasim.setTitleColor(.white, for: .normal)
        fontsMenuView?.fontShofar.setTitleColor(.white, for: .normal)
        updatePopUpState()
    }
    
    @objc func setupFontHadasim() {
        self.folioReader?.currentFont = FolioReaderFont(rawValue: 2)!
        fontsMenuView?.fontDavid.setTitleColor(.white, for: .normal)
        fontsMenuView?.fontFrankRuhel.setTitleColor(.white, for: .normal)
        fontsMenuView?.fontHadasim.setTitleColor(readerConfig?.fontSelected, for: .normal)
        fontsMenuView?.fontShofar.setTitleColor(.white, for: .normal)
        updatePopUpState()
    }
    
    @objc func setupFontShofar() {
        self.folioReader?.currentFont = FolioReaderFont(rawValue: 3)!
        fontsMenuView?.fontDavid.setTitleColor(.white, for: .normal)
        fontsMenuView?.fontFrankRuhel.setTitleColor(.white, for: .normal)
        fontsMenuView?.fontHadasim.setTitleColor(.white, for: .normal)
        fontsMenuView?.fontShofar.setTitleColor(readerConfig?.fontSelected, for: .normal)
        updatePopUpState()
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if gestureRecognizer is UITapGestureRecognizer && touch.view == view {
            return true
        }
        return false
    }
    
    // MARK: - Status Bar
    
    override var prefersStatusBarHidden : Bool {
        return (self.readerConfig?.shouldHideNavigationOnTap == true)
    }
}
