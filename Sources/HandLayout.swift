import UIKit

public enum Namespacer {
    case byhand
}

public extension CGRect {
    init(square length: CGFloat) {
        self.init(size: CGSize(square: length))
    }

    init(size: CGSize) {
        self.init(origin: .zero, size: size)
    }

    init(width: CGFloat, height: CGFloat) {
        self.init(x: 0, y: 0, width: width, height: height)
    }

    var center: CGPoint {
        get {
            return CGPoint(x: midX, y: midY)
        }
        set {
            origin.x = newValue.x - width / 2
            origin.y = newValue.y - height / 2
        }
    }
}

public extension CGSize {
    init(square length: CGFloat) {
        self.init(width: length, height: length)
    }
}

public extension UILabel {
    convenience init(_ attrstr: NSAttributedString?) {
        self.init(frame: .zero)
        if attrstr?.string.contains("\n") ?? false { numberOfLines = 0 }
        attributedText = attrstr
        sizeToFit()
    }

    convenience init(_: Namespacer, text string: String = "", font: FontConvertible = UIFont(size: UIFont.labelFontSize), color: UIColor = UIColorTextDefault, kerning: CGFloat? = UIKerningDefault) {
        if kerning == nil {         // avoid using attributedStrings if possible
            self.init(frame: .zero) // since it is a blackbox of who knows what
            text = string
            self.font = font.font
            textColor = color
            sizeToFit()
        } else {
            var attrs: [NSAttributedStringKey: Any] = [:]
            attrs[.kern] = kerning
            attrs[.font] = font.font
            attrs[.foregroundColor] = color
            self.init(NSAttributedString(string: string, attributes: attrs))
        }
    }
    
    convenience init(lines: [String], font: FontConvertible = UIFont(size: UIFont.labelFontSize), color: UIColor = UIColorTextDefault, kerning: CGFloat? = UIKerningDefault) {
        let string = lines.joined(separator: "\n")

        self.init(frame: .zero)

        if let kerning = kerning {
            attributedText = NSAttributedString(string: string, font: font, color: color, kerning: kerning)
        } else {
            text = string
            self.font = font.font
            textColor = color
        }
        numberOfLines = lines.count
        sizeToFit()
    }
}


public extension UIView {
    convenience init(width: CGFloat = UIScreen.main.bounds.width, height: CGFloat) {
        self.init(frame: CGRect(width: width, height: height))
    }

    convenience init(color: UIColor) {
        self.init(frame: .zero)
        backgroundColor = color
    }

    var origin: CGPoint {
        get { return frame.origin }
        set { frame.origin = newValue }
    }
    var maxX: CGFloat {
        get { return frame.maxX }
        set { frame.origin.x = newValue - frame.width }
    }
    var maxY: CGFloat {
        get { return frame.maxY }
        set { frame.origin.y = newValue - frame.height }
    }
    var minX: CGFloat {
        get { return frame.minX }
        set { frame.origin.x = newValue }
    }
    var minY: CGFloat {
        get { return frame.minY }
        set { frame.origin.y = newValue }
    }

    // for following we set full CGRect or in some
    // circumstances we don't fully understand, the
    // bounds origin shifts causing all sorts of badness

    var width: CGFloat {
        get { return bounds.width }
        set { bounds = CGRect(x: 0, y: 0, width: newValue, height: height) }
    }
    var height: CGFloat {
        get { return bounds.height }
        set { bounds = CGRect(x: 0, y: 0, width: width, height: newValue) }
    }
    var size: CGSize {
        get { return bounds.size }
        set { bounds = CGRect(origin: .zero, size: newValue) }
    }

    enum AutosplayoutType { case edges, margins }

