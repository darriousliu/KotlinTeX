import Foundation

struct MTEnvProperties {
    var envName: String?
    var ended: Bool = false
    var numRows: Int64 = 0
}

class MTMathListBuilder {
    private var chars: String
    private var currentCharIndex: Int = 0
    private var charLength: Int
    private var currentInnerAtom: MTInner? = nil
    private var currentEnv: MTEnvProperties? = nil
    private var currentFontStyle: MTFontStyle = .KMTFontStyleDefault
    private var spacesAllowed: Bool = false
    private var parseError: MTParseError? = nil

    private var singleCharCommands: [Character] =
        ["{", "}", "$", "#", "%", "_", "|", " ", ",", ">", ";", "!", "\\"]

    private let fractionCommands: [String: [String]] = [
        "over": [""],
        "atop": [""],
        "choose": ["(", ")"],
        "brack": ["[", "]"],
        "brace": ["{", "}"]
    ]

    init(str: String) {
        self.chars = str
        self.charLength = str.count
    }

    private func hasCharacters() -> Bool {
        return currentCharIndex < charLength
    }

    // gets the next character and moves the pointer ahead
    private func getNextCharacter() -> Character {
        guard currentCharIndex < charLength else {
            fatalError("Retrieving character at index \(currentCharIndex) beyond length \(charLength)")
        }
        let character: Character = chars.character(at: currentCharIndex)
        currentCharIndex += 1
        return character
    }

    private func unlockCharacter() {
        guard currentCharIndex > 0 else {
            fatalError("Unlocking when at the first character.")
        }
        currentCharIndex -= 1
    }

    func build() -> MTMathList? {
        let list: MTMathList? = buildInternal(oneCharOnly: false)
        if hasCharacters() {
            // something went wrong most likely braces mismatched
            setError(.MismatchBraces, message: "Mismatched braces: \(chars)")
            return nil
        }
        return list
    }

    private func buildInternal(oneCharOnly: Bool) -> MTMathList? {
        return buildInternal(oneCharOnly: oneCharOnly, stopChar: "\0")
    }

