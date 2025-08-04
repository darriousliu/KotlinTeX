import Foundation

class MathDisplayException: Error {
    var message: String

    init(_ message: String) {
        self.message = message
    }
}

/**
@typedef MTMathAtomType
@brief The type of atom in a `MTMathList`.

The type of the atom determines how it is rendered, and spacing between the atoms.
 */

enum MTMathAtomType: Comparable {
    // A non-atom
    case kMTMathAtomNone

    /// A number or text in ordinary format - Ord in TeX
    case kMTMathAtomOrdinary

    /// A number - Does not exist in TeX
    case kMTMathAtomNumber

    /// A variable (i.e. text in italic format) - Does not exist in TeX
    case kMTMathAtomVariable

    /// A large operator such as (sin/cos, integral etc.) - Op in TeX
    case kMTMathAtomLargeOperator

    /// A binary operator - Bin in TeX
    case kMTMathAtomBinaryOperator

    /// A unary operator - Does not exist in TeX.
    case kMTMathAtomUnaryOperator

    /// A relation, e.g. = > < etc. - Rel in TeX
    case kMTMathAtomRelation

    /// Open brackets - Open in TeX
    case kMTMathAtomOpen

    /// Close brackets - Close in TeX
    case kMTMathAtomClose

    /// An fraction e.g 1/2 - generalized fraction noad in TeX
    case kMTMathAtomFraction

    /// A radical operator e.g. sqrt(2)
    case kMTMathAtomRadical

    /// Punctuation such as , - Punct in TeX
    case kMTMathAtomPunctuation

    /// A placeholder square for future input. Does not exist in TeX
    case kMTMathAtomPlaceholder

    /// An inner atom, i.e. an embedded math list - Inner in TeX
    case kMTMathAtomInner

    /// An underlined atom - Under in TeX
    case kMTMathAtomUnderline

    /// An overlined atom - Over in TeX
    case kMTMathAtomOverline

    /// An accented atom - Accent in TeX
    case kMTMathAtomAccent

    // Atoms after this point do not support subscripts or superscripts

    /// A left atom - Left & Right in TeX. We don't need two since we track boundaries separately.
    case kMTMathAtomBoundary

    // Atoms after this are non-math TeX nodes that are still useful in math mode. They do not have
    // the usual structure.

    /// Spacing between math atoms. This denotes both glue and kern for TeX. We do not
    /// distinguish between glue and kern.
    case kMTMathAtomSpace

    /// Denotes style changes during rendering.
    case kMTMathAtomStyle
    case kMTMathAtomColor
    case kMTMathAtomTextColor

    // Atoms after this point are not part of TeX and do not have the usual structure.

    /// An table atom. This atom does not exist in TeX. It is equivalent to the TeX command
    /// halign which is handled outside of the TeX math rendering engine. We bring it into our
    /// math typesetting to handle matrices and other tables.
    case kMTMathAtomTable

    private var order: Int {
        switch self {
        case .kMTMathAtomNone: return 0
        case .kMTMathAtomOrdinary: return 1
        case .kMTMathAtomNumber: return 2
        case .kMTMathAtomVariable: return 3
        case .kMTMathAtomBinaryOperator: return 4
        case .kMTMathAtomUnaryOperator: return 5
        case .kMTMathAtomRelation: return 6
        case .kMTMathAtomOpen: return 7
        case .kMTMathAtomClose: return 8
        case .kMTMathAtomFraction: return 9
        case .kMTMathAtomRadical: return 10
        case .kMTMathAtomPunctuation: return 11
        case .kMTMathAtomPlaceholder: return 12
        case .kMTMathAtomLargeOperator: return 13
        case .kMTMathAtomInner: return 14
        case .kMTMathAtomUnderline: return 15
        case .kMTMathAtomOverline: return 16
        case .kMTMathAtomAccent: return 17
        case .kMTMathAtomBoundary: return 18 // No scripts allowed after this point.
        case .kMTMathAtomSpace: return 19 // No scripts allowed after this point.
        case .kMTMathAtomStyle: return 20 // No scripts allowed after this point.
        case .kMTMathAtomColor: return 21 // No scripts allowed after this point.
        case .kMTMathAtomTextColor: return 22 // No scripts allowed after this point.
        case .kMTMathAtomTable: return 23 // No scripts allowed after this point.
        }
    }

