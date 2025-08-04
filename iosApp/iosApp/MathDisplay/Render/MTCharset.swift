import Foundation

/**
 * Created by greg on 3/13/18.
 */

/*
   A string is a sequence of characters that could be 1 or 2 in length to represent a unicode charater.
   Given a string return the number of characters compensating
 */
func numberOfGlyphs(_ s: String) -> Int {
    return s.unicodeScalars.count
}

struct CGGlyph {
    var gid: Int = 0
    var glyphAscent: Float = 0.0
    var glyphDescent: Float = 0.0
    var glyphWidth: Float = 0.0

    var isValid: Bool {
        return gid != 0
    }
}

let kMTUnicodeGreekLowerStart: Character = "\u{03B1}"
let kMTUnicodeGreekLowerEnd: Character = "\u{03C9}"
let kMTUnicodeGreekCapitalStart: Character = "\u{0391}"
let kMTUnicodeGreekCapitalEnd: Character = "\u{03A9}"

// Note this is not equivalent to ch.isLowerCase() delta is a test case
func isLowerEn(_ ch: Character) -> Bool {
    return ch >= "a" && ch <= "z"
}

func isUpperEn(_ ch: Character) -> Bool {
    return ch >= "A" && ch <= "Z"
}

func isNumber(_ ch: Character) -> Bool {
    return ch >= "0" && ch <= "9"
}

func isLowerGreek(_ ch: Character) -> Bool {
    return ch >= kMTUnicodeGreekLowerStart && ch <= kMTUnicodeGreekLowerEnd
}

func isCapitalGreek(_ ch: Character) -> Bool {
    return ch >= kMTUnicodeGreekCapitalStart && ch <= kMTUnicodeGreekCapitalEnd
}

func greekSymbolOrder(_ ch: Character) -> Int {
    // These greek symbols that always appear in unicode in this particular order after the alphabet
    // The symbols are epsilon, vartheta, varkappa, phi, varrho, varpi.
    let greekSymbols: [UInt32] = [0x03F5, 0x03D1, 0x03F0, 0x03D5, 0x03F1, 0x03D6]
    guard let scalar = ch.unicodeScalars.first else {
        return -1
    }
    return greekSymbols.firstIndex(of: scalar.value) ?? -1
}

func isGREEKSYMBOL(_ ch: Character) -> Bool {
    return greekSymbolOrder(ch) != -1
}

class MTCodepointChar {
    let codepoint: Int

    init(_ codepoint: Int) {
        self.codepoint = codepoint
    }

    func toUnicodeString() -> String {
        return String(UnicodeScalar(codepoint) ?? Character(" ").unicodeScalars.first!)
    }
}

// mathit
let kMTUnicodePlanksConstant = 0x210e
let kMTUnicodeMathCapitalItalicStart = 0x1D434
let kMTUnicodeMathLowerItalicStart = 0x1D44E
let kMTUnicodeGreekCapitalItalicStart = 0x1D6E2
let kMTUnicodeGreekLowerItalicStart = 0x1D6FC
let kMTUnicodeGreekSymbolItalicStart = 0x1D716

func getItalicized(_ ch: Character) -> MTCodepointChar {
    // Special cases for italics
    switch ch {
    case "h": // italic h (plank's constant)
        return MTCodepointChar(kMTUnicodePlanksConstant)

    case _ where isUpperEn(ch):
        return MTCodepointChar(kMTUnicodeMathCapitalItalicStart + Int(ch.asciiValue! - Character("A").asciiValue!))

    case _ where isLowerEn(ch):
        return MTCodepointChar(kMTUnicodeMathLowerItalicStart + Int(ch.asciiValue! - Character("a").asciiValue!))

    case _ where isCapitalGreek(ch):
        // Capital Greek characters
        guard let startScalar = kMTUnicodeGreekCapitalStart.unicodeScalars.first else {
            return MTCodepointChar(Int(ch.asciiValue!))
        }
        return MTCodepointChar(kMTUnicodeGreekCapitalItalicStart + Int(ch.unicodeScalars.first!.value - startScalar.value))

    case _ where isLowerGreek(ch):
        // Greek characters
        guard let startScalar = kMTUnicodeGreekLowerStart.unicodeScalars.first else {
            return MTCodepointChar(Int(ch.asciiValue!))
        }
        return MTCodepointChar(kMTUnicodeGreekLowerItalicStart + Int(ch.unicodeScalars.first!.value - startScalar.value))

    case _ where isGREEKSYMBOL(ch):
        return MTCodepointChar(kMTUnicodeGreekSymbolItalicStart + greekSymbolOrder(ch))

    default:
        // Note there are no italicized numbers in unicode so we don't support italicizing numbers.
        return MTCodepointChar(Int(ch.unicodeScalars.first!.value))
    }
}

