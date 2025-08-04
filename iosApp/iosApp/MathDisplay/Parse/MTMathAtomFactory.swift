import Foundation

private let MTSymbolMultiplication = "\u{00D7}"
private let MTSymbolDivision = "\u{00F7}"
private let MTSymbolFractionSlash = "\u{2044}"
private let MTSymbolWhiteSquare = "\u{25A1}"
private let MTSymbolBlackSquare = "\u{25A0}"
private let MTSymbolLessEqual = "\u{2264}"
private let MTSymbolGreaterEqual = "\u{2265}"
private let MTSymbolNotEqual = "\u{2260}"
private let MTSymbolSquareRoot = "\u{221A}" // \sqrt
private let MTSymbolCubeRoot = "\u{221B}"
private let MTSymbolInfinity = "\u{221E}" // \infty
private let MTSymbolAngle = "\u{2220}" // \angle
private let MTSymbolDegree = "\u{00B0}" // \circ

open class MTMathAtomFactory {
    private var supportedLatexSymbols: [String: MTMathAtom] = [
        "square": placeholder(),

        // Greek characters
        "alpha": MTMathAtom(type: .kMTMathAtomVariable, nucleus: "\u{03B1}"),
        "beta": MTMathAtom(type: .kMTMathAtomVariable, nucleus: "\u{03B2}"),
        "gamma": MTMathAtom(type: .kMTMathAtomVariable, nucleus: "\u{03B3}"),
        "delta": MTMathAtom(type: .kMTMathAtomVariable, nucleus: "\u{03B4}"),
        "varepsilon": MTMathAtom(type: .kMTMathAtomVariable, nucleus: "\u{03B5}"),
        "zeta": MTMathAtom(type: .kMTMathAtomVariable, nucleus: "\u{03B6}"),
        "eta": MTMathAtom(type: .kMTMathAtomVariable, nucleus: "\u{03B7}"),
        "theta": MTMathAtom(type: .kMTMathAtomVariable, nucleus: "\u{03B8}"),
        "iota": MTMathAtom(type: .kMTMathAtomVariable, nucleus: "\u{03B9}"),
        "kappa": MTMathAtom(type: .kMTMathAtomVariable, nucleus: "\u{03BA}"),
        "lambda": MTMathAtom(type: .kMTMathAtomVariable, nucleus: "\u{03BB}"),
        "mu": MTMathAtom(type: .kMTMathAtomVariable, nucleus: "\u{03BC}"),
        "nu": MTMathAtom(type: .kMTMathAtomVariable, nucleus: "\u{03BD}"),
        "xi": MTMathAtom(type: .kMTMathAtomVariable, nucleus: "\u{03BE}"),
        "omicron": MTMathAtom(type: .kMTMathAtomVariable, nucleus: "\u{03BF}"),
        "pi": MTMathAtom(type: .kMTMathAtomVariable, nucleus: "\u{03C0}"),
        "rho": MTMathAtom(type: .kMTMathAtomVariable, nucleus: "\u{03C1}"),
        "varsigma": MTMathAtom(type: .kMTMathAtomVariable, nucleus: "\u{03C2}"),
        "sigma": MTMathAtom(type: .kMTMathAtomVariable, nucleus: "\u{03C3}"),
        "tau": MTMathAtom(type: .kMTMathAtomVariable, nucleus: "\u{03C4}"),
        "upsilon": MTMathAtom(type: .kMTMathAtomVariable, nucleus: "\u{03C5}"),
        "varphi": MTMathAtom(type: .kMTMathAtomVariable, nucleus: "\u{03C6}"),
        "chi": MTMathAtom(type: .kMTMathAtomVariable, nucleus: "\u{03C7}"),
        "psi": MTMathAtom(type: .kMTMathAtomVariable, nucleus: "\u{03C8}"),
        "omega": MTMathAtom(type: .kMTMathAtomVariable, nucleus: "\u{03C9}"),

        "vartheta": MTMathAtom(type: .kMTMathAtomVariable, nucleus: "\u{03D1}"),
        "phi": MTMathAtom(type: .kMTMathAtomVariable, nucleus: "\u{03D5}"),
        "varpi": MTMathAtom(type: .kMTMathAtomVariable, nucleus: "\u{03D6}"),
        "varkappa": MTMathAtom(type: .kMTMathAtomVariable, nucleus: "\u{03F0}"),
        "varrho": MTMathAtom(type: .kMTMathAtomVariable, nucleus: "\u{03F1}"),
        "epsilon": MTMathAtom(type: .kMTMathAtomVariable, nucleus: "\u{03F5}"),

        // Capital greek characters
        "Gamma": MTMathAtom(type: .kMTMathAtomVariable, nucleus: "\u{0393}"),
        "Delta": MTMathAtom(type: .kMTMathAtomVariable, nucleus: "\u{0394}"),
        "Theta": MTMathAtom(type: .kMTMathAtomVariable, nucleus: "\u{0398}"),
        "Lambda": MTMathAtom(type: .kMTMathAtomVariable, nucleus: "\u{039B}"),
        "Xi": MTMathAtom(type: .kMTMathAtomVariable, nucleus: "\u{039E}"),
        "Pi": MTMathAtom(type: .kMTMathAtomVariable, nucleus: "\u{03A0}"),
        "Sigma": MTMathAtom(type: .kMTMathAtomVariable, nucleus: "\u{03A3}"),
        "Upsilon": MTMathAtom(type: .kMTMathAtomVariable, nucleus: "\u{03A5}"),
        "Phi": MTMathAtom(type: .kMTMathAtomVariable, nucleus: "\u{03A6}"),
        "Psi": MTMathAtom(type: .kMTMathAtomVariable, nucleus: "\u{03A8}"),
        "Omega": MTMathAtom(type: .kMTMathAtomVariable, nucleus: "\u{03A9}"),

        // Open
        "lceil": MTMathAtom(type: .kMTMathAtomOpen, nucleus: "\u{2308}"),
        "lfloor": MTMathAtom(type: .kMTMathAtomOpen, nucleus: "\u{230A}"),
        "langle": MTMathAtom(type: .kMTMathAtomOpen, nucleus: "\u{27E8}"),
        "lgroup": MTMathAtom(type: .kMTMathAtomOpen, nucleus: "\u{27EE}"),

        // Close
        "rceil": MTMathAtom(type: .kMTMathAtomClose, nucleus: "\u{2309}"),
        "rfloor": MTMathAtom(type: .kMTMathAtomClose, nucleus: "\u{230B}"),
        "rangle": MTMathAtom(type: .kMTMathAtomClose, nucleus: "\u{27E9}"),
        "rgroup": MTMathAtom(type: .kMTMathAtomClose, nucleus: "\u{27EF}"),

        // Arrows
        "leftarrow": MTMathAtom(type: .kMTMathAtomRelation, nucleus: "\u{2190}"),
        "uparrow": MTMathAtom(type: .kMTMathAtomRelation, nucleus: "\u{2191}"),
        "rightarrow": MTMathAtom(type: .kMTMathAtomRelation, nucleus: "\u{2192}"),
        "downarrow": MTMathAtom(type: .kMTMathAtomRelation, nucleus: "\u{2193}"),
        "leftrightarrow": MTMathAtom(type: .kMTMathAtomRelation, nucleus: "\u{2194}"),
        "updownarrow": MTMathAtom(type: .kMTMathAtomRelation, nucleus: "\u{2195}"),
        "nwarrow": MTMathAtom(type: .kMTMathAtomRelation, nucleus: "\u{2196}"),
        "nearrow": MTMathAtom(type: .kMTMathAtomRelation, nucleus: "\u{2197}"),
        "searrow": MTMathAtom(type: .kMTMathAtomRelation, nucleus: "\u{2198}"),
        "swarrow": MTMathAtom(type: .kMTMathAtomRelation, nucleus: "\u{2199}"),
        "mapsto": MTMathAtom(type: .kMTMathAtomRelation, nucleus: "\u{21A6}"),
        "Leftarrow": MTMathAtom(type: .kMTMathAtomRelation, nucleus: "\u{21D0}"),
        "Uparrow": MTMathAtom(type: .kMTMathAtomRelation, nucleus: "\u{21D1}"),
        "Rightarrow": MTMathAtom(type: .kMTMathAtomRelation, nucleus: "\u{21D2}"),
        "Downarrow": MTMathAtom(type: .kMTMathAtomRelation, nucleus: "\u{21D3}"),
        "Leftrightarrow": MTMathAtom(type: .kMTMathAtomRelation, nucleus: "\u{21D4}"),
        "Updownarrow": MTMathAtom(type: .kMTMathAtomRelation, nucleus: "\u{21D5}"),
        "longleftarrow": MTMathAtom(type: .kMTMathAtomRelation, nucleus: "\u{27F5}"),
        "longrightarrow": MTMathAtom(type: .kMTMathAtomRelation, nucleus: "\u{27F6}"),
        "longleftrightarrow": MTMathAtom(type: .kMTMathAtomRelation, nucleus: "\u{27F7}"),
        "Longleftarrow": MTMathAtom(type: .kMTMathAtomRelation, nucleus: "\u{27F8}"),
        "Longrightarrow": MTMathAtom(type: .kMTMathAtomRelation, nucleus: "\u{27F9}"),
        "Longleftrightarrow": MTMathAtom(type: .kMTMathAtomRelation, nucleus: "\u{27FA}"),

        // Relations
        "leq": MTMathAtom(type: .kMTMathAtomRelation, nucleus: MTSymbolLessEqual),
        "geq": MTMathAtom(type: .kMTMathAtomRelation, nucleus: MTSymbolGreaterEqual),
        "neq": MTMathAtom(type: .kMTMathAtomRelation, nucleus: MTSymbolNotEqual),
        "in": MTMathAtom(type: .kMTMathAtomRelation, nucleus: "\u{2208}"),
        "notin": MTMathAtom(type: .kMTMathAtomRelation, nucleus: "\u{2209}"),
        "ni": MTMathAtom(type: .kMTMathAtomRelation, nucleus: "\u{220B}"),
        "propto": MTMathAtom(type: .kMTMathAtomRelation, nucleus: "\u{221D}"),
        "mid": MTMathAtom(type: .kMTMathAtomRelation, nucleus: "\u{2223}"),
        "parallel": MTMathAtom(type: .kMTMathAtomRelation, nucleus: "\u{2225}"),
        "sim": MTMathAtom(type: .kMTMathAtomRelation, nucleus: "\u{223C}"),
        "simeq": MTMathAtom(type: .kMTMathAtomRelation, nucleus: "\u{2243}"),
        "cong": MTMathAtom(type: .kMTMathAtomRelation, nucleus: "\u{2245}"),
        "approx": MTMathAtom(type: .kMTMathAtomRelation, nucleus: "\u{2248}"),
        "asymp": MTMathAtom(type: .kMTMathAtomRelation, nucleus: "\u{224D}"),
        "doteq": MTMathAtom(type: .kMTMathAtomRelation, nucleus: "\u{2250}"),
        "equiv": MTMathAtom(type: .kMTMathAtomRelation, nucleus: "\u{2261}"),
        "gg": MTMathAtom(type: .kMTMathAtomRelation, nucleus: "\u{226A}"),
        "ll": MTMathAtom(type: .kMTMathAtomRelation, nucleus: "\u{226B}"),
        "prec": MTMathAtom(type: .kMTMathAtomRelation, nucleus: "\u{227A}"),
        "succ": MTMathAtom(type: .kMTMathAtomRelation, nucleus: "\u{227B}"),
        "subset": MTMathAtom(type: .kMTMathAtomRelation, nucleus: "\u{2282}"),
        "supset": MTMathAtom(type: .kMTMathAtomRelation, nucleus: "\u{2283}"),
        "subseteq": MTMathAtom(type: .kMTMathAtomRelation, nucleus: "\u{2286}"),
        "supseteq": MTMathAtom(type: .kMTMathAtomRelation, nucleus: "\u{2287}"),
        "sqsubset": MTMathAtom(type: .kMTMathAtomRelation, nucleus: "\u{228F}"),
        "sqsupset": MTMathAtom(type: .kMTMathAtomRelation, nucleus: "\u{2290}"),
        "sqsubseteq": MTMathAtom(type: .kMTMathAtomRelation, nucleus: "\u{2291}"),
        "sqsupseteq": MTMathAtom(type: .kMTMathAtomRelation, nucleus: "\u{2292}"),
        "models": MTMathAtom(type: .kMTMathAtomRelation, nucleus: "\u{22A7}"),
        "perp": MTMathAtom(type: .kMTMathAtomRelation, nucleus: "\u{27C2}"),

        // operators
        "times": times(),
        "div": divide(),
        "pm": MTMathAtom(type: .kMTMathAtomBinaryOperator, nucleus: "\u{00B1}"),
        "dagger": MTMathAtom(type: .kMTMathAtomBinaryOperator, nucleus: "\u{2020}"),
        "ddagger": MTMathAtom(type: .kMTMathAtomBinaryOperator, nucleus: "\u{2021}"),
        "mp": MTMathAtom(type: .kMTMathAtomBinaryOperator, nucleus: "\u{2213}"),
        "setminus": MTMathAtom(type: .kMTMathAtomBinaryOperator, nucleus: "\u{2216}"),
        "ast": MTMathAtom(type: .kMTMathAtomBinaryOperator, nucleus: "\u{2217}"),
        "circ": MTMathAtom(type: .kMTMathAtomBinaryOperator, nucleus: "\u{2218}"),
        "bullet": MTMathAtom(type: .kMTMathAtomBinaryOperator, nucleus: "\u{2219}"),
        "wedge": MTMathAtom(type: .kMTMathAtomBinaryOperator, nucleus: "\u{2227}"),
        "vee": MTMathAtom(type: .kMTMathAtomBinaryOperator, nucleus: "\u{2228}"),
        "cap": MTMathAtom(type: .kMTMathAtomBinaryOperator, nucleus: "\u{2229}"),
        "cup": MTMathAtom(type: .kMTMathAtomBinaryOperator, nucleus: "\u{222A}"),
        "wr": MTMathAtom(type: .kMTMathAtomBinaryOperator, nucleus: "\u{2240}"),
        "uplus": MTMathAtom(type: .kMTMathAtomBinaryOperator, nucleus: "\u{228E}"),
        "sqcap": MTMathAtom(type: .kMTMathAtomBinaryOperator, nucleus: "\u{2293}"),
        "sqcup": MTMathAtom(type: .kMTMathAtomBinaryOperator, nucleus: "\u{2294}"),
        "oplus": MTMathAtom(type: .kMTMathAtomBinaryOperator, nucleus: "\u{2295}"),
        "ominus": MTMathAtom(type: .kMTMathAtomBinaryOperator, nucleus: "\u{2296}"),
        "otimes": MTMathAtom(type: .kMTMathAtomBinaryOperator, nucleus: "\u{2297}"),
        "oslash": MTMathAtom(type: .kMTMathAtomBinaryOperator, nucleus: "\u{2298}"),
        "odot": MTMathAtom(type: .kMTMathAtomBinaryOperator, nucleus: "\u{2299}"),
        "star": MTMathAtom(type: .kMTMathAtomBinaryOperator, nucleus: "\u{22C6}"),
        "cdot": MTMathAtom(type: .kMTMathAtomBinaryOperator, nucleus: "\u{22C5}"),
        "amalg": MTMathAtom(type: .kMTMathAtomBinaryOperator, nucleus: "\u{2A3F}"),

        // No limit operators
        "log": operatorWithName("log", limits: false),
        "lg": operatorWithName("lg", limits: false),
        "ln": operatorWithName("ln", limits: false),
        "sin": operatorWithName("sin", limits: false),
        "arcsin": operatorWithName("arcsin", limits: false),
        "sinh": operatorWithName("sinh", limits: false),
        "cos": operatorWithName("cos", limits: false),
        "arccos": operatorWithName("arccos", limits: false),
        "cosh": operatorWithName("cosh", limits: false),
        "tan": operatorWithName("tan", limits: false),
        "arctan": operatorWithName("arctan", limits: false),
        "tanh": operatorWithName("tanh", limits: false),
        "cot": operatorWithName("cot", limits: false),
        "coth": operatorWithName("coth", limits: false),
        "sec": operatorWithName("sec", limits: false),
        "csc": operatorWithName("csc", limits: false),
        "arg": operatorWithName("arg", limits: false),
        "ker": operatorWithName("ker", limits: false),
        "dim": operatorWithName("dim", limits: false),
        "hom": operatorWithName("hom", limits: false),
        "exp": operatorWithName("exp", limits: false),
        "deg": operatorWithName("deg", limits: false),

        // Limit operators
        "lim": operatorWithName("lim", limits: true),
        "limsup": operatorWithName("lim sup", limits: true),
        "liminf": operatorWithName("lim inf", limits: true),
        "max": operatorWithName("max", limits: true),
        "min": operatorWithName("min", limits: true),
        "sup": operatorWithName("sup", limits: true),
        "inf": operatorWithName("inf", limits: true),
        "det": operatorWithName("det", limits: true),
        "Pr": operatorWithName("Pr", limits: true),
        "gcd": operatorWithName("gcd", limits: true),

        // Large operators
        "prod": operatorWithName("\u{220F}", limits: true),
        "coprod": operatorWithName("\u{2210}", limits: true),
        "sum": operatorWithName("\u{2211}", limits: true),
        "int": operatorWithName("\u{222B}", limits: false),
        "oint": operatorWithName("\u{222E}", limits: false),
        "bigwedge": operatorWithName("\u{22C0}", limits: true),
        "bigvee": operatorWithName("\u{22C1}", limits: true),
        "bigcap": operatorWithName("\u{22C2}", limits: true),
        "bigcup": operatorWithName("\u{22C3}", limits: true),
        "bigodot": operatorWithName("\u{2A00}", limits: true),
        "bigoplus": operatorWithName("\u{2A01}", limits: true),
        "bigotimes": operatorWithName("\u{2A02}", limits: true),
        "biguplus": operatorWithName("\u{2A04}", limits: true),
        "bigsqcup": operatorWithName("\u{2A06}", limits: true),

        // Latex command characters
        "{": MTMathAtom(type: .kMTMathAtomOpen, nucleus: "{"),
        "}": MTMathAtom(type: .kMTMathAtomClose, nucleus: "}"),
        "$": MTMathAtom(type: .kMTMathAtomOrdinary, nucleus: "$"),
        "&": MTMathAtom(type: .kMTMathAtomOrdinary, nucleus: "&"),
        "#": MTMathAtom(type: .kMTMathAtomOrdinary, nucleus: "#"),
        "%": MTMathAtom(type: .kMTMathAtomOrdinary, nucleus: "%"),
        "_": MTMathAtom(type: .kMTMathAtomOrdinary, nucleus: "_"),
        " ": MTMathAtom(type: .kMTMathAtomOrdinary, nucleus: " "),
        "backslash": MTMathAtom(type: .kMTMathAtomOrdinary, nucleus: "\\"),

        // Punctuation
        // Note: \colon is different from : which is a relation
        "colon": MTMathAtom(type: .kMTMathAtomPunctuation, nucleus: ":"),
        "cdotp": MTMathAtom(type: .kMTMathAtomPunctuation, nucleus: "\u{00B7}"),

        // Other symbols
        "degree": MTMathAtom(type: .kMTMathAtomOrdinary, nucleus: "\u{00B0}"),
        "neg": MTMathAtom(type: .kMTMathAtomOrdinary, nucleus: "\u{00AC}"),
        "angstrom": MTMathAtom(type: .kMTMathAtomOrdinary, nucleus: "\u{00C5}"),
        "|": MTMathAtom(type: .kMTMathAtomOrdinary, nucleus: "\u{2016}"),
        "vert": MTMathAtom(type: .kMTMathAtomOrdinary, nucleus: "|"),
        "ldots": MTMathAtom(type: .kMTMathAtomOrdinary, nucleus: "\u{2026}"),
        "prime": MTMathAtom(type: .kMTMathAtomOrdinary, nucleus: "\u{2032}"),
        "hbar": MTMathAtom(type: .kMTMathAtomOrdinary, nucleus: "\u{210F}"),
        "Im": MTMathAtom(type: .kMTMathAtomOrdinary, nucleus: "\u{2111}"),
        "ell": MTMathAtom(type: .kMTMathAtomOrdinary, nucleus: "\u{2113}"),
        "wp": MTMathAtom(type: .kMTMathAtomOrdinary, nucleus: "\u{2118}"),
        "Re": MTMathAtom(type: .kMTMathAtomOrdinary, nucleus: "\u{211C}"),
        "mho": MTMathAtom(type: .kMTMathAtomOrdinary, nucleus: "\u{2127}"),
        "aleph": MTMathAtom(type: .kMTMathAtomOrdinary, nucleus: "\u{2135}"),
        "forall": MTMathAtom(type: .kMTMathAtomOrdinary, nucleus: "\u{2200}"),
        "exists": MTMathAtom(type: .kMTMathAtomOrdinary, nucleus: "\u{2203}"),
        "emptyset": MTMathAtom(type: .kMTMathAtomOrdinary, nucleus: "\u{2205}"),
        "nabla": MTMathAtom(type: .kMTMathAtomOrdinary, nucleus: "\u{2207}"),
        "infty": MTMathAtom(type: .kMTMathAtomOrdinary, nucleus: "\u{221E}"),
        "angle": MTMathAtom(type: .kMTMathAtomOrdinary, nucleus: "\u{2220}"),
        "top": MTMathAtom(type: .kMTMathAtomOrdinary, nucleus: "\u{22A4}"),
        "bot": MTMathAtom(type: .kMTMathAtomOrdinary, nucleus: "\u{22A5}"),
        "vdots": MTMathAtom(type: .kMTMathAtomOrdinary, nucleus: "\u{22EE}"),
        "cdots": MTMathAtom(type: .kMTMathAtomOrdinary, nucleus: "\u{22EF}"),
        "ddots": MTMathAtom(type: .kMTMathAtomOrdinary, nucleus: "\u{22F1}"),
        "triangle": MTMathAtom(type: .kMTMathAtomOrdinary, nucleus: "\u{25B3}"),
        // These expand into 2 unicode chars
        "imath": MTMathAtom(type: .kMTMathAtomOrdinary, nucleus: "\u{1D6A4}"),
        "jmath": MTMathAtom(type: .kMTMathAtomOrdinary, nucleus: "\u{1D6A5}"),
        "partial": MTMathAtom(type: .kMTMathAtomOrdinary, nucleus: "\u{1D6F5}"),

        // Spacing
        ",": MTMathSpace(space: 3.0),
        ">": MTMathSpace(space: 4.0),
        ";": MTMathSpace(space: 5.0),
        "!": MTMathSpace(space: -3.0),
        "quad": MTMathSpace(space: 18.0), // quad = 1em = 18mu
        "qquad": MTMathSpace(space: 36.0), // qquad = 2em

        // Style
        "displaystyle": MTMathStyle(style: .kMTLineStyleDisplay),
        "textstyle": MTMathStyle(style: .kMTLineStyleText),
        "scriptstyle": MTMathStyle(style: .kMTLineStyleScript),
        "scriptscriptstyle": MTMathStyle(style: .kMTLineStyleScriptScript)
    ]