    static func <(lhs: MTMathAtomType, rhs: MTMathAtomType) -> Bool {
        return lhs.order < rhs.order
    }
}

let NSNotFound: Int = -1

struct NSRange: Equatable {
    var location: Int = NSNotFound
    var length: Int = 0

    // Return true if equal to passed range
    func equal(_ cmp: NSRange) -> Bool {
        return (cmp.location == self.location && cmp.length == self.length)
    }

    var maxRange: Int {
        return location + length
    }

    func union(_ a: NSRange) -> NSRange {
        let b = self
        let e = max(a.maxRange, b.maxRange)
        let s = min(a.location, b.location)
        return NSRange(location: s, length: e - s)
    }

    func copy() -> NSRange {
        return NSRange(location: self.location, length: self.length)
    }
}

enum MTFontStyle {
    /// The default latex rendering style. i.e. variables are italic and numbers are roman.
    case KMTFontStyleDefault

    /// Roman font style i.e. \mathrm
    case KMTFontStyleRoman

    /// Bold font style i.e. \mathbf
    case KMTFontStyleBold

    /// Caligraphic font style i.e. \mathcal
    case KMTFontStyleCaligraphic

    /// Typewriter (monospace) style i.e. \mathtt
    case KMTFontStyleTypewriter

    /// Italic style i.e. \mathit
    case KMTFontStyleItalic

    /// San-serif font i.e. \mathss
    case KMTFontStyleSansSerif

    /// Fractur font i.e \mathfrak
    case KMTFontStyleFraktur

    /// Blackboard font i.e. \mathbb
    case KMTFontStyleBlackboard

    /// Bold italic
    case KMTFontStyleBoldItalic
}

/**
 A `MTMathAtom` is the basic unit of a math list. Each atom represents a single character
 or mathematical operator in a list. However certain atoms can represent more complex structures
 such as fractions and radicals. Each atom has a type which determines how the atom is rendered and
 a nucleus. The nucleus contains the character(s) that need to be rendered. However the nucleus may
 be empty for certain types of atoms. An atom has an optional subscript or superscript which represents
 the subscript or superscript that is to be rendered.

 Certain types of atoms inherit from `MTMathAtom` and may have additional fields.
 */
/*
constructor
/** Factory function to create an atom with a given type and value.
 @param type The type of the atom to instantiate.
 @param value The value of the atoms nucleus. The value is ignored for fractions and radicals.
 */
class func atom(withType type: MTMathAtomType, value: String) -> MTMathAtom
*/

open class MTMathAtom: CustomStringConvertible {

    var type: MTMathAtomType
    var nucleus: String

    /** Returns a string representation of the MTMathAtom */
    /** The nucleus of the atom. */

    /** An optional superscript. */
    var superScript: MTMathList? = nil {
        didSet {
            guard scriptsAllowed() else {
                fatalError("Superscripts not allowed for atom \(self)")
            }
        }
    }

    /** An optional subscript. */
    var subScript: MTMathList? = nil {
        didSet {
            guard scriptsAllowed() else {
                fatalError("Subscripts not allowed for atom \(self)")
            }
        }
    }

    /** The font style to be used for the atom. */
    var fontStyle: MTFontStyle = .KMTFontStyleDefault

    /// If this atom was formed by fusion of multiple atoms, then this stores the list of atoms that were fused to create this one.
    /// This is used in the finalizing and preprocessing steps.
    var fusedAtoms: [MTMathAtom] = []

    /// The index range in the MTMathList this MTMathAtom tracks. This is used by the finalizing and preprocessing steps
    /// which fuse MTMathAtoms to track the position of the current MTMathAtom in the original list.
    // This will be the zero Range until finalize is called on the MTMathList
    var indexRange: NSRange = NSRange(location: 0, length: 0)