    func autoSplayout(to type: AutosplayoutType = .edges) {
        guard let superview = self.superview else { return }

        // otherwise we will get crashy-conflicts
        translatesAutoresizingMaskIntoConstraints = false

        switch type {
        case .edges:
            superview.addConstraints([NSLayoutAttribute.left, .right, .top, .bottom].map {
                .init(item: self, attribute: $0, relatedBy: .equal, toItem: superview, attribute: $0, multiplier: 1, constant: 0)
            })
        case .margins:
            if #available(iOS 11, *) {
                NSLayoutConstraint.activate([
                    leadingAnchor.constraint(equalTo: superview.layoutMarginsGuide.leadingAnchor),
                    topAnchor.constraint(equalTo: superview.layoutMarginsGuide.topAnchor),
                    trailingAnchor.constraint(equalTo: superview.layoutMarginsGuide.trailingAnchor),
                    bottomAnchor.constraint(equalTo: superview.layoutMarginsGuide.bottomAnchor)
                ])
            } else {
                NSLayoutConstraint.activate([
                    leftAnchor.constraint(equalTo: superview.leftAnchor, constant: superview.layoutMargins.left),
                    topAnchor.constraint(equalTo: superview.topAnchor, constant: superview.layoutMargins.top),
                    rightAnchor.constraint(equalTo: superview.rightAnchor, constant: -superview.layoutMargins.right),
                    bottomAnchor.constraint(equalTo: superview.bottomAnchor, constant: -superview.layoutMargins.bottom),
                ])
            }
        }
    }

    var allSubviews: [UIView] {
        var stack = [self]
        var rv = [UIView]()
        while let v = stack.popLast() {
            let subviews = v.subviews
            stack.append(contentsOf: subviews)
            rv.append(contentsOf: subviews)
        }
        return rv
    }

    func add(constrained: UIView) {
        addSubview(constrained)
        constrained.translatesAutoresizingMaskIntoConstraints = false
    }

    func add(subview: UIView, constraints: [NSLayoutConstraint]) {
        addSubview(subview)
        subview.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate(constraints)
    }

    var windowFrame: CGRect {
        return convert(bounds, to: nil)
    }
}

public extension UIResponder {
    var viewController: UIViewController? {
        var vc: UIResponder! = next
        while vc != nil {
            vc = vc.next
            if let vc = vc as? UIViewController {
                return vc
            }
        }
        return nil
    }
}

public extension Int {
    var f: CGFloat { return CGFloat(self) }
}

public extension Int16 {
    var f: CGFloat { return CGFloat(self) }
}

public extension UInt32 {
    var f: CGFloat { return CGFloat(self) }
}

public extension Double {
    var f: CGFloat { return CGFloat(self) }
}

public let ⅓ = 1.f / 3.f
public let ⅔ = 2.f / 3.f
public let ⅗ = 3.f / 5.f
public let ⅘ = 4.f / 5.f
public let ϕ = 1.61803398875

public extension UIImage {
    func size(forHeight newHeight: CGFloat) -> CGSize {
        var sz = size
        sz.width = (newHeight / sz.height) * sz.width
        sz.height = newHeight
        return sz
    }
    func size(forWidth newWidth: CGFloat) -> CGSize {
        var sz = size
        sz.height = (newWidth / sz.width) * sz.height
        sz.width = newWidth
        return sz
    }
}

public extension UIImageView {
    func size(forHeight newHeight: CGFloat) -> CGSize {
        return image?.size(forHeight: newHeight) ?? .zero
    }

    // if the image doesn't help us, we return .zero
    func size(forWidth newWidth: CGFloat, atLeast minsz: CGSize? = nil) -> CGSize {
        guard var sz = image?.size(forWidth: newWidth) else {
            return .zero
        }
        if let minsz = minsz {
            if sz.height < minsz.height {
                let f = sz.height / minsz.height
                sz.width *= f
                sz.height = minsz.height
            }
            if sz.width < minsz.width {
                let f = sz.width / minsz.width
                sz.height *= f
                sz.width = minsz.width
            }
            if sz.height < minsz.height {
                sz.height = minsz.height
            }
        }
        return sz
    }

    func sizeToFit(width: CGFloat) {
        bounds = CGRect(size: size(forWidth: width))
    }

    func sizeToFit(height: CGFloat) {
        bounds = CGRect(size: size(forHeight: height))
    }
}

public extension UIViewController {
    var width: CGFloat { return view.width }
    var height: CGFloat { return view.height }

    var insets: UIEdgeInsets {
        return UIEdgeInsets(top: topLayoutGuide.length, left: 0, bottom: bottomLayoutGuide.length, right: 0)
    }