    private func buildInternal(oneCharOnly: Bool, stopChar: Character) -> MTMathList? {
        let list = MTMathList()
        if oneCharOnly && stopChar != "\0" {
            fatalError("Cannot set both oneCharOnly and stopChar.")
        }

        var prevAtom: MTMathAtom? = nil
        outerLoop: while hasCharacters() {
            if errorActive() {
                // If there is an error thus far then bail out.
                return nil
            }
            var atom: MTMathAtom?
            let ch = getNextCharacter()
            if oneCharOnly {
                if ch == "^" || ch == "}" || ch == "_" || ch == "&" {
                    // this is not the character we are looking for.
                    // They are meant for the caller to look at.
                    unlockCharacter()
                    return list
                }
            }
            // If there is a stop character, keep scanning till we find it
            if stopChar != "\0" && ch == stopChar {
                return list
            }

            switch ch {
            case "^":
                if oneCharOnly {
                    fatalError("This should have been handled before")
                }
                if prevAtom == nil || prevAtom?.superScript != nil || prevAtom?.scriptsAllowed() == false {
                    // If there is no previous atom, or if it already has a superscript
                    // or if scripts are not allowed for it, then add an empty node.
                    prevAtom = MTMathAtom(type: .kMTMathAtomOrdinary, nucleus: "")
                    list.addAtom(prevAtom!)
                }
                // this is a superscript for the previous atom
                // note: if the next char is the stopChar it will be consumed by the ^ and so it doesn't count as stop
                prevAtom?.superScript = buildInternal(oneCharOnly: true)
                continue outerLoop
            case "_":
                if oneCharOnly {
                    fatalError("This should have been handled before")
                }
                if prevAtom == nil || prevAtom?.subScript != nil || prevAtom?.scriptsAllowed() == false {
                    // If there is no previous atom, or if it already has a subscript
                    // or if scripts are not allowed for it, then add an empty node.
                    prevAtom = MTMathAtom(type: .kMTMathAtomOrdinary, nucleus: "")
                    list.addAtom(prevAtom!)
                }
                // this is a subscript for the previous atom
                // note: if the next char is the stopChar it will be consumed by the _ and so it doesn't count as stop
                prevAtom?.subScript = buildInternal(oneCharOnly: true)
                continue outerLoop
            case "{":
                // this puts us in a recursive routine, and sets oneCharOnly to false and no stop character
                let sublist = buildInternal(oneCharOnly: false, stopChar: "}")
                if let sublist = sublist {
                    prevAtom = sublist.atoms.last
                    list.append(list: sublist)
                }
                if oneCharOnly {
                    return list
                }
                continue outerLoop
            case "}":
                if oneCharOnly {
                    fatalError("This should have been handled before")
                }
                if stopChar != "\0" {
                    fatalError("This should have been handled before")
                }
                // We encountered a closing brace when there is no stop set, that means there was no
                // corresponding opening brace.
                setError(.MismatchBraces, message: "Mismatched braces.")
                return nil
            case "\\":
                // \ means a command
                let command = readCommand()
                if let done = stopCommand(command, list, stopChar: stopChar) {
                    return done
                } else if errorActive() {
                    return nil
                }
                if applyModifier(command, to: prevAtom) {
                    continue outerLoop
                }
                if let fontStyle = MTMathAtom.Factory.shared.fontStyleWithName[command] {
                    let oldSpacesAllowed = spacesAllowed
                    // Text has special consideration where it allows spaces without escaping.
                    spacesAllowed = (command == "text")
                    let oldFontStyle = currentFontStyle
                    currentFontStyle = fontStyle
                    let sublist = buildInternal(oneCharOnly: true)
                    // Restore the font style.
                    currentFontStyle = oldFontStyle
                    spacesAllowed = oldSpacesAllowed
                    if let sublist = sublist {
                        prevAtom = sublist.atoms.last
                        list.append(list: sublist)
                    }
                    if oneCharOnly {
                        return list
                    }
                    continue outerLoop
                }
                atom = atomForCommand(command)
                if atom == nil {
                    // this was an unknown command,
                    // we flag an error and return
                    // (note setError will not set the error if there is already one, so we flag internal error
                    // in the odd case that an _error is not set.
                    setError(.InternalError, message: "Internal error")
                    return nil
                }
            case "&":
                // used for column separation in tables
                if oneCharOnly {
                    fatalError("This should have been handled before")
                }
                return {
                    if currentEnv != nil {
                        return list
                    } else {
                        let table = buildTable(env: nil, firstList: list, isRow: false)
                        if let table = table {
                            return MTMathList(table)
                        } else {
                            return nil
                        }
                    }
                }()
            default:
                if spacesAllowed && ch == " " {
                    // If spaces are allowed then spaces do not need escaping with a \ before being used.
                    atom = MTMathAtom.Factory.shared.atomForLatexSymbolName(symbolName: " ")
                } else {
                    atom = MTMathAtom.Factory.shared.atomForCharacter(ch)
                    if atom == nil {
                        // Not a recognized character
                        continue outerLoop
                    }
                }
            }
            // This would be a coding error
            if atom == nil {
                fatalError("Atom shouldn't be nil")
            }
            atom?.fontStyle = currentFontStyle
            list.addAtom(atom!)
            prevAtom = atom

            if oneCharOnly {
                // we consumed our oneChar
                return list
            }
        }

        if stopChar != "\0" {
            if stopChar == "}" {
                // We did not find a corresponding closing brace.
                setError(.MismatchBraces, message: "Missing closing brace")
            } else {
                // we never found our stop character
                setError(.CharacterNotFound, message: "Expected character not found: \(stopChar)")
            }
        }
        return list
    }

    private func readString() -> String {
        // a string of all upper and lower case characters.
        var mutable = ""
        while hasCharacters() {
            let ch = getNextCharacter()
            if "a"..."z" ~= ch || "A"..."Z" ~= ch {
                mutable.append(ch)
            } else {
                // we went too far
                unlockCharacter()
                break
            }
        }
        return mutable
    }