    init(type: MTMathAtomType, nucleus: String) {
        self.type = type
        self.nucleus = nucleus
    }

    private func dumpStr(s: String) {
        let ca = Array(s)
        let cp = Utils.codePointAt(sequence: ca, index: 0)
        print("str \(s) codepoint \(cp)")
        for c in ca {
            print("c \(c)")
        }
    }

    class Factory: MTMathAtomFactory {
        static let shared = Factory()

        // Returns true if the current binary operator is not really binary.
        func isNotBinaryOperator(_ prevNode: MTMathAtom?) -> Bool {
            guard let prevNode = prevNode else {
                return true
            }

            switch prevNode.type {
            case .kMTMathAtomBinaryOperator, .kMTMathAtomRelation, .kMTMathAtomOpen, .kMTMathAtomPunctuation, .kMTMathAtomLargeOperator:
                return true
            default:
                return false
            }
        }

        func typeToText(_ type: MTMathAtomType) -> String {
            switch type {
            case .kMTMathAtomNone: return "None"
            case .kMTMathAtomOrdinary: return "Ordinary"
            case .kMTMathAtomNumber: return "Number"
            case .kMTMathAtomVariable: return "Variable"
            case .kMTMathAtomBinaryOperator: return "Binary Operator"
            case .kMTMathAtomUnaryOperator: return "Unary Operator"
            case .kMTMathAtomRelation: return "Relation"
            case .kMTMathAtomOpen: return "Open"
            case .kMTMathAtomClose: return "Close"
            case .kMTMathAtomFraction: return "Fraction"
            case .kMTMathAtomRadical: return "Radical"
            case .kMTMathAtomPunctuation: return "Punctuation"
            case .kMTMathAtomPlaceholder: return "Placeholder"
            case .kMTMathAtomLargeOperator: return "Large Operator"
            case .kMTMathAtomInner: return "Inner"
            case .kMTMathAtomUnderline: return "Underline"
            case .kMTMathAtomOverline: return "Overline"
            case .kMTMathAtomAccent: return "Accent"
            case .kMTMathAtomBoundary: return "Boundary"
            case .kMTMathAtomSpace: return "Space"
            case .kMTMathAtomStyle: return "Style"
            case .kMTMathAtomColor: return "Color"
            case .kMTMathAtomTextColor: return "TextColor"
            case .kMTMathAtomTable: return "Table"
            }
        }

        /*
          Some types have special classes instead of MTMathAtom. Based on the type create the correct class
         */
        func atomWithType(type: MTMathAtomType, value: String) -> MTMathAtom {
            switch type {
            case .kMTMathAtomFraction:
                return MTFraction(rule: true)

            case .kMTMathAtomPlaceholder:
                return MTMathAtom(type: .kMTMathAtomPlaceholder, nucleus: "\u{25A1}")

            case .kMTMathAtomRadical:
                return MTRadical()

            case .kMTMathAtomLargeOperator:
                return MTLargeOperator(nucleus: value, limits: true)

            case .kMTMathAtomInner:
                return MTInner()

            case .kMTMathAtomOverline:
                return MTOverLine()

            case .kMTMathAtomUnderline:
                return MTUnderLine()

            case .kMTMathAtomAccent:
                return MTAccent(nucleus: value)

            case .kMTMathAtomSpace:
                return MTMathSpace(space: 0.0)

            case .kMTMathAtomColor:
                return MTMathColor()

            default:
                return MTMathAtom(type: type, nucleus: value)
            }
        }