    var activeViewController: UIViewController {
        switch self {
        case let nc as UINavigationController:
            if let vc = nc.visibleViewController {
                return vc.activeViewController
            } else {
                return nc
            }
        case let tbc as UITabBarController:
            if let vc = tbc.selectedViewController {
                return vc.activeViewController
            } else {
                return tbc
            }
        default:
            if let pvc = presentedViewController {
                return pvc.activeViewController
            } else {
                return self
            }
        }
    }

    var bounds: CGRect {
        return view.bounds
    }

    func inNav(leftBarButton: UIBarButtonItem? = nil, rightBarButton: UIBarButtonItem? = nil) -> UIViewController {
        let nav = UINavigationController(rootViewController: self)
        navigationItem.leftBarButtonItem = leftBarButton
        navigationItem.rightBarButtonItem = rightBarButton
        return nav
    }
}

extension UIEdgeInsets: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) {
        self = UIEdgeInsets(CGFloat(value))
    }
}

extension UIEdgeInsets: ExpressibleByFloatLiteral {
    public init(floatLiteral value: Float) {
        self = UIEdgeInsets(CGFloat(value))
    }
}

public extension UIEdgeInsets {
    init(_ value: CGFloat) {
        self.init(top: value, left: value, bottom: value, right: value)
    }

    init(horizontal: CGFloat, vertical: CGFloat) {
        self.init(top: vertical, left: horizontal, bottom: vertical, right: horizontal)
    }
}

public extension CALayer {
    var minX: CGFloat {
        get { return frame.origin.x }
        set { frame.origin.x = newValue }
    }
    var minY: CGFloat {
        get { return frame.origin.y }
        set { frame.origin.y = newValue }
    }
    var width: CGFloat {
        get { return bounds.size.width }
        set { bounds.size.width = newValue }
    }
}


public enum Shape: ExpressibleByIntegerLiteral {
    case square
    case rounded(CornerRadius)

    public enum CornerRadius {
        case auto
        case value(CGFloat)
    }

    public init(integerLiteral value: Int) {
        self = .rounded(.value(CGFloat(value)))
    }
}


public extension UITextField {
    convenience init(_ namespacer: Namespacer, placeholder: String? = nil, style: UITextBorderStyle = .roundedRect, width: CGFloat? = nil) {
        self.init()
        self.placeholder = placeholder
        self.borderStyle = style
        sizeToFit()
        self.width = width ?? self.width
    }
}


public extension UIButton {
    /// - Note: If you set kerning at least once then you must use setAttributedTitle rather than setTitle from now on
    convenience init(_: Namespacer, title: String = "", font: FontConvertible = UIFont.systemFont(ofSize: UIFont.buttonFontSize), titleColor fg: UIColor? = nil, backgroundColor bg: UIColor? = nil, corners: Shape = .rounded(.auto), kerning: CGFloat? = UIKerningDefault)
    {
        if fg != nil || bg != nil {
            self.init(type: .custom)  // ensures iOS does less stuff with our choices, eg. dimming highlight states
        } else {
            self.init(type: .system)  // titleColor is tintColor and some other auto-choices
        }

        if let kerning = kerning {
            var attrs: [NSAttributedStringKey: Any] = [:]
            attrs[.font] = font.font
            attrs[.kern] = kerning
            attrs[.foregroundColor] = fg
            setAttributedTitle(NSAttributedString(string: title, attributes: attrs), for: .normal)
        } else {
            // avoid setAttributedTitle unless necessary since it causes `setTitle` to stop working after being used once :P
            setTitle(title, for: .normal)
            setTitleColor(fg, for: .normal)
            titleLabel?.font = font.font
        }

        sizeToFit()
        
        bounds.size.width += 20  //FIXME arbituary

        if let bg = bg {
            setBackground(color: bg, corners: corners)
        }
    }

    func setBackground(color bg: UIColor, corners: Shape, for state: UIControlState = .normal) {
        switch corners {
        case .square:
            // we still set an image as otherwise you don't get automatic touch-highlights
            setBackgroundImage(UIImage(color: bg), for: state)
        case .rounded(.auto):
            let radius = min(height, width) / 2
            setBackgroundImage(UIImage.make(color: bg, cornerRadius: radius), for: state)
        case .rounded(.value(let radius)):
            setBackgroundImage(UIImage.make(color: bg, cornerRadius: radius), for: state)
        }
    }