// mathbf
let kMTUnicodeMathCapitalBoldStart = 0x1D400
let kMTUnicodeMathLowerBoldStart = 0x1D41A
let kMTUnicodeGreekCapitalBoldStart = 0x1D6A8
let kMTUnicodeGreekLowerBoldStart = 0x1D6C2
let kMTUnicodeGreekSymbolBoldStart = 0x1D6DC
let kMTUnicodeNumberBoldStart = 0x1D7CE

func getBold(_ ch: Character) -> MTCodepointChar {
    if isUpperEn(ch) {
        return MTCodepointChar(kMTUnicodeMathCapitalBoldStart + Int(ch.unicodeScalars.first!.value - 65)) // 'A' is ASCII 65
    } else if isLowerEn(ch) {
        return MTCodepointChar(kMTUnicodeMathLowerBoldStart + Int(ch.unicodeScalars.first!.value - 97)) // 'a' is ASCII 97
    } else if isCapitalGreek(ch) {
        // Capital Greek characters
        return MTCodepointChar(kMTUnicodeGreekCapitalBoldStart + Int(ch.unicodeScalars.first!.value - kMTUnicodeGreekCapitalStart.unicodeScalars.first!.value))
    } else if isLowerGreek(ch) {
        // Greek characters
        return MTCodepointChar(kMTUnicodeGreekLowerBoldStart + Int(ch.unicodeScalars.first!.value - kMTUnicodeGreekLowerStart.unicodeScalars.first!.value))
    } else if isGREEKSYMBOL(ch) {
        return MTCodepointChar(kMTUnicodeGreekSymbolBoldStart + greekSymbolOrder(ch))
    } else if isNumber(ch) {
        return MTCodepointChar(kMTUnicodeNumberBoldStart + Int(ch.unicodeScalars.first!.value - 48)) // '0' is ASCII 48
    }
    return MTCodepointChar(Int(ch.unicodeScalars.first!.value))
}

// mathbfit
let kMTUnicodeMathCapitalBoldItalicStart = 0x1D468
let kMTUnicodeMathLowerBoldItalicStart = 0x1D482
let kMTUnicodeGreekCapitalBoldItalicStart = 0x1D71C
let kMTUnicodeGreekLowerBoldItalicStart = 0x1D736
let kMTUnicodeGreekSymbolBoldItalicStart = 0x1D750

func getBoldItalic(_ ch: Character) -> MTCodepointChar {
    if isUpperEn(ch) {
        return MTCodepointChar(kMTUnicodeMathCapitalBoldItalicStart + Int(ch.unicodeScalars.first!.value - 65)) // 'A' is ASCII 65
    } else if isLowerEn(ch) {
        return MTCodepointChar(kMTUnicodeMathLowerBoldItalicStart + Int(ch.unicodeScalars.first!.value - 97)) // 'a' is ASCII 97
    } else if isCapitalGreek(ch) {
        // Capital Greek characters
        return MTCodepointChar(kMTUnicodeGreekCapitalBoldItalicStart + Int(ch.unicodeScalars.first!.value - kMTUnicodeGreekCapitalStart.unicodeScalars.first!.value))
    } else if isLowerGreek(ch) {
        // Greek characters
        return MTCodepointChar(kMTUnicodeGreekLowerBoldItalicStart + Int(ch.unicodeScalars.first!.value - kMTUnicodeGreekLowerStart.unicodeScalars.first!.value))
    } else if isGREEKSYMBOL(ch) {
        return MTCodepointChar(kMTUnicodeGreekSymbolBoldItalicStart + greekSymbolOrder(ch))
    } else if isNumber(ch) {
        // No bold italic for numbers so we just bold them.
        return getBold(ch)
    }
    return MTCodepointChar(Int(ch.unicodeScalars.first!.value))
}