        func atomForCharacter(_ ch: Character) -> MTMathAtom? {
            let chStr = String(ch)

            if ch.unicodeScalars.allSatisfy({ $0.value < 0x21 || $0.value > 0x7E }) {
                return nil
            }

            switch ch {
            case "$", "%", "#", "&", "~", "'", "^", "_", "{", "}", "\\":
                return nil

            case "(", "[":
                return atomWithType(type: .kMTMathAtomOpen, value: chStr)

            case ")", "]", "!", "?":
                return atomWithType(type: .kMTMathAtomClose, value: chStr)

            case ",", ";":
                return atomWithType(type: .kMTMathAtomPunctuation, value: chStr)

            case "=", ">", "<":
                return atomWithType(type: .kMTMathAtomRelation, value: chStr)

            case ":":
                return atomWithType(type: .kMTMathAtomRelation, value: "\u{2236}")

            case "-":
                return atomWithType(type: .kMTMathAtomBinaryOperator, value: "\u{2212}")

            case "+", "*":
                return atomWithType(type: .kMTMathAtomBinaryOperator, value: chStr)

            case ".", "0"..."9":
                return atomWithType(type: .kMTMathAtomNumber, value: chStr)

            case "a"..."z", "A"..."Z":
                return atomWithType(type: .kMTMathAtomVariable, value: chStr)

            case "\"", "/", "@", "`", "|":
                return atomWithType(type: .kMTMathAtomOrdinary, value: chStr)

            default:
                fatalError("Unknown ascii character \(ch). Should have been accounted for.")
            }
        }
    }

    open func toLatexString() -> String {
        var str = nucleus
        str = toStringSubs(s: str)
        return str
    }

    func toStringSubs(s: String) -> String {
        var str = s
        if let superScript = self.superScript {
            str += "^{\(MTMathListBuilder.Factory.toLatexString(superScript))}"
        }
        if let subScript = self.subScript {
            str += "_{\(MTMathListBuilder.Factory.toLatexString(subScript))}"
        }
        return str
    }

    func copyDeepContent(atom: MTMathAtom) -> MTMathAtom {
        if let sub = self.subScript {
            atom.subScript = sub.copyDeep()
        }
        if let sup = self.superScript {
            atom.superScript = sup.copyDeep()
        }
        assert(atom.fusedAtoms.isEmpty)
        atom.fontStyle = self.fontStyle
        atom.indexRange = self.indexRange
        return atom
    }

    open func copyDeep() -> MTMathAtom {
        let atom = MTMathAtom(type: self.type, nucleus: self.nucleus)
        return copyDeepContent(atom: atom)
    }

    func finalized(newNode: MTMathAtom) -> MTMathAtom {
        if let sup = self.superScript {
            newNode.superScript = sup.finalized()
        }
        if let sub = self.subScript {
            newNode.subScript = sub.finalized()
        }
        newNode.fontStyle = self.fontStyle
        newNode.indexRange = self.indexRange
        return newNode
    }

    open func finalized() -> MTMathAtom {
        return finalized(newNode: self.copyDeep())
    }

    /** Returns true if this atom allows scripts (sub or super). */
    func scriptsAllowed() -> Bool {
        return (self.type < .kMTMathAtomBoundary)
    }

    public var description: String {
        return "\(Factory.shared.typeToText(self.type)) \(self)"
    }

    /// Fuse the given atom with this one by combining their nucleii.
    func fuse(atom: MTMathAtom) {
        if self.subScript != nil {
            fatalError("Cannot fuse into an atom which has a subscript: \(self)")
        }
        if self.superScript != nil {
            fatalError("Cannot fuse into an atom which has a superscript: \(self)")
        }
        if self.type != atom.type {
            fatalError("Only atoms of the same type can be fused: \(self) \(atom)")
        }

        if fusedAtoms.isEmpty {
            fusedAtoms.append(self.copyDeep())
        }
        if !atom.fusedAtoms.isEmpty {
            fusedAtoms.append(contentsOf: atom.fusedAtoms)
        } else {
            fusedAtoms.append(atom)
        }
        self.nucleus += atom.nucleus
        self.indexRange.length += atom.indexRange.length
        self.subScript = atom.subScript
        self.superScript = atom.superScript
    }
}

// Fractions have no nucleus and are always KMTMathAtomFraction type
class MTFraction: MTMathAtom {

    /// Numerator of the fraction
    var numerator: MTMathList? = nil

    /// Denominator of the fraction
    var denominator: MTMathList? = nil

    /**If true, the fraction has a rule (i.e. a line) between the numerator and denominator.
    The default value is true. */
    var hasRule: Bool = true

    /** An optional delimiter for a fraction on the left. */
    var leftDelimiter: String? = nil