    convenience init(_: Namespacer, image: UIImage) {
        self.init(type: .custom)
        setImage(image, for: .normal)
        sizeToFit()
    }

    enum UnderlinedNamespacer {
        case underlined
    }

    convenience init(_: UnderlinedNamespacer, title: String, font: FontConvertible = UIFont(size: UIFont.buttonFontSize), titleColor: UIColor = UIColorTextDefault) {
        self.init(frame: .zero)

        setAttributedTitle(.init(string: title, attributes: [
            .font: font.font,
            .foregroundColor: titleColor,
            .underlineStyle: NSUnderlineStyle.styleSingle.rawValue
        ]), for: .normal)

        setAttributedTitle(.init(string: title, attributes: [
            .font: font.font,
            .foregroundColor: titleColor.adjusted(alpha: 0.5),
            .underlineStyle: NSUnderlineStyle.styleSingle.rawValue
        ]), for: .highlighted)
    }
}


public extension UISegmentedControl {
    convenience init(_: Namespacer, _ titles: String...) {
        self.init()
        guard titles.count > 0 else { return }
        titles.enumerated().map{ ($1, $0, false) }.forEach(insertSegment)
        selectedSegmentIndex = 0
        sizeToFit()
    }
}


public extension UIImage {
    convenience init(color: UIColor) {
        self.init(color: color, size: CGSize(square: 1))
    }

    convenience init(color: UIColor, size: CGSize) {
        UIGraphicsBeginImageContext(size)
        guard let ctx = UIGraphicsGetCurrentContext() else { fatalError() }
        ctx.setFillColor(color.cgColor)
        ctx.fill(CGRect(size: size))

        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        guard let cgImage = img?.cgImage else { fatalError() }
        
        self.init(cgImage: cgImage)
    }

    static func make(color: UIColor, cornerRadius: CGFloat) -> UIImage {
        let minEdgeSize = cornerRadius * 2 + 1
        let rect = CGRect(square: minEdgeSize)

        let roundedRect = UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius)
        roundedRect.lineWidth = 0

        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0.f);
        color.setFill()
        roundedRect.fill()
        roundedRect.stroke()
        roundedRect.addClip()
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        if let img = img {
            return img.resizableImage(withCapInsets: UIEdgeInsets(cornerRadius))
        } else {
            return UIImage()
        }
    }
}


open class UIPaddedLabel: UILabel {
    public var contentInsets = UIEdgeInsets.zero

    open override var intrinsicContentSize: CGSize {
        var sz = super.intrinsicContentSize
        sz.width += contentInsets.left + contentInsets.right
        sz.height += contentInsets.top + contentInsets.bottom
        return sz
    }

    open override func drawText(in rect: CGRect) {
        let insets: UIEdgeInsets
        if self.contentInsets.top == self.contentInsets.bottom {
            // prevents potential clipping due to CoreText not always seemingly being accurate
            insets = UIEdgeInsets(top: 0, left: self.contentInsets.left, bottom: 0, right: self.contentInsets.right)
        } else {
            insets = self.contentInsets
        }
        super.drawText(in: rect.inset(by: insets))
    }

    open override func sizeToFit() {
        let W = contentInsets.left + contentInsets.right
        width -= W
        super.sizeToFit()
        width += W
        height += contentInsets.top + contentInsets.bottom + 1  // plus one allows for rounding errors that apparently `sizeToFit` can cause sometimes
    }
}

public extension CGRect {
    /// because we provide a convertible for UIEdgeInsets you can do eg: `rect.inset(by: 10)`
    func inset(by insets: UIEdgeInsets) -> CGRect {
        return UIEdgeInsetsInsetRect(self, insets)
    }

    func inset(_ edges: UIRectEdge, by: CGFloat) -> CGRect {
        var insets = UIEdgeInsets()
        if edges.contains(.top) { insets.top = by }
        if edges.contains(.bottom) { insets.bottom = by }
        if edges.contains(.left) { insets.left = by }
        if edges.contains(.right) { insets.right = by }
        return UIEdgeInsetsInsetRect(self, insets)
    }
}

