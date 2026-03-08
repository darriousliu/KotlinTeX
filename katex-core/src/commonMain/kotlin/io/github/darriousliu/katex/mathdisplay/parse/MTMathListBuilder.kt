//
//  MTMathListBuilder.m
//  iosMath
//
//  Created by Kostub Deshmukh on 8/28/13.
//  Copyright (C) 2013 MathChat
//   
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//
package io.github.darriousliu.katex.mathdisplay.parse

import io.github.darriousliu.katex.utils.toFixed


// NSString *const MTParseError = "ParseError"

private data class MTEnvProperties(
    var envName: String?,
    var ended: Boolean = false,
    var numRows: Long = 0
)


class MTMathListBuilder(str: String) {
    private var chars: String = str
    private var currentCharIndex: Int = 0
    private var charLength: Int = str.length
    private var currentInnerAtom: MTInner? = null
    private var currentEnv: MTEnvProperties? = null
    private var currentFontStyle: MTFontStyle = MTFontStyle.KMTFontStyleDefault
    private var spacesAllowed: Boolean = false
    private var parseError: MTParseError? = null

    private var singleCharCommands: Array<Char> =
        arrayOf('{', '}', '$', '#', '%', '_', '|', ' ', ',', '>', ';', '!', '\\')

    private val fractionCommands: HashMap<String, Array<String>> =
        hashMapOf(
            "over" to arrayOf(""),
            "atop" to arrayOf(""),
            "choose" to arrayOf("(", ")"),
            "brack" to arrayOf("[", "]"),
            "brace" to arrayOf("{", "}")
        )

    private fun hasCharacters(): Boolean {
        return currentCharIndex < charLength
    }

    // gets the next character and moves the pointer ahead
    private fun getNextCharacter(): Char {
        if (currentCharIndex >= charLength) {
            throw MathDisplayException("Retrieving character at index $currentCharIndex beyond length $charLength")
        }
        return chars[currentCharIndex++]
    }

    private fun unlockCharacter() {
        if (currentCharIndex <= 0) {
            throw MathDisplayException("Unlooking when at the first character.")
        }
        currentCharIndex--
    }

    fun build(): MTMathList? {
        val list: MTMathList? = buildInternal(false)
        if (hasCharacters()) {
            // something went wrong most likely braces mismatched
            this.setError(MTParseErrors.MismatchBraces, "Mismatched braces: $chars")
            return null
        }
        return list
    }

    private fun buildInternal(oneCharOnly: Boolean): MTMathList? {
        return buildInternal(oneCharOnly, 0.toChar())
    }