    let aliases: [String: String] = [
        "lnot": "neg",
        "land": "wedge",
        "lor": "vee",
        "ne": "neq",
        "le": "leq",
        "ge": "geq",
        "lbrace": "{",
        "rbrace": "}",
        "Vert": "|",
        "gets": "leftarrow",
        "to": "rightarrow",
        "iff": "Longleftrightarrow",
        "AA": "angstrom"
    ]
    private var textToLatexSymbolNames: [String: String] = [:]
    
    private let accents: [String: String] = [
        "grave": "\u{0300}",
        "acute": "\u{0301}",
        "hat": "\u{0302}", // In our implementation hat and widehat behave the same.
        "tilde": "\u{0303}", // In our implementation tilde and widetilde behave the same.
        "bar": "\u{0304}",
        "breve": "\u{0306}",
        "dot": "\u{0307}",
        "ddot": "\u{0308}",
        "check": "\u{030C}",
        "vec": "\u{20D7}",
        "widehat": "\u{0302}",
        "widetilde": "\u{0303}"
    ]

    // Reverse of above with preference for shortest command on overlap
    private var accentToCommands: [String: String] = [:]

    private let delimiters: [String: String] = [
        ".": "", // . means no delimiter
        "(": "(",
        ")": ")",
        "[": "[",
        "]": "]",
        "<": "\u{2329}",
        ">": "\u{232A}",
        "/": "/",
        "\\": "\\",
        "|": "|",
        "lgroup": "\u{27EE}",
        "rgroup": "\u{27EF}",
        "||": "\u{2016}",
        "Vert": "\u{2016}",
        "vert": "|",
        "uparrow": "\u{2191}",
        "downarrow": "\u{2193}",
        "updownarrow": "\u{2195}",
        "Uparrow": "21D1",
        "Downarrow": "21D3",
        "Updownarrow": "21D5",
        "backslash": "\\",
        "rangle": "\u{232A}",
        "langle": "\u{2329}",
        "rbrace": "}",
        "}": "}",
        "{": "{",
        "lbrace": "{",
        "lceil": "\u{2308}",
        "rceil": "\u{2309}",
        "lfloor": "\u{230A}",
        "rfloor": "\u{230B}"
    ]
    