// LaTeX default
func getDefaultStyle(_ ch: Character) throws -> MTCodepointChar {
    if isLowerEn(ch) || isUpperEn(ch) || isLowerGreek(ch) || isGREEKSYMBOL(ch) {
        return getItalicized(ch)
    } else if isNumber(ch) || isCapitalGreek(ch) {
        return MTCodepointChar(Int(ch.asciiValue!))
    } else if ch == "." {
        // . is treated as a number in our code, but it doesn't change fonts.
        return MTCodepointChar(Int(ch.asciiValue!))
    }
    throw MathDisplayException("Unknown character \(ch) for default style.")
}

let kMTUnicodeMathCapitalScriptStart = 0x1D49C
// TODO(kostub): Unused in Latin Modern Math - if another font is used determine if
// this should be applicable.
// static const MTCodepointChar kMTUnicodeMathLowerScriptStart = 0x1D4B6;

// mathcal/mathscr (calligraphic or script)
func getCalligraphicChar(_ ch: Character) -> MTCodepointChar {
    // Calligraphic has lots of exceptions:
    switch ch {
    case "B":
        return MTCodepointChar(0x212C)   // Script B (bernoulli)
    case "E":
        return MTCodepointChar(0x2130)   // Script E (emf)
    case "F":
        return MTCodepointChar(0x2131)   // Script F (fourier)
    case "H":
        return MTCodepointChar(0x210B)   // Script H (hamiltonian)
    case "I":
        return MTCodepointChar(0x2110)   // Script I
    case "L":
        return MTCodepointChar(0x2112)   // Script L (laplace)
    case "M":
        return MTCodepointChar(0x2133)   // Script M (M-matrix)
    case "R":
        return MTCodepointChar(0x211B)   // Script R (Riemann integral)
    case "e":
        return MTCodepointChar(0x212F)   // Script e (Natural exponent)
    case "g":
        return MTCodepointChar(0x210A)   // Script g (real number)
    case "o":
        return MTCodepointChar(0x2134)   // Script o (order)
    default:
        break
    }
    if isUpperEn(ch) {
        return MTCodepointChar(kMTUnicodeMathCapitalScriptStart + Int(ch.asciiValue! - Character("A").asciiValue!))
    } else if isLowerEn(ch) {
        // Latin Modern Math does not have lower case calligraphic characters, so we use
        // the default style instead of showing a ?
        return try! getDefaultStyle(ch)
    }
    // Calligraphic characters don't exist for greek or numbers, we give them the
    // default treatment.
    return try! getDefaultStyle(ch)
}

let kMTUnicodeMathCapitalTTStart = 0x1D670
let kMTUnicodeMathLowerTTStart = 0x1D68A
let kMTUnicodeNumberTTStart = 0x1D7F6

// mathtt (monospace)
func getTypewriter(_ ch: Character) -> MTCodepointChar {
    if isUpperEn(ch) {
        return MTCodepointChar(kMTUnicodeMathCapitalTTStart + Int(ch.asciiValue! - Character("A").asciiValue!))
    } else if isLowerEn(ch) {
        return MTCodepointChar(kMTUnicodeMathLowerTTStart + Int(ch.asciiValue! - Character("a").asciiValue!))
    } else if isNumber(ch) {
        return MTCodepointChar(kMTUnicodeNumberTTStart + Int(ch.asciiValue! - Character("0").asciiValue!))
    } else {
        // Monospace characters don't exist for greek, we give them the
        // default treatment.
        return try! getDefaultStyle(ch)
    }
}

let kMTUnicodeMathCapitalSansSerifStart = 0x1D5A0
let kMTUnicodeMathLowerSansSerifStart = 0x1D5BA
let kMTUnicodeNumberSansSerifStart = 0x1D7E2

// mathsf
func getSansSerif(_ ch: Character) -> MTCodepointChar {
    if isUpperEn(ch) {
        return MTCodepointChar(kMTUnicodeMathCapitalSansSerifStart + Int(ch.asciiValue! - Character("A").asciiValue!))
    } else if isLowerEn(ch) {
        return MTCodepointChar(kMTUnicodeMathLowerSansSerifStart + Int(ch.asciiValue! - Character("a").asciiValue!))
    } else if isNumber(ch) {
        return MTCodepointChar(kMTUnicodeNumberSansSerifStart + Int(ch.asciiValue! - Character("0").asciiValue!))
    } else {
        // Sans-serif characters don't exist for greek, we give them the
        // default treatment.
        return try! getDefaultStyle(ch)
    }
}