    private fun buildInternal(oneCharOnly: Boolean, stopChar: Char): MTMathList? {
        val list = MTMathList()
        if (oneCharOnly && (stopChar.code > 0)) {
            throw MathDisplayException("Cannot set both oneCharOnly and stopChar.")
        }

        var prevAtom: MTMathAtom? = null
        outerLoop@ while (hasCharacters()) {
            if (this.errorActive()) {
                // If there is an error thus far then bail out.
                return null
            }
            var atom: MTMathAtom?
            val ch: Char = getNextCharacter()
            if (oneCharOnly) {
                if (ch == '^' || ch == '}' || ch == '_' || ch == '&') {
                    // this is not the character we are looking for.
                    // They are meant for the caller to look at.
                    unlockCharacter()
                    return list
                }
            }
            // If there is a stop character, keep scanning till we find it
            if (stopChar.code > 0 && ch == stopChar) {
                return list
            }

            when (ch) {
                '^' -> {
                    if (oneCharOnly) throw MathDisplayException("This should have been handled before")

                    if (prevAtom == null || prevAtom.superScript != null || !prevAtom.scriptsAllowed()) {
                        // If there is no previous atom, or if it already has a superscript
                        // or if scripts are not allowed for it, then add an empty node.
                        prevAtom = MTMathAtom(MTMathAtomType.KMTMathAtomOrdinary, "")
                        list.addAtom(prevAtom)
                    }
                    // this is a superscript for the previous atom
                    // note: if the next char is the stopChar it will be consumed by the ^ and so it doesn't count as stop
                    prevAtom.superScript = buildInternal(true)
                    continue@outerLoop
                }

                '_' -> {
                    if (oneCharOnly) throw MathDisplayException("This should have been handled before")

                    if (prevAtom == null || prevAtom.subScript != null || !prevAtom.scriptsAllowed()) {
                        // If there is no previous atom, or if it already has a subscript
                        // or if scripts are not allowed for it, then add an empty node.
                        prevAtom = MTMathAtom(MTMathAtomType.KMTMathAtomOrdinary, "")
                        list.addAtom(prevAtom)
                    }
                    // this is a subscript for the previous atom
                    // note: if the next char is the stopChar it will be consumed by the _ and so it doesn't count as stop
                    prevAtom.subScript = buildInternal(true)
                    continue@outerLoop
                }

                '{' -> {
                    // this puts us in a recursive routine, and sets oneCharOnly to false and no stop character
                    val sublist: MTMathList? = buildInternal(false, '}')
                    if (sublist != null) {
                        prevAtom = sublist.atoms.lastOrNull()
                        list.append(sublist)
                    }
                    if (oneCharOnly) {
                        return list
                    }
                    continue@outerLoop
                }

                '}' -> {
                    if (oneCharOnly) throw MathDisplayException("This should have been handled before")
                    if (stopChar.code != 0) throw MathDisplayException("This should have been handled before")
                    // We encountered a closing brace when there is no stop set, that means there was no
                    // corresponding opening brace.
                    this.setError(MTParseErrors.MismatchBraces, "Mismatched braces.")
                    return null
                }

                '\\' -> {
                    // \ means a command
                    val command: String = readCommand()
                    val done: MTMathList? = stopCommand(command, list, stopChar)
                    if (done != null) {
                        return done
                    } else if (this.errorActive()) {
                        return null
                    }
                    if (applyModifier(command, prevAtom)) {
                        continue@outerLoop
                    }
                    val fontStyle: MTFontStyle? = MTMathAtom.fontStyles[command]
                    if (fontStyle != null) {
                        val oldSpacesAllowed: Boolean = spacesAllowed
                        // Text has special consideration where it allows spaces without escaping.
                        spacesAllowed = command == "text"
                        val oldFontStyle: MTFontStyle = currentFontStyle
                        currentFontStyle = fontStyle
                        val sublist: MTMathList? = buildInternal(true)
                        // Restore the font style.
                        currentFontStyle = oldFontStyle
                        spacesAllowed = oldSpacesAllowed
                        if (sublist != null) {
                            prevAtom = sublist.atoms.lastOrNull()
                            list.append(sublist)
                        }
                        if (oneCharOnly) {
                            return list
                        }
                        continue@outerLoop
                    }
                    atom = atomForCommand(command)
                    if (atom == null) {
                        // this was an unknown command,
                        // we flag an error and return
                        // (note setError will not set the error if there is already one, so we flag internal error
                        // in the odd case that an _error is not set.
                        this.setError(MTParseErrors.InternalError, "Internal error")
                        return null
                    }
                }

                '&' -> {
                    // used for column separation in tables
                    if (oneCharOnly) throw MathDisplayException("This should have been handled before")
                    return if (currentEnv != null) {
                        list
                    } else {
                        // c list and a default env
                        val table: MTMathAtom? = buildTable(null, list, false)
                        if (table != null) {
                            MTMathList(table)
                        } else {
                            null
                        }
                    }
                }

                '\'' -> {
                    // ' is a shorthand for \prime in superscript position, e.g. f' = f^{\prime}
                    val primeAtom = MTMathAtom.atomForLatexSymbol("prime")
                        ?: throw MathDisplayException("prime atom not found")
                    primeAtom.fontStyle = currentFontStyle
                    if (oneCharOnly) {
                        // Inside a single-char context (e.g. x^'), add prime as a regular atom
                        list.addAtom(primeAtom)
                        return list
                    }
                    if (prevAtom == null || !prevAtom.scriptsAllowed()) {
                        // No previous atom or scripts not allowed; add an empty node
                        prevAtom = MTMathAtom(MTMathAtomType.KMTMathAtomOrdinary, "")
                        list.addAtom(prevAtom)
                    }
                    // Append \prime to the superscript list (supports f'' = f^{\prime\prime})
                    val superScript = prevAtom.superScript ?: MTMathList()
                    superScript.addAtom(primeAtom)
                    prevAtom.superScript = superScript
                    continue@outerLoop
                }

                else -> {
                    if (spacesAllowed && ch == ' ') {
                        // If spaces are allowed then spaces do not need escaping with a \ before being used.
                        atom = MTMathAtom.atomForLatexSymbol(" ")
                    } else {
                        atom = MTMathAtom.atomForCharacter(ch)
                        if (atom == null) {
                            // Not a recognized character
                            continue@outerLoop
                        }
                    }
                }
            }
            // This would be a coding error
            if (atom == null) {
                throw MathDisplayException("Atom shouldn't be null")
            }
            atom.fontStyle = currentFontStyle
            list.addAtom(atom)
            prevAtom = atom

            if (oneCharOnly) {
                // we consumed our oneChar
                return list
            }
        }


        if (stopChar.code > 0) {
            if (stopChar == '}') {
                // We did not find a corresponding closing brace.
                this.setError(MTParseErrors.MismatchBraces, "Missing closing brace")
            } else {
                // we never found our stop character
                this.setError(
                    MTParseErrors.CharacterNotFound,
                    "Expected character not found: $stopChar"
                )
            }
        }
        return list
    }