    let fontStyleWithName: [String: MTFontStyle] = [
        "mathnormal": .KMTFontStyleDefault,
        "mathrm": .KMTFontStyleRoman,
        "textrm": .KMTFontStyleRoman,
        "rm": .KMTFontStyleRoman,
        "mathbf": .KMTFontStyleBold,
        "bf": .KMTFontStyleBold,
        "textbf": .KMTFontStyleBold,
        "mathcal": .KMTFontStyleCaligraphic,
        "cal": .KMTFontStyleCaligraphic,
        "mathtt": .KMTFontStyleTypewriter,
        "texttt": .KMTFontStyleTypewriter,
        "mathit": .KMTFontStyleItalic,
        "textit": .KMTFontStyleItalic,
        "mit": .KMTFontStyleItalic,
        "mathsf": .KMTFontStyleSansSerif,
        "textsf": .KMTFontStyleSansSerif,
        "mathfrak": .KMTFontStyleFraktur,
        "frak": .KMTFontStyleFraktur,
        "mathbb": .KMTFontStyleBlackboard,
        "mathbfit": .KMTFontStyleBoldItalic,
        "bm": .KMTFontStyleBoldItalic,
        "text": .KMTFontStyleRoman
    ]

    // Reverse of above with preference for shortest command on overlap
    private var delimValueToName: [String: String] = [:]