    /** An optional delimiter for a fraction on the right. */
    var rightDelimiter: String? = nil

    init() {
        super.init(type: .kMTMathAtomFraction, nucleus: "")
    }

    // fractions have no nucleus
    convenience init(rule: Bool = true) {
        self.init()
        self.hasRule = rule
    }

    override func toLatexString() -> String {
        var str = ""

        str += self.hasRule ? "\\frac" : "\\atop"

        if self.leftDelimiter != nil || self.rightDelimiter != nil {
            str += "[\(self.leftDelimiter ?? "")][\(self.rightDelimiter ?? "")]"
        }

        var nStr = ""
        if let num = self.numerator {
            nStr = MTMathListBuilder.Factory.toLatexString(num)
        }
        var dStr = ""
        if let den = self.denominator {
            dStr = MTMathListBuilder.Factory.toLatexString(den)
        }
        str += "{\(nStr)}{\(dStr)}"

        return super.toStringSubs(s: str)
    }

    override func copyDeep() -> MTFraction {
        let atom = MTFraction(rule: self.hasRule)
        super.copyDeepContent(atom: atom)
        atom.hasRule = self.hasRule
        atom.numerator = self.numerator?.copyDeep()
        atom.denominator = self.denominator?.copyDeep()
        atom.leftDelimiter = self.leftDelimiter
        atom.rightDelimiter = self.rightDelimiter
        return atom
    }

    override func finalized() -> MTFraction {
        let newFrac = self.copyDeep()
        super.finalized(newNode: newFrac)
        newFrac.numerator = newFrac.numerator?.finalized()
        newFrac.denominator = newFrac.denominator?.finalized()
        return newFrac
    }
}

// Radicals have no nucleus and are always KMTMathAtomRadical type
class MTRadical: MTMathAtom {
    /// Denotes the degree of the radical, i.e. the value to the top left of the radical sign
    /// This can be null if there is no degree.
    var degree: MTMathList? = nil

    /// Denotes the term under the square root sign
    ///
    var radicand: MTMathList? = nil

    init() {
        super.init(type: .kMTMathAtomRadical, nucleus: "")
    }

    override func toLatexString() -> String {
        var str = "\\sqrt"

        if let deg = self.degree {
            let dStr = MTMathListBuilder.Factory.toLatexString(deg)
            str += "[\(dStr)]"
        }

        var rStr = ""
        if let rad = self.radicand {
            rStr = MTMathListBuilder.Factory.toLatexString(rad)
        }

        str += "{\(rStr)}"

        return super.toStringSubs(s: str)
    }

    override func copyDeep() -> MTRadical {
        let atom = MTRadical()
        super.copyDeepContent(atom: atom)
        atom.radicand = self.radicand?.copyDeep()
        atom.degree = self.degree?.copyDeep()
        return atom
    }

    override func finalized() -> MTRadical {
        let newRad = self.copyDeep()
        super.finalized(newNode: newRad)
        newRad.radicand = newRad.radicand?.finalized()
        newRad.degree = newRad.degree?.finalized()
        return newRad
    }
}

class MTLargeOperator: MTMathAtom {
    var hasLimits: Bool = false

    init(nucleus: String) {
        super.init(type: .kMTMathAtomLargeOperator, nucleus: nucleus)
    }

    convenience init(nucleus: String, limits: Bool) {
        self.init(nucleus: nucleus)
        self.hasLimits = limits
    }

    override func copyDeep() -> MTLargeOperator {
        let atom = MTLargeOperator(nucleus: nucleus, limits: hasLimits)
        super.copyDeepContent(atom: atom)
        return atom
    }
}

// Inners have no nucleus and are always KMTMathAtomInner type
class MTInner: MTMathAtom {
    /// The inner math list
    var innerList: MTMathList? = nil

    /// The left boundary atom. This must be a node of type KMTMathAtomBoundary
    var leftBoundary: MTMathAtom? = nil {
        didSet {
            if let value = leftBoundary, value.type != .kMTMathAtomBoundary {
                fatalError("Left boundary must be of type KMTMathAtomBoundary \(value)")
            }
        }
    }