    private fun readString(): String {
        // a string of all upper and lower case characters.
        val mutable = StringBuilder()
        while (hasCharacters()) {
            val ch: Char = getNextCharacter()
            if ((ch in 'a'..'z') || (ch in 'A'..'Z')) {
                mutable.append(ch)
            } else {
                // we went too far
                unlockCharacter()
                break
            }
        }
        return mutable.toString()
    }

    private fun readColor(): String? {
        if (!expectCharacter('{')) {
            // We didn't find an opening brace, so no env found.
            this.setError(MTParseErrors.CharacterNotFound, "Missing {")
            return null
        }

        // Ignore spaces and nonascii.
        skipSpaces()

        // a string of all upper and lower case characters.
        val mutable = StringBuilder()
        while (hasCharacters()) {
            val ch: Char = getNextCharacter()
            if (ch == '#' || (ch in 'A'..'F') || (ch in 'a'..'f') || (ch in '0'..'9')) {
                mutable.append(ch)
            } else {
                // we went too far
                unlockCharacter()
                break
            }
        }

        if (!expectCharacter('}')) {
            // We didn't find an closing brace, so invalid format.
            this.setError(MTParseErrors.CharacterNotFound, "Missing }")
            return null
        }
        return mutable.toString()
    }

    private fun nonSpaceChar(ch: Char): Boolean {
        return (ch.code < 0x21 || ch.code > 0x7E)
    }

    private fun skipSpaces() {
        while (hasCharacters()) {
            val ch: Char = getNextCharacter()
            if (nonSpaceChar(ch)) {
                // skip non ascii characters and spaces
                continue
            } else {
                unlockCharacter()
                return
            }
        }
    }

    private fun expectCharacter(ch: Char): Boolean {
        if (nonSpaceChar(ch)) throw MathDisplayException("Expected non space character $ch")
        skipSpaces()

        if (hasCharacters()) {
            val c: Char = getNextCharacter()
            if (nonSpaceChar(c)) throw MathDisplayException("Expected non space character $c")
            if (c == ch) {
                return true
            } else {
                unlockCharacter()
                return false
            }
        }
        return false
    }