    init() {
        for (command, atom) in supportedLatexSymbols {
            if atom.nucleus.isEmpty {
                continue
            }

            let existingCommand = textToLatexSymbolNames[atom.nucleus]
            if let existingCommand = existingCommand {
                // If there are 2 commands for the same symbol, choose one deterministically.
                if command.count > existingCommand.count {
                    // Keep the shorter command
                    continue
                } else if command.count == existingCommand.count {
                    // If the length is the same, keep the alphabetically first
                    if command > existingCommand {
                        continue
                    }
                }
            }
            // In other cases replace the command.
            textToLatexSymbolNames[atom.nucleus] = command
        }
        for (command, nucleus) in accents {
            let existingCommand: String? = accentToCommands[nucleus]
            if let existingCommand = existingCommand {
                if command.count > existingCommand.count {
                    // Keep the shorter command
                    continue
                } else if command.count == existingCommand.count {
                    // If the length is the same, keep the alphabetically first
                    if command > existingCommand {
                        continue
                    }
                }
            }
            accentToCommands[nucleus] = command
        }
        for (command, delim) in delimiters {
            if let existingCommand = delimValueToName[delim] {
                if command.count > existingCommand.count {
                    // Keep the shorter command
                    continue
                } else if command.count == existingCommand.count {
                    // If the length is the same, keep the alphabetically first
                    if command > existingCommand {
                        continue
                    }
                }
            }
            delimValueToName[delim] = command
        }
    }