    init() {
        super.init(type: .kMTMathAtomInner, nucleus: "")
    }

    /// The right boundary atom. This must be a node of type KMTMathAtomBoundary
    var rightBoundary: MTMathAtom? = nil {
        didSet {
            if let value = rightBoundary, value.type != .kMTMathAtomBoundary {
                fatalError("Right boundary must be of type KMTMathAtomBoundary \(value)")
            }
        }
    }

    override func toLatexString() -> String {
        var str = "\\inner"

        if let lb = self.leftBoundary {
            str += "[\(lb.nucleus)]"
        }

        if let il = self.innerList {
            let iStr = MTMathListBuilder.Factory.toLatexString(il)
            str += "{\(iStr)}"
        } else {
            str += "{}"
        }

        if let rb = self.rightBoundary {
            str += "[\(rb.nucleus)]"
        }

        return super.toStringSubs(s: str)
    }

    override func copyDeep() -> MTInner {
        let atom = MTInner()
        super.copyDeepContent(atom: atom)
        atom.innerList = self.innerList?.copyDeep()
        atom.leftBoundary = self.leftBoundary?.copyDeep()
        atom.rightBoundary = self.rightBoundary?.copyDeep()
        return atom
    }

    override func finalized() -> MTInner {
        let newInner = self.copyDeep()
        super.finalized(newNode: newInner)
        newInner.innerList = newInner.innerList?.finalized()
        newInner.leftBoundary = newInner.leftBoundary?.finalized()
        newInner.rightBoundary = newInner.rightBoundary?.finalized()
        return newInner
    }
}

// OverLines have no nucleus and are always KMTMathAtomOverline type
class MTOverLine: MTMathAtom {

    /// The inner math list
    var innerList: MTMathList? = nil

    init() {
        super.init(type: .kMTMathAtomOverline, nucleus: "")
    }

    override func toLatexString() -> String {
        if let il = self.innerList {
            let iStr = MTMathListBuilder.Factory.toLatexString(il)
            return "{\(iStr)}"
        }
        return "{}"
    }

    override func copyDeep() -> MTOverLine {
        let atom = MTOverLine()
        super.copyDeepContent(atom: atom)
        atom.innerList = self.innerList?.copyDeep()
        return atom
    }

    override func finalized() -> MTOverLine {
        let newOverLine = self.copyDeep()
        super.finalized(newNode: newOverLine)
        newOverLine.innerList = newOverLine.innerList?.finalized()
        return newOverLine
    }
}

// UnderLines have no nucleus and are always KMTMathAtomUnderline type
class MTUnderLine: MTMathAtom {

    /// The inner math list
    var innerList: MTMathList? = nil

    init() {
        super.init(type: .kMTMathAtomUnderline, nucleus: "")
    }

    override func toLatexString() -> String {
        if let il = self.innerList {
            let iStr = MTMathListBuilder.Factory.toLatexString(il)
            return "{\(iStr)}"
        }
        return "{}"
    }

    override func copyDeep() -> MTUnderLine {
        let atom = MTUnderLine()
        super.copyDeepContent(atom: atom)
        atom.innerList = self.innerList?.copyDeep()
        return atom
    }

    override func finalized() -> MTUnderLine {
        let newUnderLine = self.copyDeep()
        super.finalized(newNode: newUnderLine)
        newUnderLine.innerList = newUnderLine.innerList?.finalized()
        return newUnderLine
    }
}

// Accents are always KMTMathAtomUnderline type
class MTAccent: MTMathAtom {

    /// The inner math list
    var innerList: MTMathList? = nil

    init(nucleus: String) {
        super.init(type: .kMTMathAtomAccent, nucleus: nucleus)
    }

    override func toLatexString() -> String {
        if let il = self.innerList {
            let iStr = MTMathListBuilder.Factory.toLatexString(il)
            return "{\(iStr)}"
        }
        return "{}"
    }