    private fun readCommand(): String {
        if (hasCharacters()) {
            // Check if we have a single character command.
            val ch: Char = getNextCharacter()
            // Single char commands
            if (singleCharCommands.contains(ch)) {
                return ch.toString()
            } else {
                // not a known single character command
                unlockCharacter()
            }
        }
        // otherwise a command is a string of all upper and lower case characters.
        return readString()
    }

    private fun readDelimiter(): String? {
        // Ignore spaces and nonascii.
        skipSpaces()
        while (hasCharacters()) {
            val ch: Char = getNextCharacter()
            if (nonSpaceChar(ch)) throw MathDisplayException("Expected non space character $ch")
            if (ch == '\\') {
                // \ means a command
                val command: String = readCommand()
                if (command == "|") {
                    // | is a command and also a regular delimiter. We use the || command to
                    // distinguish between the 2 cases for the caller.
                    return "||"
                }
                return command
            } else {
                return ch.toString()
            }
        }
        // We ran out of characters for delimiter
        return null
    }

    private fun readEnvironment(): String? {
        if (!expectCharacter('{')) {
            // We didn't find an opening brace, so no env found.
            this.setError(MTParseErrors.CharacterNotFound, "Missing {")
            return null
        }

        // Ignore spaces and nonascii.
        skipSpaces()
        val env: String? = readString()

        if (!expectCharacter('}')) {
            // We didn't find an closing brace, so invalid format.
            this.setError(MTParseErrors.CharacterNotFound, "Missing }")
            return null
        }
        return env
    }

    private fun getBoundaryAtom(delimiterType: String): MTMathAtom? {
        val delimiter = this.readDelimiter()
        if (delimiter == null) {
            this.setError(MTParseErrors.MissingDelimiter, "Missing delimiter for $delimiterType")
            return null
        }
        val boundary = MTMathAtom.boundary(delimiter)
        if (boundary == null) {
            this.setError(
                MTParseErrors.InvalidDelimiter,
                "Invalid delimiter for $delimiterType: $delimiter"
            )
            return null
        }

        return boundary
    }

    private fun atomForCommand(command: String): MTMathAtom? {
        val atom = MTMathAtom.atomForLatexSymbol(command)
        if (atom != null) {
            return atom
        }
        val accent = MTMathAtom.accentWithName(command)
        if (accent != null) {
            // The command is an accent
            accent.innerList = this.buildInternal(true)
            return accent
        }

        when (command) {
            "frac" -> {
                // A fraction command has 2 arguments
                val frac = MTFraction()
                frac.numerator = this.buildInternal(true)
                frac.denominator = this.buildInternal(true)
                return frac
            }

            "binom" -> {
                // A binom command has 2 arguments
                val frac = MTFraction(false)
                frac.numerator = this.buildInternal(true)
                frac.denominator = this.buildInternal(true)
                frac.leftDelimiter = "("
                frac.rightDelimiter = ")"
                return frac
            }

            "sqrt" -> {
                // A sqrt command with one argument
                val rad = MTRadical()
                val ch = this.getNextCharacter()
                if (ch == '[') {
                    // special handling for sqrt[degree]{radicand}
                    rad.degree = this.buildInternal(false, ']')
                    rad.radicand = this.buildInternal(true)
                } else {
                    this.unlockCharacter()
                    rad.radicand = this.buildInternal(true)
                }
                return rad
            }

            "left" -> {
                // Save the current inner while a new one gets built.
                val oldInner: MTInner? = currentInnerAtom
                currentInnerAtom = MTInner()
                currentInnerAtom?.leftBoundary = this.getBoundaryAtom("left")
                if (currentInnerAtom?.leftBoundary == null) {
                    return null
                }
                currentInnerAtom?.innerList = this.buildInternal(false)
                if (currentInnerAtom?.rightBoundary == null) {
                    // A right node would have set the right boundary so we must be missing the right node.
                    this.setError(MTParseErrors.MissingRight, "Missing \\right")
                    return null
                }
                // reinstate the old inner atom.
                val newInner = currentInnerAtom
                currentInnerAtom = oldInner
                return newInner
            }

            "overline" -> {
                // The overline command has 1 arguments
                val over = MTOverLine()
                over.innerList = this.buildInternal(true)
                return over
            }

            "underline" -> {
                // The underline command has 1 arguments
                val under = MTUnderLine()
                under.innerList = this.buildInternal(true)
                return under
            }

            "begin" -> {
                val env = this.readEnvironment() ?: return null
                return buildTable(env, null, false)
            }

            "color" -> {
                // A color command has 2 arguments
                val mathColor = MTMathColor()
                mathColor.colorString = this.readColor()
                mathColor.innerList = this.buildInternal(true)
                return mathColor
            }

            "textcolor" -> {
                // A textcolor command has 2 arguments
                val mathColor = MTMathTextColor()
                mathColor.colorString = this.readColor()
                mathColor.innerList = this.buildInternal(true)
                return mathColor
            }

            else -> {
                this.setError(MTParseErrors.InvalidCommand, "Invalid command $command")
                return null
            }
        }
    }