    static func times() -> MTMathAtom {
        return MTMathAtom(type: .kMTMathAtomBinaryOperator, nucleus: MTSymbolMultiplication)
    }

    private static func divide() -> MTMathAtom {
        return MTMathAtom(type: .kMTMathAtomBinaryOperator, nucleus: MTSymbolDivision)
    }

    private static func placeholder() -> MTMathAtom {
        return MTMathAtom(type: .kMTMathAtomPlaceholder, nucleus: MTSymbolWhiteSquare)
    }

    private func placeholderList() -> MTMathList {
        let newList = MTMathList()
        newList.addAtom(MTMathAtomFactory.placeholder())
        return newList
    }

    @discardableResult
    private func placeholderFraction() -> MTFraction {
        let frac = MTFraction()
        frac.numerator = placeholderList()
        frac.denominator = placeholderList()
        return frac
    }

    @discardableResult
    private func placeholderRadical() -> MTRadical {
        let rad = MTRadical()
        rad.degree = placeholderList()
        rad.radicand = placeholderList()
        return rad
    }

    @discardableResult
    private func placeholderSquareRoot() -> MTRadical {
        let rad = MTRadical()
        rad.radicand = placeholderList()
        return rad
    }

    static func operatorWithName(_ name: String, limits: Bool) -> MTLargeOperator {
        return MTLargeOperator(nucleus: name, limits: limits)
    }