    private func readColor() -> String? {
        guard try! expectCharacter("{") else {
            // We didn't find an opening brace, so no env found.
            setError(.CharacterNotFound, message: "Missing {")
            return nil
        }

        // Ignore spaces and nonascii characters.
        skipSpaces()

        // a string of all upper and lower case characters.
        var mutable = ""
        while hasCharacters() {
            let ch = getNextCharacter()
            if ch == "#" || ("A"..."F" ~= ch) || ("a"..."f" ~= ch) || ("0"..."9" ~= ch) {
                mutable.append(ch)
            } else {
                // we went too far
                unlockCharacter()
                break
            }
        }

        guard try! expectCharacter("}") else {
            // We didn't find an closing brace, so invalid format.
            setError(.CharacterNotFound, message: "Missing }")
            return nil
        }
        return mutable
    }

    private func nonSpaceChar(_ ch: Character) -> Bool {
        guard let scalar = ch.unicodeScalars.first else {
            return true
        }
        return (scalar.value < 0x21 || scalar.value > 0x7E)
    }

    private func skipSpaces() {
        while hasCharacters() {
            let ch = getNextCharacter()
            if nonSpaceChar(ch) {
                // skip non ascii characters and spaces
                continue
            } else {
                unlockCharacter()
                return
            }
        }
    }

    private func expectCharacter(_ ch: Character) throws -> Bool {
        if nonSpaceChar(ch) {
            throw MathDisplayException("Expected non space character \(ch)")
        }
        skipSpaces()

        if hasCharacters() {
            let c: Character = getNextCharacter()
            if nonSpaceChar(c) {
                throw MathDisplayException("Expected non space character \(c)")
            }
            if c == ch {
                return true
            } else {
                unlockCharacter()
                return false
            }
        }
        return false
    }

    private func readCommand() -> String {
        if hasCharacters() {
            // Check if we have a single character command.
            let ch: Character = getNextCharacter()
            // Single char commands
            if singleCharCommands.contains(ch) {
                return String(ch)
            } else {
                // not a known single character command
                unlockCharacter()
            }
        }
        // otherwise a command is a string of all upper and lower case characters.
        return readString()
    }

    private func readDelimiter() throws -> String? {
        // Ignore spaces and nonascii.
        skipSpaces()
        while hasCharacters() {
            let ch: Character = getNextCharacter()
            if nonSpaceChar(ch) {
                throw MathDisplayException("Expected non space character \(ch)")
            }
            if ch == "\\" {
                // \ means a command
                let command: String = readCommand()
                if command == "|" {
                    // | is a command and also a regular delimiter. We use the || command to
                    // distinguish between the 2 cases for the caller.
                    return "||"
                }
                return command
            } else {
                return String(ch)
            }
        }
        // We ran out of characters for delimiter
        return nil
    }

    private func readEnvironment() -> String? {
        if try! !expectCharacter("{") {
            // We didn't find an opening brace, so no env found.
            self.setError(.CharacterNotFound, message: "Missing {")
            return nil
        }

        // Ignore spaces and nonascii.
        skipSpaces()
        let env: String? = readString()

        if try! !expectCharacter("}") {
            // We didn't find a closing brace, so invalid format.
            self.setError(.CharacterNotFound, message: "Missing }")
            return nil
        }
        return env
    }

    private func getBoundaryAtom(_ delimiterType: String) -> MTMathAtom? {
        guard let delimiter = try! self.readDelimiter() else {
            self.setError(.MissingDelimiter, message: "Missing delimiter for \(delimiterType)")
            return nil
        }
        guard let boundary = MTMathAtom.Factory.shared.boundaryAtomForDelimiterName(delimiter) else {
            self.setError(.InvalidDelimiter, message: "Invalid delimiter for \(delimiterType): \(delimiter)")
            return nil
        }
        return boundary
    }