    private fun stopCommand(command: String, list: MTMathList, stopChar: Char): MTMathList? {
        when (command) {
            "right" -> {
                if (currentInnerAtom == null) {
                    this.setError(MTParseErrors.MissingLeft, "Missing \\left")
                    return null
                }
                currentInnerAtom?.rightBoundary = this.getBoundaryAtom("right")
                if (currentInnerAtom?.rightBoundary == null) {
                    return null
                }
                // return the list read so far.
                return list
            }

            "over", "atop", "choose", "brack", "brace" -> {
                val frac = if (command == "over") {
                    MTFraction()
                } else {
                    MTFraction(false)
                }
                val delimiters = fractionCommands[command]
                if (delimiters != null && delimiters.size == 2) {
                    frac.leftDelimiter = delimiters[0]
                    frac.rightDelimiter = delimiters[1]
                }
                frac.numerator = list
                frac.denominator = this.buildInternal(false, stopChar)
                if (errorActive()) {
                    return null
                }
                val fracList = MTMathList()
                fracList.addAtom(frac)
                return fracList
            }

            "\\", "cr" -> {
                val ce = this.currentEnv
                if (ce != null) {
                    // Stop the current list and increment the row count
                    // ++ causes kotlin compile crash
                    ce.numRows = ce.numRows + 1
                    this.currentEnv = ce
                    return list
                } else {
                    // Create a new table with the current list and a default env
                    val table: MTMathAtom? = this.buildTable(null, list, true)
                    if (table != null)
                        return MTMathList(table)
                    return null
                }
            }

            "end" -> {
                if (currentEnv == null) {
                    this.setError(MTParseErrors.MissingBegin, "Missing \\begin")
                    return null
                } else {
                    val env = this.readEnvironment() ?: return null

                    if (env != currentEnv?.envName) {
                        this.setError(
                            MTParseErrors.InvalidEnv,
                            "Begin environment name $currentEnv.envName does not match end name: $env"
                        )
                        return null
                    }
                    // Finish the current environment.
                    currentEnv?.ended = true
                    return list
                }
            }

            else -> {
                return null
            }
        }
    }

    // Applies the modifier to the atom. Returns true if modifier applied.
    private fun applyModifier(modifier: String, atom: MTMathAtom?): (Boolean) {
        if (modifier == "limits") {
            if (atom == null || atom.type != MTMathAtomType.KMTMathAtomLargeOperator) {
                this.setError(
                    MTParseErrors.InvalidLimits,
                    "limits can only be applied to an operator."
                )
            } else {
                val op: MTLargeOperator = atom as MTLargeOperator
                op.hasLimits = true
            }
            return true
        } else if (modifier == "nolimits") {
            if (atom == null || atom.type != MTMathAtomType.KMTMathAtomLargeOperator) {
                this.setError(
                    MTParseErrors.InvalidLimits,
                    "nolimits can only be applied to an operator."
                )
                return true
            } else {
                val op: MTLargeOperator = atom as MTLargeOperator
                op.hasLimits = false
            }
            return true
        }
        return false
    }