public func *(size: CGSize, factor: CGFloat) -> CGSize {
    return CGSize(width: size.width * factor, height: size.height * factor)
}

public func *(size: CGSize, factor: (CGFloat, CGFloat)) -> CGSize {
    return CGSize(width: size.width * factor.0, height: size.height * factor.1)
}

public func +(size: CGSize, px: CGFloat) -> CGSize {
    return CGSize(width: size.width + px, height: size.height + px)
}

public func +(lhs: CGSize, rhs: CGSize) -> CGSize {
    return CGSize(width: lhs.width + rhs.width, height: lhs.height + rhs.height)
}

public func *=(lhs: inout CGSize, rhs: CGFloat) {
    lhs = lhs * rhs
}

public func +=(lhs: inout CGSize, rhs: CGFloat) {
    lhs = lhs + rhs
}

public func +=(lhs: inout CGSize, rhs: CGSize) {
    lhs = lhs + rhs
}

public func +(lhs: NSAttributedString, rhs: NSAttributedString) -> NSAttributedString {
    let rv = NSMutableAttributedString(attributedString: lhs)
    rv.append(rhs)
    return rv
}

public func +(lhs: CGPoint, rhs: CGPoint) -> CGPoint {
    return CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
}

public func -(lhs: CGPoint, rhs: CGPoint) -> CGPoint {
    return CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
}

public func -=(lhs: inout CGPoint, rhs: CGPoint) {
    lhs = lhs - rhs
}



public extension NSAttributedString {
    convenience init(string: String, font: FontConvertible = UIFont(), color: UIColor = UIColorTextDefault, kerning: CGFloat? = UIKerningDefault) {
        var attrs: [NSAttributedStringKey: Any] = [
            .font: font.font,
            .foregroundColor: color
        ]
        attrs[.kern] = kerning
        self.init(string: string, attributes: attrs)
    }

    var range: NSRange {
        return NSMakeRange(0, length)
    }

    func p(spacing: CGFloat, alignment: NSTextAlignment = .left) -> NSAttributedString {
        let a = NSMutableAttributedString(attributedString: self)
        let para = NSMutableParagraphStyle()
        para.paragraphSpacing = spacing
        para.alignment = alignment
        a.addAttributes([.paragraphStyle: para], range: range)
        return a
    }
}


public extension UIDevice {
    static var isSmall: Bool {
        return UIScreen.main.bounds.size.width <= Model.SE.width
    }

    public enum Model {
        case classic   // original iPhone until iPhone 5
        case SE        // iPhone 5
        case standard  // iPhone 6
        case plus
        case X
        case iPad(Size)

        public enum Size {
            case standard
            case large
        }

        public var width: CGFloat {
            switch self {
            case .classic, .SE:
                return 320
            case .standard, .X:
                return 375
            case .plus:
                return 414
            case .iPad(.standard):
                return 768
            case .iPad(.large):
                return 1024
            }
        }
    }

    static var model: Model {
        let sz = UIScreen.main.bounds.size
        switch (sz.width, sz.height) {
        case (320, 480):
            return .classic
        case (320, 568):
            return .SE
        case (375, 667):
            return .standard
        case (414, 736):
            return .plus
        case (375, 812):
            return .X
        case (768, 1024):
            return .iPad(.standard)
        case (1024, 1366):
            return .iPad(.large)
        default:
            return .standard
        }
    }
}

public extension UILabel {
    convenience init(_: Namespacer, _ text: String, _ alignment: NSTextAlignment = .left) {
        self.init(.byhand, NSMutableAttributedString().normal(text), alignment)
    }

    convenience init(_: Namespacer, _ attrText: NSAttributedString, _ alignment: NSTextAlignment = .left) {
        self.init(frame: .zero)
        attributedText = attrText
        textAlignment = alignment
    }

    func size(forHeight newHeight: CGFloat) -> CGSize {
        fatalError()
    }