    private func atomForCommand(_ command: String) -> MTMathAtom? {
        if let atom = MTMathAtom.Factory.shared.atomForLatexSymbolName(symbolName: command) {
            return atom
        }
        if let accent = MTMathAtom.Factory.shared.accentWithName(command) {
            // The command is an accent
            accent.innerList = self.buildInternal(oneCharOnly: true)
            return accent
        }

        switch command {
        case "frac":
            // A fraction command has 2 arguments
            let frac = MTFraction()
            frac.numerator = self.buildInternal(oneCharOnly: true)
            frac.denominator = self.buildInternal(oneCharOnly: true)
            return frac

        case "binom":
            // A binom command has 2 arguments
            let frac = MTFraction(rule: false)
            frac.numerator = self.buildInternal(oneCharOnly: true)
            frac.denominator = self.buildInternal(oneCharOnly: true)
            frac.leftDelimiter = "("
            frac.rightDelimiter = ")"
            return frac

        case "sqrt":
            // A sqrt command with one argument
            let rad = MTRadical()
            let ch = self.getNextCharacter()
            if ch == "[" {
                // special handling for sqrt[degree]{radicand}
                rad.degree = self.buildInternal(oneCharOnly: false, stopChar: "]")
                rad.radicand = self.buildInternal(oneCharOnly: true)
            } else {
                self.unlockCharacter()
                rad.radicand = self.buildInternal(oneCharOnly: true)
            }
            return rad

        case "left":
            // Save the current inner while a new one gets built.
            let oldInner: MTInner? = currentInnerAtom
            currentInnerAtom = MTInner()
            currentInnerAtom?.leftBoundary = self.getBoundaryAtom("left")
            if currentInnerAtom?.leftBoundary == nil {
                return nil
            }
            currentInnerAtom?.innerList = self.buildInternal(oneCharOnly: false)
            if currentInnerAtom?.rightBoundary == nil {
                // A right node would have set the right boundary so we must be missing the right node.
                self.setError(.MissingRight, message: "Missing \\right")
                return nil
            }
            // reinstate the old inner atom.
            let newInner = currentInnerAtom
            currentInnerAtom = oldInner
            return newInner

        case "overline":
            // The overline command has 1 argument
            let over = MTOverLine()
            over.innerList = self.buildInternal(oneCharOnly: true)
            return over

        case "underline":
            // The underline command has 1 argument
            let under = MTUnderLine()
            under.innerList = self.buildInternal(oneCharOnly: true)
            return under

        case "begin":
            guard let env = self.readEnvironment() else {
                return nil
            }
            return buildTable(env: env, firstList: nil, isRow: false)

        case "color":
            // A color command has 2 arguments
            let mathColor = MTMathColor()
            mathColor.colorString = self.readColor()
            mathColor.innerList = self.buildInternal(oneCharOnly: true)
            return mathColor

        case "textcolor":
            // A textcolor command has 2 arguments
            let mathColor = MTMathTextColor()
            mathColor.colorString = self.readColor()
            mathColor.innerList = self.buildInternal(oneCharOnly: true)
            return mathColor

        default:
            self.setError(.InvalidCommand, message: "Invalid command \(command)")
            return nil
        }
    }