    fun copyError(dst: MTParseError) {
        dst.copyFrom(this.parseError)
    }

    fun errorActive(): Boolean {
        return this.parseError != null
    }

    private fun setError(errorCode: MTParseErrors, message: String) {
        // Only record the first error.
        if (this.parseError == null) {
            this.parseError = MTParseError(errorCode, message)
        }
    }

    private fun buildTable(env: String?, firstList: MTMathList?, isRow: Boolean): MTMathAtom? {
        // Save the current env till an new one gets built.
        val oldEnv: MTEnvProperties? = currentEnv
        val newEnv = MTEnvProperties(env)
        this.currentEnv = newEnv
        var currentRow = 0
        var currentCol = 0
        val rows: MutableList<MutableList<MTMathList>> = mutableListOf()
        rows.add(currentRow, mutableListOf())
        if (firstList != null) {
            rows[currentRow].add(currentCol, firstList)
            if (isRow) {
                // ++ causes kotlin compile crash
                newEnv.numRows = newEnv.numRows + 1
                currentRow++
                rows.add(currentRow, mutableListOf())
            } else {
                currentCol++
            }
        }
        while (!newEnv.ended && this.hasCharacters()) {
            val list: MTMathList? = this.buildInternal(false)
            if (list == null) {
                // If there is an error building the list, bail out early.
                return null
            }
            rows[currentRow].add(currentCol, list)
            currentCol++
            if (newEnv.numRows > currentRow) {
                currentRow = newEnv.numRows.toInt() - 0
                rows.add(currentRow, mutableListOf())
                currentCol = 0
            }
        }
        if (!newEnv.ended && newEnv.envName != null) {
            this.setError(MTParseErrors.MissingEnd, "Missing \\end")
            return null
        }
        val error = MTParseError()
        val table: MTMathAtom? = MTMathAtom.table(newEnv.envName, rows, error)

        if (table == null) {
            parseError = error
            return null
        }
        // reinstate the old env.
        this.currentEnv = oldEnv
        return table
    }