    override func copyDeep() -> MTAccent {
        let atom = MTAccent(nucleus: nucleus)
        super.copyDeepContent(atom: atom)
        atom.innerList = self.innerList?.copyDeep()
        return atom
    }

    override func finalized() -> MTAccent {
        let newAccent = self.copyDeep()
        super.finalized(newNode: newAccent)
        newAccent.innerList = newAccent.innerList?.finalized()
        return newAccent
    }
}

// Spaces  are  KMTMathAtomSpace with a float for space and no nucleus
class MTMathSpace: MTMathAtom {
    var space: Float = 0.0

    init() {
        super.init(type: .kMTMathAtomSpace, nucleus: "")
    }

    convenience init(space: Float) {
        self.init()
        self.space = space
    }

    override func copyDeep() -> MTMathSpace {
        let atom = MTMathSpace(space: space)
        super.copyDeepContent(atom: atom)
        return atom
    }

}

/**
@typedef MTLineStyle
@brief Styling of a line of math
 */
enum MTLineStyle: Comparable {
    /// Display style
    case kMTLineStyleDisplay

    /// Text style (inline)
    case kMTLineStyleText

    /// Script style (for sub/super scripts)
    case kMTLineStyleScript

    /// Script script style (for scripts of scripts)
    case kMTLineStyleScriptScript

    var ordinal: Int {
        switch self {
        case .kMTLineStyleDisplay:
            return 0
        case .kMTLineStyleText:
            return 1
        case .kMTLineStyleScript:
            return 2
        case .kMTLineStyleScriptScript:
            return 3
        }
    }

    static func <(lhs: MTLineStyle, rhs: MTLineStyle) -> Bool {
        return lhs.ordinal < rhs.ordinal
    }
}

// Styles are  KMTMathAtomStyle with a MTLineStyle and no nucleus
class MTMathStyle: MTMathAtom {

    var style: MTLineStyle = .kMTLineStyleDisplay

    init() {
        super.init(type: .kMTMathAtomStyle, nucleus: "")
    }

    convenience init(style: MTLineStyle) {
        self.init()
        self.style = style
    }

    override func copyDeep() -> MTMathStyle {
        let atom = MTMathStyle(style: style)
        super.copyDeepContent(atom: atom)
        return atom
    }
}

// Colors are always KMTMathAtomColor type with a string for the color
class MTMathColor: MTMathAtom {

    /// The inner math list
    var innerList: MTMathList? = nil
    var colorString: String? = nil

    init() {
        super.init(type: .kMTMathAtomColor, nucleus: "")
    }

    override func toLatexString() -> String {
        var str = "\\color"
        str += "{\(self.colorString ?? "")}{\(self.innerList ?? MTMathList())}"
        return super.toStringSubs(s: str)
    }

    override func copyDeep() -> MTMathColor {
        let atom = MTMathColor()
        super.copyDeepContent(atom: atom)
        atom.innerList = self.innerList?.copyDeep()
        atom.colorString = self.colorString
        return atom
    }

    override func finalized() -> MTMathColor {
        let newColor = self.copyDeep()
        super.finalized(newNode: newColor)
        newColor.innerList = newColor.innerList?.finalized()
        return newColor
    }
}

// Colors are always KMTMathAtomColor type with a string for the color
class MTMathTextColor: MTMathAtom {

    /// The inner math list
    var innerList: MTMathList? = nil
    var colorString: String? = nil

    init() {
        super.init(type: .kMTMathAtomTextColor, nucleus: "")
    }

    override func toLatexString() -> String {
        var str = "\\textcolor"
        str += "{\(self.colorString ?? "")}{\(self.innerList ?? MTMathList())}"
        return super.toStringSubs(s: str)
    }

    override func copyDeep() -> MTMathTextColor {
        let atom = MTMathTextColor()
        super.copyDeepContent(atom: atom)
        atom.innerList = self.innerList?.copyDeep()
        atom.colorString = self.colorString
        return atom
    }

    override func finalized() -> MTMathTextColor {
        let newColor = self.copyDeep()
        super.finalized(newNode: newColor)
        newColor.innerList = newColor.innerList?.finalized()
        return newColor
    }
}