let kMTUnicodeMathCapitalFrakturStart = 0x1D504
let kMTUnicodeMathLowerFrakturStart = 0x1D51E

// mathfrak
func getFraktur(_ ch: Character) -> MTCodepointChar {
    // Fraktur has exceptions:
    switch ch {
    case "C":
        return MTCodepointChar(0x212D)   // C Fraktur
    case "H":
        return MTCodepointChar(0x210C)   // Hilbert space
    case "I":
        return MTCodepointChar(0x2111)   // Imaginary
    case "R":
        return MTCodepointChar(0x211C)   // Real
    case "Z":
        return MTCodepointChar(0x2128)   // Z Fraktur
    default:
        break
    }
    if isUpperEn(ch) {
        return MTCodepointChar(kMTUnicodeMathCapitalFrakturStart + Int((ch.asciiValue! - Character("A").asciiValue!)))
    } else if isLowerEn(ch) {
        return MTCodepointChar(kMTUnicodeMathLowerFrakturStart + Int((ch.asciiValue! - Character("a").asciiValue!)))
    }
    // Fraktur characters don't exist for greek & numbers, we give them the
    // default treatment.
    return try! getDefaultStyle(ch)
}

let kMTUnicodeMathCapitalBlackboardStart = 0x1D538
let kMTUnicodeMathLowerBlackboardStart = 0x1D552
let kMTUnicodeNumberBlackboardStart = 0x1D7D8

// mathbb (double struck)
func getBlackboard(_ ch: Character) -> MTCodepointChar {
    // Blackboard has lots of exceptions:
    switch ch {
    case "C":
        return MTCodepointChar(0x2102)  // Complex numbers
    case "H":
        return MTCodepointChar(0x210D)  // Quaternions
    case "N":
        return MTCodepointChar(0x2115)   // Natural numbers
    case "P":
        return MTCodepointChar(0x2119)   // Primes
    case "Q":
        return MTCodepointChar(0x211A)   // Rationals
    case "R":
        return MTCodepointChar(0x211D)   // Reals
    case "Z":
        return MTCodepointChar(0x2124)  // Integers
    default:
        break
    }
    if isUpperEn(ch) {
        return MTCodepointChar(kMTUnicodeMathCapitalBlackboardStart + Int((ch.asciiValue! - Character("A").asciiValue!)))
    } else if isLowerEn(ch) {
        return MTCodepointChar(kMTUnicodeMathLowerBlackboardStart + Int((ch.asciiValue! - Character("a").asciiValue!)))
    } else if isNumber(ch) {
        return MTCodepointChar(kMTUnicodeNumberBlackboardStart + Int((ch.asciiValue! - Character("0").asciiValue!)))
    }
    // Blackboard characters don't exist for greek, we give them the
    // default treatment.
    return try! getDefaultStyle(ch)
}

func styleCharacter(_ ch: Character, fontStyle: MTFontStyle) -> MTCodepointChar {
    switch fontStyle {
    case .KMTFontStyleDefault:
        return try! getDefaultStyle(ch)
    case .KMTFontStyleRoman:
        return MTCodepointChar(Int(ch.asciiValue!))
    case .KMTFontStyleBold:
        return getBold(ch)
    case .KMTFontStyleItalic:
        return getItalicized(ch)
    case .KMTFontStyleBoldItalic:
        return getBoldItalic(ch)
    case .KMTFontStyleCaligraphic:
        return getCalligraphicChar(ch)
    case .KMTFontStyleTypewriter:
        return getTypewriter(ch)
    case .KMTFontStyleSansSerif:
        return getSansSerif(ch)
    case .KMTFontStyleFraktur:
        return getFraktur(ch)
    case .KMTFontStyleBlackboard:
        return getBlackboard(ch)
    }
}

// This can only take single unicode character sequence as input.
// Should never be called with a codepoint that requires 2 escaped characters to represent
func changeFont(_ str: String, fontStyle: MTFontStyle) -> String {
    var ret = ""
    let ca = Array(str)
    for ch in ca {
        let codepoint = styleCharacter(ch, fontStyle: fontStyle)
        ret.append(codepoint.toUnicodeString())
    }
    return ret
}