    companion object Factory {
        fun buildFromString(str: String): MTMathList? {
            val builder = MTMathListBuilder(str)
            return builder.build()
        }

        fun buildFromString(str: String, error: MTParseError): MTMathList? {
            val builder = MTMathListBuilder(str)
            val output: MTMathList? = builder.build()
            if (builder.errorActive()) {
                builder.copyError(error)
                return null
            }
            return output
        }

        private val spaceToCommands: HashMap<Float, String> =
            hashMapOf(
                3.0f to ",",
                4.0f to ">",
                5.0f to ";",
                -3.0f to "!",
                18.0f to "quad",
                36.0f to "qquad"
            )

        private val styleToCommands: HashMap<MTLineStyle, String> =
            hashMapOf(
                MTLineStyle.KMTLineStyleDisplay to "displaystyle",
                MTLineStyle.KMTLineStyleText to "textstyle",
                MTLineStyle.KMTLineStyleScript to "scriptstyle",
                MTLineStyle.KMTLineStyleScriptScript to "scriptscriptstyle"
            )

        private fun delimiterToLatexString(delimiter: MTMathAtom): String {
            val command: String? = MTMathAtom.getDelimiterName(delimiter)
            if (command != null) {
                val singleChars: Array<String> =
                    arrayOf("(", ")", "[", "]", "<", ">", "|", ".", "/")
                return if (singleChars.contains(command)) {
                    command
                } else if (command == "||") {
                    "\\|" // special case for ||
                } else {
                    "\\$command"
                }
            }
            return ""
        }

        fun toLatexString(ml: MTMathList): String {
            val str = StringBuilder()
            var currentFontStyle: MTFontStyle = MTFontStyle.KMTFontStyleDefault
            for (atom in ml.atoms) {
                if (currentFontStyle != atom.fontStyle) {
                    if (currentFontStyle != MTFontStyle.KMTFontStyleDefault) {
                        // close the previous font style.
                        str.append("}")
                    }
                    if (atom.fontStyle != MTFontStyle.KMTFontStyleDefault) {
                        // open new font style
                        val fontStyleName: String = MTMathAtom.fontNameForStyle(atom.fontStyle)
                        str.append("\\$fontStyleName{")
                    }
                    currentFontStyle = atom.fontStyle
                }
                if (atom.type == MTMathAtomType.KMTMathAtomFraction) {
                    val frac = atom as MTFraction

                    val numerator: MTMathList? = frac.numerator
                    var numStr = ""
                    if (numerator != null) {
                        numStr = toLatexString(numerator)
                    }
                    val denominator: MTMathList? = frac.denominator
                    var denStr = ""
                    if (denominator != null) {
                        denStr = toLatexString(denominator)
                    }

                    if (frac.hasRule) {
                        str.append("\\frac{$numStr}{$denStr}")
                    } else {
                        var command: String?
                        if (frac.leftDelimiter == null && frac.rightDelimiter == null) {
                            command = "atop"
                        } else if (frac.leftDelimiter == "(" && frac.rightDelimiter == ")") {
                            command = "choose"
                        } else if (frac.leftDelimiter == "{" && frac.rightDelimiter == "}") {
                            command = "brace"
                        } else if (frac.leftDelimiter == "[" && frac.rightDelimiter == "]") {
                            command = "brack"
                        } else { // atopwithdelims is not handled in builder at this time so this case should not be executed unless built programmatically
                            val leftD: String? = frac.leftDelimiter
                            val rightD: String? = frac.rightDelimiter
                            command = "atopwithdelims$leftD$rightD"
                        }
                        str.append("{$numStr \\$command $denStr}")
                    }
                } else if (atom.type == MTMathAtomType.KMTMathAtomRadical) {
                    val rad = atom as MTRadical
                    str.append(rad.toLatexString())
                } else if (atom.type == MTMathAtomType.KMTMathAtomInner) {
                    val inner: MTInner = atom as MTInner
                    val leftBoundary = inner.leftBoundary
                    val rightBoundary = inner.rightBoundary

                    if (leftBoundary != null || rightBoundary != null) {
                        if (leftBoundary != null) {
                            val ds: String = this.delimiterToLatexString(leftBoundary)
                            str.append("\\left$ds ")
                        } else {
                            str.append("\\left. ")
                        }
                        val il = inner.innerList
                        if (il != null) {
                            str.append(this.toLatexString(il))
                        }
                        if (rightBoundary != null) {
                            val ds: String = this.delimiterToLatexString(rightBoundary)
                            str.append("\\right$ds ")
                        } else {
                            str.append("\\right. ")
                        }
                    } else {
                        str.append("{")
                        val il = inner.innerList
                        if (il != null) {
                            str.append(this.toLatexString(il))
                        }
                        str.append("}")
                    }
                } else if (atom.type == MTMathAtomType.KMTMathAtomTable) {
                    val table: MTMathTable = atom as MTMathTable
                    if (table.environment != null) {
                        str.append("\\begin{")
                        str.append(table.environment)
                        str.append("}")
                    }
                    for (i in 0 until table.numRows()) {
                        val row: MutableList<MTMathList> = table.cells[i]

                        for (j in 0 until row.size) {
                            var cell: MTMathList = row[j]
                            if (table.environment == "matrix") {
                                if (cell.atoms.isNotEmpty() && cell.atoms[0].type == MTMathAtomType.KMTMathAtomStyle) {
                                    // remove the first atom.
                                    val atoms: MutableList<MTMathAtom> =
                                        cell.atoms.subList(1, cell.atoms.size)
                                    cell = MTMathList(atoms)
                                }
                            }
                            if (table.environment == "eqalign" || table.environment == "aligned" || table.environment == "split") {
                                if (j == 1 && cell.atoms.isNotEmpty() && cell.atoms[0].type == MTMathAtomType.KMTMathAtomOrdinary && cell.atoms[0].nucleus.isEmpty()) {
                                    // Empty nucleus added for spacing. Remove it.
                                    val atoms: MutableList<MTMathAtom> =
                                        cell.atoms.subList(1, cell.atoms.size)
                                    cell = MTMathList(atoms)
                                }
                            }
                            str.append(this.toLatexString(cell))
                            if (j < row.size - 1) {
                                str.append("&")
                            }
                        }
                        if (i < table.numRows() - 1) {
                            str.append("\\\\ ")
                        }
                    }
                    if (table.environment != null) {
                        str.append("\\end{")
                        str.append(table.environment)
                        str.append("}")
                    }
                } else if (atom.type == MTMathAtomType.KMTMathAtomOverline) {
                    str.append("\\overline")
                    val over = atom as MTOverLine
                    str.append(over.toLatexString())
                } else if (atom.type == MTMathAtomType.KMTMathAtomUnderline) {
                    str.append("\\underline")
                    val under = atom as MTUnderLine
                    str.append(under.toLatexString())
                } else if (atom.type == MTMathAtomType.KMTMathAtomAccent) {
                    val accent = atom as MTAccent
                    val accentName = MTMathAtom.accentName(accent)
                    str.append("\\$accentName")
                    str.append(accent.toLatexString())
                } else if (atom.type == MTMathAtomType.KMTMathAtomLargeOperator) {
                    val op = atom as MTLargeOperator
                    val command: String? = MTMathAtom.latexSymbolName(atom)
                    if (command != null) {
                        val originalOp: MTLargeOperator =
                            MTMathAtom.atomForLatexSymbol(command) as MTLargeOperator
                        str.append("\\$command ")
                        if (originalOp.hasLimits != op.hasLimits) {
                            if (op.hasLimits) {
                                str.append("\\limits ")
                            } else {
                                str.append("\\nolimits ")
                            }
                        }
                    }
                } else if (atom.type == MTMathAtomType.KMTMathAtomSpace) {
                    val space = atom as MTMathSpace
                    val command: String? = spaceToCommands[space.space]
                    if (command != null) {
                        str.append("\\$command ")
                    } else {
                        //mkern parsing not yet implemented so this code does not have a test case
                        val s = "\\mkern${space.space.toFixed(1)}mu"
                        str.append(s)
                    }
                } else if (atom.type == MTMathAtomType.KMTMathAtomStyle) {
                    val style = atom as MTMathStyle
                    val command = styleToCommands[style.style]
                    str.append("\\$command ")
                } else if (atom.nucleus.isEmpty()) {
                    str.append("{}")
                } else if (atom.nucleus == "\u2236") {
                    // math colon
                    str.append(":")
                } else if (atom.nucleus == "\u2212") {
                    // math minus
                    str.append("-")
                } else {
                    val command = MTMathAtom.latexSymbolName(atom)
                    if (command != null) {
                        str.append("\\$command ")
                    } else {
                        str.append(atom.nucleus)
                    }
                }

                val superscript = atom.superScript
                if (superscript != null) {
                    val s = this.toLatexString(superscript)
                    str.append("^{$s}")
                }

                val subscript = atom.subScript
                if (subscript != null) {
                    val s = this.toLatexString(subscript)
                    str.append("_{$s}")
                }
            }
            if (currentFontStyle != MTFontStyle.KMTFontStyleDefault) {
                str.append("}")
            }
            return str.toString()
        }
    }
}