    private func stopCommand(_ command: String, _ list: MTMathList, stopChar: Character) -> MTMathList? {
        switch command {
        case "right":
            if currentInnerAtom == nil {
                self.setError(.MissingLeft, message: "Missing \\left")
                return nil
            }
            currentInnerAtom?.rightBoundary = self.getBoundaryAtom("right")
            if currentInnerAtom?.rightBoundary == nil {
                return nil
            }
            // return the list read so far.
            return list

        case "over", "atop", "choose", "brack", "brace":
            let frac = (command == "over") ? MTFraction() : MTFraction(rule: false)
            if let delimiters = fractionCommands[command], delimiters.count == 2 {
                frac.leftDelimiter = delimiters[0]
                frac.rightDelimiter = delimiters[1]
            }
            frac.numerator = list
            frac.denominator = self.buildInternal(oneCharOnly: false, stopChar: stopChar)
            if errorActive() {
                return nil
            }
            let fracList = MTMathList()
            fracList.addAtom(frac)
            return fracList

        case "\\", "cr":
            if var ce = self.currentEnv {
                // Stop the current list and increment the row count
                ce.numRows += 1
                self.currentEnv = ce
                return list
            } else {
                // Create a new table with the current list and a default env
                if let table = self.buildTable(env: nil, firstList: list, isRow: true) {
                    return MTMathList(table)
                }
                return nil
            }

        case "end":
            if currentEnv == nil {
                self.setError(.MissingBegin, message: "Missing \\begin")
                return nil
            } else {
                guard let env = self.readEnvironment() else {
                    return nil
                }

                if env != currentEnv?.envName {
                    self.setError(.InvalidEnv, message: "Begin environment name \(currentEnv?.envName ?? "") does not match end name: \(env)")
                    return nil
                }
                // Finish the current environment.
                currentEnv?.ended = true
                return list
            }

        default:
            return nil
        }
    }

// Applies the modifier to the atom. Returns true if modifier applied.
    private func applyModifier(_ modifier: String, to atom: MTMathAtom?) -> Bool {
        if modifier == "limits" {
            if atom == nil || atom?.type != .kMTMathAtomLargeOperator {
                self.setError(.InvalidLimits, message: "limits can only be applied to an operator.")
            } else if let op = atom as? MTLargeOperator {
                op.hasLimits = true
            }
            return true
        } else if modifier == "nolimits" {
            if atom == nil || atom?.type != .kMTMathAtomLargeOperator {
                self.setError(.InvalidLimits, message: "nolimits can only be applied to an operator.")
                return true
            } else if let op = atom as? MTLargeOperator {
                op.hasLimits = false
            }
            return true
        }
        return false
    }

    func copyError(to dst: MTParseError) {
        dst.copyFrom(src: self.parseError)
    }

    func errorActive() -> Bool {
        return self.parseError != nil
    }

    private func setError(_ errorCode: MTParseErrors, message: String) {
        // Only record the first error.
        if self.parseError == nil {
            self.parseError = MTParseError(errorCode: errorCode, errorDesc: message)
        }
    }

    private func buildTable(env: String?, firstList: MTMathList?, isRow: Bool) -> MTMathAtom? {
        // Save the current env till a new one gets built.
        let oldEnv = currentEnv
        var newEnv = MTEnvProperties(envName: env)
        self.currentEnv = newEnv
        var currentRow = 0
        var currentCol = 0
        var rows: [[MTMathList]] = []
        rows.insert([], at: currentRow)
        if let firstList = firstList {
            rows[currentRow].insert(firstList, at: currentCol)
            if isRow {
                // ++ causes kotlin compile crash
                newEnv.numRows += 1
                currentRow += 1
                rows.insert([], at: currentRow)
            } else {
                currentCol += 1
            }
        }
        while !newEnv.ended && self.hasCharacters() {
            let list = self.buildInternal(oneCharOnly: false)
            if list == nil {
                // If there is an error building the list, bail out early.
                return nil
            }
            rows[currentRow].insert(list!, at: currentCol)
            currentCol += 1
            if newEnv.numRows > currentRow {
                currentRow = Int(newEnv.numRows)
                rows.insert([], at: currentRow)
                currentCol = 0
            }
        }
        if !newEnv.ended && newEnv.envName != nil {
            self.setError(MTParseErrors.MissingEnd, message: "Missing \\end")
            return nil
        }
        let error = MTParseError()
        let table = MTMathAtom.Factory.shared.tableWithEnvironment(newEnv.envName, cells: &rows, error: error)

        if table == nil {
            parseError = error
            return nil
        }
        // reinstate the old env.
        self.currentEnv = oldEnv
        return table
    }

    class Factory {
        class func buildFromString(_ str: String) -> MTMathList? {
            let builder = MTMathListBuilder(str: str)
            return builder.build()
        }

        class func buildFromString(_ str: String, error: MTParseError) -> MTMathList? {
            let builder = MTMathListBuilder(str: str)
            let output = builder.build()
            if builder.errorActive() {
                builder.copyError(to: error)
                return nil
            }
            return output
        }

        private static let spaceToCommands: [Float: String] = [
            3.0: ",",
            4.0: ">",
            5.0: ";",
            -3.0: "!",
            18.0: "quad",
            36.0: "qquad"
        ]