    func mathListForCharacters(_ chars: String) -> MTMathList {
        let list = MTMathList()
        for char in chars {
            if let atom = MTMathAtom.Factory.shared.atomForCharacter(char) {
                list.addAtom(atom)
            }
        }
        return list
    }

    func latexSymbolNameForAtom(_ atom: MTMathAtom) -> String? {
        guard !atom.nucleus.isEmpty else {
            return nil
        }
        return textToLatexSymbolNames[atom.nucleus]
    }

    func addLatexSymbol(name: String, atom: MTMathAtom) {
        supportedLatexSymbols[name] = atom
        if !atom.nucleus.isEmpty {
            textToLatexSymbolNames[atom.nucleus] = name
        }
    }

    func supportedLatexSymbolNames() -> [String] {
        return Array(supportedLatexSymbols.keys).sorted()
    }

    func accentWithName(_ accentName: String) -> MTAccent? {
        guard let accentValue = accents[accentName] else {
            return nil
        }
        return MTAccent(nucleus: accentValue)
    }

    func accentName(for accent: MTAccent) -> String? {
        return accentToCommands[accent.nucleus]
    }

    func boundaryAtomForDelimiterName(_ delimName: String) -> MTMathAtom? {
        guard let delimiterValue = delimiters[delimName] else {
            return nil
        }
        return MTMathAtom(type: .kMTMathAtomBoundary, nucleus: delimiterValue)
    }