    func size(forWidth newWidth: CGFloat) -> CGSize {
        guard let str = attributedText else { fatalError("Unsupported code path, please fork and implement") }
        let size = CGSize(width: newWidth, height: 10_000)
        let opts: NSStringDrawingOptions = [.usesLineFragmentOrigin, .usesFontLeading]
        let rect = str.boundingRect(with: size, options: opts, context: nil)
        return rect.size
    }

    func sizeToFit(width: CGFloat) {
        self.width = width
        sizeToFit()
        self.width = width
    }
}


public extension UIFont {
    func size(forWidth width: CGFloat, text: String) -> CGSize {
        let bounds = CGSize(width: width, height: 100_000)
        return text.boundingRect(with: bounds, options: .usesLineFragmentOrigin, attributes: [
            .font: self
        ], context: nil).size
    }

    func width(of str: String) -> CGFloat {
        let bounds = CGSize(width: 100_000, height: 100_000)
        return str.boundingRect(with: bounds, options: .usesLineFragmentOrigin, attributes: [
            .font: self
        ], context: nil).size.width
    }
}


//MARK: Defaults

public let UIColorTextDefault = UIColor.white
public let UIFontNameDefault = UIFont.Name.brandon(.medium)
public let UIKerningDefault: CGFloat? = nil


//MARK: UIFont

private var cache = Set<String>()

public extension UIFont {
    enum Name {
        case brandon(BrandonWeight)
        case gordon
        case ss(SSWeight)

        public enum BrandonWeight {
            case regular, medium, bold, black
        }
        public enum SSWeight {
            case junior, standard, community
        }

        fileprivate var basename: String {
            switch self {
            case .brandon(.regular):
                return "Brandon_txt_reg"
            case .brandon(.medium):
                return "Brandon_txt_med"
            case .brandon(.bold):
                return "Brandon_txt_bld"
            case .brandon(.black):
                return "Brandon_txt_blk"
            case .gordon:
                return "Gordon-Black"
            case .ss(.junior):
                return "ss-junior"
            case .ss(.standard):
                return "ss-standard"
            case .ss(.community):
                return "ss-community"
            }
        }

        fileprivate var familyName: String {
            switch self {
            case .brandon(.regular):
                return "BrandonText-Regular"
            case .brandon(.medium):
                return "BrandonText-Medium"
            case .brandon(.bold):
                return "BrandonText-Bold"
            case .brandon(.black):
                return "BrandonText-Black"
            case .gordon:
                return "Gordon-Black"
            case .ss(.junior):
                return "SSJunior"
            case .ss(.standard):
                return "SSStandard"
            case .ss(.community):
                return "SS Community"
            }
        }

        fileprivate func registerIfNecessary() {
            let basename = self.basename
            guard !cache.contains(basename) else { return }
            let bundle = Bundle(identifier: "is.poncho.fmwk.kit")!
            let path = bundle.path(forResource: basename, ofType: "otf")!
            let data = NSData(contentsOfFile: path)!
            let provider = CGDataProvider(data: data)!
            var error: Unmanaged<CFError>?
            guard let font = CGFont(provider) else { return }
            CTFontManagerRegisterGraphicsFont(font, &error)
            if let error = error {
                print(#function, error)
            } else {
                cache.insert(basename)
            }
        }
    }

    convenience init(_ name: Name = UIFontNameDefault, size: CGFloat = UIFont.systemFontSize) {
        name.registerIfNecessary()
        self.init(name: name.familyName, size: size)!
    }
}


//MARK: FontConvertible

public protocol FontConvertible {
    var font: UIFont { get }
}

extension UIFont: FontConvertible {
    public var font: UIFont { return self }
}

extension Int: FontConvertible {
    public var font: UIFont { return UIFont(size: CGFloat(self)) }
}


//MARK: UIColor

public extension UIColor {
    func adjusted(alpha: CGFloat) -> UIColor {
        var (r, g, b) = (0.f, 0.f, 0.f)
        getRed(&r, green: &g, blue: &b, alpha: nil)
        return UIColor(red: r, green: g, blue: b, alpha: alpha)
    }

    convenience init(white: CGFloat) {
        self.init(white: white, alpha: 1)
    }
}

public extension UIScreen {
    var width: CGFloat {
        return bounds.width
    }
    var height: CGFloat {
        return bounds.height
    }
}