        private static let styleToCommands: [MTLineStyle: String] = [
            .kMTLineStyleDisplay: "displaystyle",
            .kMTLineStyleText: "textstyle",
            .kMTLineStyleScript: "scriptstyle",
            .kMTLineStyleScriptScript: "scriptscriptstyle"
        ]

        private static func delimiterToLatexString(_ delimiter: MTMathAtom) -> String {
            let command = MTMathAtom.Factory.shared.delimiterNameForBoundaryAtom(delimiter)
            if let command = command {
                let singleChars: [String] = ["(", ")", "[", "]", "<", ">", "|", ".", "/"]
                if singleChars.contains(command) {
                    return command
                } else if command == "||" {
                    return "\\|"
                } else {
                    return "\\\(command)"
                }
            }
            return ""
        }

        class func toLatexString(_ ml: MTMathList) -> String {
            var str = ""
            var currentFontStyle: MTFontStyle = .KMTFontStyleDefault
            for atom in ml.atoms {
                if currentFontStyle != atom.fontStyle {
                    if currentFontStyle != .KMTFontStyleDefault {
                        // close the previous font style.
                        str += "}"
                    }
                    if atom.fontStyle != .KMTFontStyleDefault {
                        // open new font style
                        let fontStyleName = MTMathAtom.Factory.shared.fontNameForStyle(atom.fontStyle)
                        str += "\\\(fontStyleName){"
                    }
                    currentFontStyle = atom.fontStyle
                }

                if atom.type == .kMTMathAtomFraction {
                    let frac = atom as! MTFraction

                    let numerator = frac.numerator
                    var numStr = ""
                    if let numerator = numerator {
                        numStr = toLatexString(numerator)
                    }
                    let denominator = frac.denominator
                    var denStr = ""
                    if let denominator = denominator {
                        denStr = toLatexString(denominator)
                    }

                    if frac.hasRule {
                        str += "\\frac{\(numStr)}{\(denStr)}"
                    } else {
                        var command: String
                        if frac.leftDelimiter == nil && frac.rightDelimiter == nil {
                            command = "atop"
                        } else if frac.leftDelimiter == "(" && frac.rightDelimiter == ")" {
                            command = "choose"
                        } else if frac.leftDelimiter == "{" && frac.rightDelimiter == "}" {
                            command = "brace"
                        } else if frac.leftDelimiter == "[" && frac.rightDelimiter == "]" {
                            command = "brack"
                        } else { // atopwithdelims is not handled in builder at this time so this case should not be executed unless built programmatically
                            let leftD = frac.leftDelimiter ?? ""
                            let rightD = frac.rightDelimiter ?? ""
                            command = "atopwithdelims\(leftD)\(rightD)"
                        }
                        str += "{\(numStr) \(command) \(denStr)}"
                    }
                } else if atom.type == .kMTMathAtomRadical {
                    let rad = atom as! MTRadical
                    str += rad.toLatexString()
                } else if atom.type == .kMTMathAtomInner {
                    let inner = atom as! MTInner
                    let leftBoundary = inner.leftBoundary
                    let rightBoundary = inner.rightBoundary

                    if leftBoundary != nil || rightBoundary != nil {
                        if let leftBoundary = leftBoundary {
                            let ds = self.delimiterToLatexString(leftBoundary)
                            str += "\\left\(ds) "
                        } else {
                            str += "\\left. "
                        }
                        if let il = inner.innerList {
                            str += self.toLatexString(il)
                        }
                        if let rightBoundary = rightBoundary {
                            let ds = self.delimiterToLatexString(rightBoundary)
                            str += "\\right\(ds) "
                        } else {
                            str += "\\right. "
                        }
                    } else {
                        str += "{"
                        if let il = inner.innerList {
                            str += self.toLatexString(il)
                        }
                        str += "}"
                    }
                } // The rest of the conversion follows a similar structured mapping process.
            }
            if currentFontStyle != .KMTFontStyleDefault {
                str += "}"
            }
            return str
        }
    }
}