    func delimiterNameForBoundaryAtom(_ boundary: MTMathAtom) -> String? {
        guard boundary.type == .kMTMathAtomBoundary else {
            return nil
        }
        return delimValueToName[boundary.nucleus]
    }

    

    func fontNameForStyle(_ fontStyle: MTFontStyle) -> String {
        switch fontStyle {
        case .KMTFontStyleDefault: return "mathnormal"
        case .KMTFontStyleRoman: return "mathrm"
        case .KMTFontStyleBold: return "mathbf"
        case .KMTFontStyleFraktur: return "mathfrak"
        case .KMTFontStyleCaligraphic: return "mathcal"
        case .KMTFontStyleItalic: return "mathit"
        case .KMTFontStyleSansSerif: return "mathsf"
        case .KMTFontStyleBlackboard: return "mathbb"
        case .KMTFontStyleTypewriter: return "mathtt"
        case .KMTFontStyleBoldItalic: return "bm"
        }
    }

    private func fractionWithNumerator(_ num: MTMathList, denom: MTMathList) -> MTFraction {
        let frac = MTFraction()
        frac.numerator = num
        frac.denominator = denom
        return frac
    }

    func fractionWithNumerator(_ numStr: String, denominatorStr: String) -> MTFraction {
        let num = mathListForCharacters(numStr)
        let denom = mathListForCharacters(denominatorStr)
        return fractionWithNumerator(num, denom: denom)
    }

    func tableWithEnvironment(_ env: String?, cells: inout [[MTMathList]], error: MTParseError) -> MTMathAtom? {
        let table = MTMathTable(env: env)
        table.cells = cells
        let matrixEnvs: [String: [String]] = [
            "matrix": [""],
            "pmatrix": ["(", ")"],
            "bmatrix": ["[", "]"],
            "Bmatrix": ["{", "}"],
            "vmatrix": ["vert", "vert"],
            "Vmatrix": ["Vert", "Vert"]
        ]
        let containsEnv = matrixEnvs.contains { (key: String, value: [String]) in
            key == env
        }

        if (containsEnv) {
            table.environment = "matrix"
            table.interRowAdditionalSpacing = 0.0
            table.interColumnSpacing = 18.0
            let style = MTMathStyle(style: .kMTLineStyleText)
            for row in table.cells {
                for cell in row {
                    cell.insertAtom(style, at: 0)
                }
            }
            let delims = matrixEnvs[env ?? ""]
        
            if delims?.count == 2 {
                let inner = MTInner()
                inner.leftBoundary = boundaryAtomForDelimiterName(delims![0])
                inner.rightBoundary = boundaryAtomForDelimiterName(delims![1])
                inner.innerList = MTMathList(table)
                return inner
            } else {
                return table
            }
        } else if env == nil {
            table.interRowAdditionalSpacing = 1.0
            table.interColumnSpacing = 0.0
            for i in 0..<table.numColumns() {
                table.setAlignment(.KMTColumnAlignmentLeft, column: i)
            }
            return table
        } else if env == "eqalign" || env == "split" || env == "aligned" {
            if table.numColumns() != 2 {
                error.copyFrom(src: MTParseError(errorCode: .InvalidNumColumns, errorDesc: "\(env!) environment can only have 2 columns"))
                return nil
            }
            let spacer = MTMathAtom(type: .kMTMathAtomOrdinary, nucleus: "")
            for row in table.cells where row.count > 1 {
                row[1].insertAtom(spacer, at: 0)
            }
            table.interRowAdditionalSpacing = 1.0
            table.interColumnSpacing = 0.0
            table.setAlignment(.KMTColumnAlignmentRight, column: 0)
            table.setAlignment(.KMTColumnAlignmentLeft, column: 1)
            return table
        } else if env == "displaylines" || env == "gather" {
            if table.numColumns() != 1 {
                error.copyFrom(src: MTParseError(errorCode: .InvalidNumColumns, errorDesc: "\(env!) environment can only have 1 column"))
                return nil
            }
            table.interRowAdditionalSpacing = 1.0
            table.interColumnSpacing = 0.0
            table.setAlignment(.KMTColumnAlignmentCenter, column: 0)
            return table
        } else if env == "eqnarray" {
            if table.numColumns() != 3 {
                error.copyFrom(src: MTParseError(errorCode: .InvalidNumColumns, errorDesc: "eqnarray environment can only have 3 columns"))
                return nil
            }
            table.interRowAdditionalSpacing = 1.0
            table.interColumnSpacing = 18.0
            table.setAlignment(.KMTColumnAlignmentRight, column: 0)
            table.setAlignment(.KMTColumnAlignmentCenter, column: 1)
            table.setAlignment(.KMTColumnAlignmentLeft
                               , column: 2)
            return table
        } else if env == "cases" {
            let numCols = table.numColumns()
            if numCols != 1 && numCols != 2 {
                error.errorCode = .InvalidNumColumns
                error.copyFrom(src: MTParseError(errorCode: .InvalidNumColumns, errorDesc: "cases environment can only have 1 or 2 columns"))
                return nil
            }
            if numCols == 1 {
                for var row in table.cells {
                    if row.count == 1 {
                        row.append(MTMathList())
                    }
                }
            }
            table.interRowAdditionalSpacing = 0.0
            table.interColumnSpacing = 18.0
            table.setAlignment(.KMTColumnAlignmentLeft, column: 0)
            table.setAlignment(.KMTColumnAlignmentLeft, column: 1)
            let style = MTMathStyle(style: .kMTLineStyleText)
            for row in table.cells {
                for cell in row {
                    cell.insertAtom(style, at: 0)
                }
            }
            let inner = MTInner()
            inner.leftBoundary = boundaryAtomForDelimiterName("{")
            inner.rightBoundary = boundaryAtomForDelimiterName(".")
            if let space = atomForLatexSymbolName(symbolName: ",") {
                inner.innerList = MTMathList(table)
            }
            return inner
        }
        error.copyFrom(src: MTParseError(errorCode: .InvalidEnv, errorDesc: "Unknown environment: \(env ?? "nil")"))
        return nil
    }

    func atomForLatexSymbolName(symbolName: String) -> MTMathAtom? {
        var name = symbolName

        // First check if this is an alias
        let canonicalName = aliases[symbolName]

        if let canonicalName = canonicalName {
            // Switch to the canonical name
            name = canonicalName
        }

        let atom = supportedLatexSymbols[name]
        if let atom = atom {
            // Return a copy of the atom since atoms are mutable.
            return atom.copyDeep()
        }
        return nil
    }
}
