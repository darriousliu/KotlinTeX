import Foundation
import SwiftUI

// Delimiter shortfall from plain.tex
let kDelimiterFactor = 901
let kDelimiterShortfallPoints = 5

let kBaseLineSkipMultiplier: Float = 1.2 // default base line stretch is 12 pt for 10pt font.
let kLineSkipMultiplier: Float = 0.1 // default is 1pt for 10pt font.
let kLineSkipLimitMultiplier: Float = 0.0
let kJotMultiplier: Float = 0.3 // A jot is 3pt for a 10pt font.

class MTTypesetter {
    let font: MTFont
    var style: MTLineStyle
    var cramped: Bool
    var spaced: Bool
    var displayAtoms: [MTDisplay] = []
    var currentPosition: MTCGPoint = .init()
    var currentLine: String = ""
    var currentAtoms: [MTMathAtom] = []
    var currentLineIndexRange: NSRange = .init()
    var styleFont: MTFont

    init(font: MTFont, lineStyle: MTLineStyle, cramped: Bool = false, spaced: Bool = false) {
        self.font = font
        self.style = lineStyle
        self.cramped = cramped
        self.spaced = spaced
        self.styleFont = font  // 初始化
        // 其他初始化
    }

    static func createLineForMathList(
        mathList: MTMathList,
        font: MTFont,
        style: MTLineStyle
    ) -> MTMathListDisplay {
        let finalizedList = mathList.finalized()
        // default is not cramped
        return createLineForMathList(mathList: finalizedList, font: font, style: style, cramped: false)
    }

    static func createLineForMathList(
        mathList: MTMathList,
        font: MTFont,
        style: MTLineStyle,
        cramped: Bool
    ) -> MTMathListDisplay {
        return createLineForMathList(mathList: mathList, font: font, style: style, cramped: cramped, spaced: false)
    }

    private static func createLineForMathList(
        mathList: MTMathList,
        font: MTFont,
        style: MTLineStyle,
        cramped: Bool,
        spaced: Bool
    ) -> MTMathListDisplay {
        let preprocessedAtoms = preprocessMathList(ml: mathList)
        let typesetter = MTTypesetter(font: font, lineStyle: style, cramped: cramped, spaced: spaced)
        try! typesetter.createDisplayAtoms(preprocessed: preprocessedAtoms)
        let lastAtom = mathList.atoms.last
        let maxrange = lastAtom?.indexRange.maxRange ?? 0
        let line = MTMathListDisplay(displays: typesetter.displayAtoms, range: NSRange(location: 0, length: maxrange))
        return line
    }

    static func preprocessMathList(ml: MTMathList) -> [MTMathAtom] {
        // Note: Some of the preprocessing described by the TeX algorithm is done in the finalize method of MTMathList.
        // Specifically rules 5 & 6 in Appendix G are handled by finalize.
        // This function does not do a complete preprocessing as specified by TeX either. It removes any special atom types
        // that are not included in TeX and applies Rule 14 to merge ordinary characters.
        var preprocessed: [MTMathAtom] = []
        var prevNode: MTMathAtom? = nil
        for atom in ml.atoms {
            if atom.type == .kMTMathAtomVariable || atom.type == .kMTMathAtomNumber {
                // These are not a TeX type nodes. TeX does this during parsing the input.
                // switch to using the font specified in the atom
                let newFont = changeFont(atom.nucleus, fontStyle: atom.fontStyle)
                // We convert it to ordinary
                atom.type = .kMTMathAtomOrdinary
                atom.nucleus = newFont
            } else if atom.type == .kMTMathAtomUnaryOperator {
                // TeX treats these as Ordinary. So will we.
                atom.type = .kMTMathAtomOrdinary
            }

            if atom.type == .kMTMathAtomOrdinary {
                // This is Rule 14 to merge ordinary characters.
                // combine ordinary atoms together
                if let prev = prevNode, prev.type == .kMTMathAtomOrdinary, prev.subScript == nil, prev.superScript == nil {
                    prev.fuse(atom: atom)
                    // skip the current node, we are done here.
                    continue
                }
            }

            // greg leftover todo from iOS code
            // TODO: add italic correction here or in second pass?
            prevNode = atom
            preprocessed.append(atom)
        }
        return preprocessed
    }

    // returns the size of the font in this style
    private func getStyleSize(style: MTLineStyle, font: MTFont) -> Float {
        let original = font.fontSize
        switch style {
        case .kMTLineStyleDisplay, .kMTLineStyleText:
            return original
        case .kMTLineStyleScript:
            return original * font.mathTable.scriptScaleDown
        case .kMTLineStyleScriptScript:
            return original * font.mathTable.scriptScriptScaleDown
        }
    }

    private func addInterElementSpace(prevNode: MTMathAtom?, currentType: MTMathAtomType) {
        var interElementSpace: Float = 0.0
        if let prevNode = prevNode {
            interElementSpace = try! self.getInterElementSpace(left: prevNode.type, right: currentType)
        } else if spaced {
            // For the first atom of a spaced list, treat it as if it is preceded by an open.
            interElementSpace = try! self.getInterElementSpace(left: .kMTMathAtomOpen, right: currentType)
        }
        currentPosition.x += interElementSpace
    }

    private func createDisplayAtoms(preprocessed: [MTMathAtom]) throws {
        // items should contain all the nodes that need to be layed out.
        // convert to a list of MTDisplayAtoms
        var prevNode: MTMathAtom? = nil
        var lastType: MTMathAtomType = .kMTMathAtomNone
        outerloop: for atom in preprocessed {
            switch atom.type {
            case .kMTMathAtomNone:
                break
            case .kMTMathAtomNumber, .kMTMathAtomVariable, .kMTMathAtomUnaryOperator:
                throw MathDisplayException("These types should never show here as they are removed by preprocessing")
            case .kMTMathAtomBoundary:
                throw MathDisplayException("A boundary atom should never be inside a mathlist.")
            case .kMTMathAtomSpace:
                // stash the existing layout
                if !currentLine.isEmpty {
                    self.addDisplayLine()
                }
                let space = atom as! MTMathSpace
                // add the desired space
                currentPosition.x += space.space * styleFont.mathTable.muUnit()
                // Since this is extra space, the desired interelement space between the prevAtom
                // and the next node is still preserved. To avoid resetting the prevAtom and lastType
                // we skip to the next node.
                continue outerloop
            case .kMTMathAtomStyle:
                // stash the existing layout
                if !currentLine.isEmpty {
                    self.addDisplayLine()
                }
                let style = atom as! MTMathStyle
                self.style = style.style
                // We need to preserve the prevNode for any interelement space changes.
                // so we skip to the next node.
                continue outerloop
            case .kMTMathAtomColor:
                // stash the existing layout
                if !currentLine.isEmpty {
                    self.addDisplayLine()
                }
                let colorAtom = atom as! MTMathColor
                if let innerList = colorAtom.innerList {
                    let display = MTTypesetter.createLineForMathList(mathList: innerList, font: font, style: style)
                    display.localTextColor = MTColor.parseColor(MTColor.parseColor(colorAtom.colorString))
                    display.position = currentPosition
                    currentPosition.x += display.width
                    displayAtoms.append(display)
                }
            case .kMTMathAtomTextColor:
                // stash the existing layout
                if !currentLine.isEmpty {
                    self.addDisplayLine()
                }
                let colorAtom = atom as! MTMathTextColor
                if let innerList = colorAtom.innerList {
                    let display = MTTypesetter.createLineForMathList(mathList: innerList, font: font, style: style)
                    display.localTextColor = MTColor.parseColor(MTColor.parseColor(colorAtom.colorString))

                    if let prevNode = prevNode {
                        let interElementSpace = try! self.getInterElementSpace(left: prevNode.type, right: (display.subDisplays![0] as! MTCTLineDisplay).atoms[0].type)
                        if !currentLine.isEmpty {
                            if interElementSpace > 0 {
                                // add a kerning of that space to the previous character
                                currentPosition.x += interElementSpace
                            }
                        } else {
                            // increase the space
                            currentPosition.x += interElementSpace
                        }
                    }

                    display.position = currentPosition
                    currentPosition.x += display.width

                    displayAtoms.append(display)
                }
            case .kMTMathAtomRadical:
                if !currentLine.isEmpty {
                    self.addDisplayLine()
                }
                let rad = atom as! MTRadical
                self.addInterElementSpace(prevNode: prevNode, currentType: .kMTMathAtomOrdinary)
                let displayRad = self.makeRadical(radicand: rad.radicand!, range: rad.indexRange)
                if let degree = rad.degree {
                    let degreeDisplay = MTTypesetter.createLineForMathList(mathList: degree, font: self.font, style: .kMTLineStyleScriptScript)
                    displayRad.setDegree(degree: degreeDisplay, fontMetrics: self.styleFont.mathTable)
                }
                self.displayAtoms.append(displayRad)
                currentPosition.x += displayRad.width
                if atom.subScript != nil || atom.superScript != nil {
                    self.makeScripts(atom: atom, display: displayRad, index: rad.indexRange.location, delta: 0.0)
                }

            case .kMTMathAtomFraction:
                if !currentLine.isEmpty {
                    self.addDisplayLine()
                }
                let frac = atom as! MTFraction
                self.addInterElementSpace(prevNode: prevNode, currentType: atom.type)
                let displayFrac = self.makeFraction(frac: frac)
                displayAtoms.append(displayFrac)
                currentPosition.x += displayFrac.width
                if atom.subScript != nil || atom.superScript != nil {
                    self.makeScripts(atom: atom, display: displayFrac, index: frac.indexRange.location, delta: 0.0)
                }

            case .kMTMathAtomLargeOperator:
                if !currentLine.isEmpty {
                    self.addDisplayLine()
                }
                self.addInterElementSpace(prevNode: prevNode, currentType: atom.type)
                let op = atom as! MTLargeOperator
                let displayOp = self.makeLargeOp(op: op)
                displayAtoms.append(displayOp)

            case .kMTMathAtomInner:
                if !currentLine.isEmpty {
                    self.addDisplayLine()
                }
                self.addInterElementSpace(prevNode: prevNode, currentType: atom.type)
                let inner = atom as! MTInner
                var displayInner: MTDisplay? = nil
                if inner.leftBoundary != nil || inner.rightBoundary != nil {
                    displayInner = self.makeLeftRight(inner: inner)
                } else if let innerList = inner.innerList {
                    displayInner = MTTypesetter.createLineForMathList(mathList: innerList, font: font, style: style, cramped: cramped)
                }
                if let displayInner = displayInner {
                    displayInner.position = currentPosition
                    currentPosition.x += displayInner.width
                    displayAtoms.append(displayInner)
                    if atom.subScript != nil || atom.superScript != nil {
                        self.makeScripts(atom: atom, display: displayInner, index: inner.indexRange.location, delta: 0.0)
                    }
                }

            case .kMTMathAtomUnderline:
                if !currentLine.isEmpty {
                    self.addDisplayLine()
                }
                self.addInterElementSpace(prevNode: prevNode, currentType: .kMTMathAtomOrdinary)
                atom.type = .kMTMathAtomOrdinary
                let under = atom as! MTUnderLine
                if let displayUnder = self.makeUnderline(under) {
                    displayAtoms.append(displayUnder)
                    currentPosition.x += displayUnder.width
                    if atom.subScript != nil || atom.superScript != nil {
                        self.makeScripts(atom: atom, display: displayUnder, index: under.indexRange.location, delta: 0.0)
                    }
                }

            case .kMTMathAtomOverline:
                if !currentLine.isEmpty {
                    self.addDisplayLine()
                }
                self.addInterElementSpace(prevNode: prevNode, currentType: .kMTMathAtomOrdinary)
                atom.type = .kMTMathAtomOrdinary
                let over = atom as! MTOverLine
                if let displayOver = self.makeOverline(over) {
                    displayAtoms.append(displayOver)
                    currentPosition.x += displayOver.width
                    if atom.subScript != nil || atom.superScript != nil {
                        self.makeScripts(atom: atom, display: displayOver, index: over.indexRange.location, delta: 0.0)
                    }
                }

            case .kMTMathAtomAccent:
                if !currentLine.isEmpty {
                    self.addDisplayLine()
                }
                self.addInterElementSpace(prevNode: prevNode, currentType: .kMTMathAtomOrdinary)
                atom.type = .kMTMathAtomOrdinary
                let accent = atom as! MTAccent
                if let displayAccent = self.makeAccent(accent: accent) {
                    displayAtoms.append(displayAccent)
                    currentPosition.x += displayAccent.width
                    if atom.subScript != nil || atom.superScript != nil {
                        self.makeScripts(atom: atom, display: displayAccent, index: accent.indexRange.location, delta: 0.0)
                    }
                }

            case .kMTMathAtomTable:
                if !currentLine.isEmpty {
                    self.addDisplayLine()
                }
                self.addInterElementSpace(prevNode: prevNode, currentType: .kMTMathAtomInner)
                atom.type = .kMTMathAtomInner
                let table = atom as! MTMathTable
                let displayTable = self.makeTable(table: table)
                displayAtoms.append(displayTable)
                currentPosition.x += displayTable.width
                // No scripts for table

            case .kMTMathAtomOrdinary, .kMTMathAtomBinaryOperator, .kMTMathAtomRelation, .kMTMathAtomOpen, .kMTMathAtomClose, .kMTMathAtomPlaceholder, .kMTMathAtomPunctuation:
                if !currentLine.isEmpty {
                    self.addDisplayLine()
                }
                if let prevNode = prevNode {
                    let interElementSpace = try! self.getInterElementSpace(left: prevNode.type, right: atom.type)
                    if !currentLine.isEmpty {
                        if interElementSpace > 0 {
                            currentPosition.x += interElementSpace
                        }
                    } else {
                        currentPosition.x += interElementSpace
                    }
                }
                let current = atom.nucleus
                currentLine += current
                if currentLineIndexRange.location == NSNotFound {
                    currentLineIndexRange.location = atom.indexRange.location
                    currentLineIndexRange.length = atom.indexRange.length
                } else {
                    currentLineIndexRange.length += atom.indexRange.length
                }
                if !atom.fusedAtoms.isEmpty {
                    self.currentAtoms.append(contentsOf: atom.fusedAtoms)
                } else {
                    self.currentAtoms.append(atom)
                }
                if atom.subScript != nil || atom.superScript != nil {
                    let line = self.addDisplayLine()
                    var delta: Float = 0.0
                    if !atom.nucleus.isEmpty {
                        let glyph = styleFont.findGlyphForCharacterAtIndex(index: 0, str: atom.nucleus)
                        delta = styleFont.mathTable.getItalicCorrection(gid: glyph.gid)
                    }
                    if delta > 0 && atom.subScript == nil {
                        currentPosition.x += delta
                    }
                    self.makeScripts(atom: atom, display: line, index: atom.indexRange.location + atom.indexRange.length - 1, delta: delta)
                }
            default:
                break
            }
            lastType = atom.type
            prevNode = atom
        }
        if !currentLine.isEmpty {
            self.addDisplayLine()
        }
        if spaced && lastType != .kMTMathAtomNone {
            // If _spaced then add an interelement space between the last type and close
            let display = displayAtoms.last!
            let interElementSpace = try self.getInterElementSpace(left: lastType, right: .kMTMathAtomClose)
            display.width += interElementSpace
        }
    }

    private func addDisplayLine() -> MTCTLineDisplay {
        // add the font
        let displayAtom = MTCTLineDisplay(str: currentLine, range: currentLineIndexRange, font: styleFont, atoms: currentAtoms)
        displayAtom.position = currentPosition
        displayAtoms.append(displayAtom)
        // update the position
        currentPosition.x += displayAtom.width
        // clear the string and the range
        currentLine = ""
        currentAtoms = []
        currentLineIndexRange = NSRange()
        return displayAtom
    }

    // Spacing

    // Returned in units of mu = 1/18 em.
    private func getSpacingInMu(type: MTInterElementSpaceType) -> Int {
        switch type {
        case .KMTSpaceInvalid:
            return -1
        case .KMTSpaceNone:
            return 0
        case .KMTSpaceThin:
            return 3
        case .KMTSpaceNSThin:
            return style < .kMTLineStyleScript ? 3 : 0
        case .KMTSpaceNSMedium:
            return style < .kMTLineStyleScript ? 4 : 0
        case .KMTSpaceNSThick:
            return style < .kMTLineStyleScript ? 5 : 0
        }
    }


    private func getInterElementSpace(left: MTMathAtomType, right: MTMathAtomType) throws -> Float {
        let leftIndex = try getInterElementSpaceArrayIndexForType(type: left, row: true)
        let rightIndex = try getInterElementSpaceArrayIndexForType(type: right, row: false)
        let spaceArray = interElementSpaceArray[leftIndex]
        let spaceType = spaceArray[rightIndex]
        if spaceType == .KMTSpaceInvalid {
            throw MathDisplayException("Invalid space between \(left) and \(right)")
        }

        let spaceMultipler = self.getSpacingInMu(type: spaceType)
        if spaceMultipler > 0 {
            // 1 em = size of font in pt. space multipler is in multiples mu or 1/18 em
            return Float(spaceMultipler) * styleFont.mathTable.muUnit()
        }
        return 0.0
    }


    // Subscript/Superscript

    private func scriptStyle() -> MTLineStyle {
        switch self.style {
        case .kMTLineStyleDisplay, .kMTLineStyleText:
            return .kMTLineStyleScript
        case .kMTLineStyleScript:
            return .kMTLineStyleScriptScript
        case .kMTLineStyleScriptScript:
            return .kMTLineStyleScriptScript
        }
    }


    // subscript is always cramped
    private func subScriptCramped() -> Bool {
        return true
    }

    // superscript is cramped only if the current style is cramped
    private func superScriptCramped() -> Bool {
        return cramped
    }

    private func superScriptShiftUp() -> Float {
        return cramped ? styleFont.mathTable.superscriptShiftUpCramped : styleFont.mathTable.superscriptShiftUp
    }

    // make scripts for the last atom
    // index is the index of the element which is getting the sub/super scripts.
    private func makeScripts(atom: MTMathAtom, display: MTDisplay, index: Int, delta: Float) {
        let subScriptList = atom.subScript
        let superScriptList = atom.superScript

        precondition(subScriptList != nil || superScriptList != nil)

        display.hasScript = true

        // get the font in script style
        let scriptFontSize = self.getStyleSize(style: self.scriptStyle(), font: self.font)
        let scriptFont = self.font.copyFontWithSize(size: scriptFontSize)
        let scriptFontMetrics = scriptFont.mathTable

        // if it is not a simple line then
        var superScriptShiftUp = display.ascent - scriptFontMetrics!.superscriptBaselineDropMax
        var subscriptShiftDown = display.descent + scriptFontMetrics!.subscriptBaselineDropMin

        if superScriptList == nil, let subScriptList = subScriptList {
            let subScript = MTTypesetter.createLineForMathList(mathList: subScriptList, font: self.font, style: self.scriptStyle(), cramped: self.subScriptCramped())
            subScript.type = .kMTLinePositionSubscript
            subScript.index = index

            subscriptShiftDown = max(subscriptShiftDown, styleFont.mathTable.subscriptShiftDown)
            subscriptShiftDown = max(subscriptShiftDown, subScript.ascent - styleFont.mathTable.subscriptTopMax)
            // add the subscript
            subScript.position = MTCGPoint(x: currentPosition.x, y: currentPosition.y - subscriptShiftDown)
            displayAtoms.append(subScript)
            // update the position
            currentPosition.x += subScript.width + styleFont.mathTable.spaceAfterScript
            return
        }

        let superScript = MTTypesetter.createLineForMathList(mathList: superScriptList!, font: self.font, style: self.scriptStyle(), cramped: self.superScriptCramped())
        superScript.type = .kMTLinePositionSuperscript
        superScript.index = index
        superScriptShiftUp = max(superScriptShiftUp, self.superScriptShiftUp())
        superScriptShiftUp = max(superScriptShiftUp, superScript.descent + styleFont.mathTable.superscriptBottomMin)

        if subScriptList == nil {
            superScript.position = MTCGPoint(x: currentPosition.x, y: currentPosition.y + superScriptShiftUp)
            displayAtoms.append(superScript)
            // update the position
            currentPosition.x += superScript.width + styleFont.mathTable.spaceAfterScript
            return
        }

        let subScript = MTTypesetter.createLineForMathList(mathList: subScriptList!, font: self.font, style: self.scriptStyle(), cramped: self.subScriptCramped())
        subScript.type = .kMTLinePositionSubscript
        subScript.index = index
        subscriptShiftDown = max(subscriptShiftDown, styleFont.mathTable.subscriptShiftDown)

        // joint positioning of subscript & superscript
        let subSuperScriptGap = (superScriptShiftUp - superScript.descent) + (subscriptShiftDown - subScript.ascent)
        if subSuperScriptGap < styleFont.mathTable.subSuperscriptGapMin {
            // Set the gap to atleast as much
            subscriptShiftDown += styleFont.mathTable.subSuperscriptGapMin - subSuperScriptGap
            let superscriptBottomDelta = styleFont.mathTable.superscriptBottomMaxWithSubscript - (superScriptShiftUp - superScript.descent)
            if superscriptBottomDelta > 0 {
                // superscript is lower than the max allowed by the font with a subscript.
                superScriptShiftUp += superscriptBottomDelta
                subscriptShiftDown -= superscriptBottomDelta
            }
        }

        // The delta is the italic correction above that shift superscript position
        superScript.position = MTCGPoint(x: currentPosition.x + delta, y: currentPosition.y + superScriptShiftUp)
        displayAtoms.append(superScript)
        subScript.position = MTCGPoint(x: currentPosition.x, y: currentPosition.y - subscriptShiftDown)
        displayAtoms.append(subScript)
        currentPosition.x += max(superScript.width + delta, subScript.width) + styleFont.mathTable.spaceAfterScript
    }

// Fractions

    func numeratorShiftUp(hasRule: Bool) -> Float {
        if hasRule {
            if self.style == .kMTLineStyleDisplay {
                return self.styleFont.mathTable.fractionNumeratorDisplayStyleShiftUp
            } else {
                return self.styleFont.mathTable.fractionNumeratorShiftUp
            }
        } else {
            if self.style == .kMTLineStyleDisplay {
                return self.styleFont.mathTable.stackTopDisplayStyleShiftUp
            } else {
                return self.styleFont.mathTable.stackTopShiftUp
            }
        }
    }

    func numeratorGapMin() -> Float {
        return self.style == .kMTLineStyleDisplay ? self.styleFont.mathTable.fractionNumeratorDisplayStyleGapMin
            : self.styleFont.mathTable.fractionNumeratorGapMin
    }

    func denominatorShiftDown(hasRule: Bool) -> Float {
        if hasRule {
            if self.style == .kMTLineStyleDisplay {
                return self.styleFont.mathTable.fractionDenominatorDisplayStyleShiftDown
            } else {
                return self.styleFont.mathTable.fractionDenominatorShiftDown
            }
        } else {
            if self.style == .kMTLineStyleDisplay {
                return self.styleFont.mathTable.stackBottomDisplayStyleShiftDown
            } else {
                return self.styleFont.mathTable.stackBottomShiftDown
            }
        }
    }

    func denominatorGapMin() -> Float {
        return self.style == .kMTLineStyleDisplay ? self.styleFont.mathTable.fractionDenominatorDisplayStyleGapMin
            : self.styleFont.mathTable.fractionDenominatorGapMin
    }

    func stackGapMin() -> Float {
        return self.style == .kMTLineStyleDisplay ? self.styleFont.mathTable.stackDisplayStyleGapMin
            : self.styleFont.mathTable.stackGapMin
    }

    func fractionDelimiterHeight() -> Float {
        return self.style == .kMTLineStyleDisplay ? self.styleFont.mathTable.fractionDelimiterDisplayStyleSize
            : self.styleFont.mathTable.fractionDelimiterSize
    }

    private func fractionStyle() -> MTLineStyle {
        switch self.style {
        case .kMTLineStyleDisplay:
            return .kMTLineStyleText
        case .kMTLineStyleText:
            return .kMTLineStyleScript
        case .kMTLineStyleScript, .kMTLineStyleScriptScript:
            return .kMTLineStyleScriptScript
        }
    }

    private func makeFraction(frac: MTFraction) -> MTDisplay {
        // lay out the parts of the fraction
        let fractionStyle = self.fractionStyle()
        let numeratorDisplay = MTTypesetter.createLineForMathList(mathList: frac.numerator!, font: self.font, style: fractionStyle, cramped: false)
        let denominatorDisplay = MTTypesetter.createLineForMathList(mathList: frac.denominator!, font: self.font, style: fractionStyle, cramped: true)

        // determine the location of the numerator
        var numeratorShiftUp = self.numeratorShiftUp(hasRule: frac.hasRule)
        var denominatorShiftDown = self.denominatorShiftDown(hasRule: frac.hasRule)
        let barLocation = styleFont.mathTable.axisHeight
        let barThickness = frac.hasRule ? styleFont.mathTable.fractionRuleThickness : 0.0

        if frac.hasRule {
            // This is the difference between the lowest edge of the numerator and the top edge of the fraction bar
            let distanceFromNumeratorToBar = (numeratorShiftUp - numeratorDisplay.descent) - (barLocation + barThickness / 2)
            // The distance should at least be displayGap
            let minNumeratorGap = self.numeratorGapMin()
            if distanceFromNumeratorToBar < minNumeratorGap {
                // This makes the distance between the bottom of the numerator and the top edge of the fraction bar
                // at least minNumeratorGap.
                numeratorShiftUp += (minNumeratorGap - distanceFromNumeratorToBar)
            }

            // Do the same for the denominator
            // This is the difference between the top edge of the denominator and the bottom edge of the fraction bar
            let distanceFromDenominatorToBar = (barLocation - barThickness / 2) - (denominatorDisplay.ascent - denominatorShiftDown)
            // The distance should at least be denominator gap
            let minDenominatorGap = self.denominatorGapMin()
            if distanceFromDenominatorToBar < minDenominatorGap {
                // This makes the distance between the top of the denominator and the bottom of the fraction bar to be exactly
                // minDenominatorGap
                denominatorShiftDown += (minDenominatorGap - distanceFromDenominatorToBar)
            }
        } else {
            // This is the distance between the numerator and the denominator
            let clearance = (numeratorShiftUp - numeratorDisplay.descent) - (denominatorDisplay.ascent - denominatorShiftDown)
            // This is the minimum clearance between the numerator and denominator.
            let minGap = self.stackGapMin()
            if clearance < minGap {
                numeratorShiftUp += (minGap - clearance) / 2
                denominatorShiftDown += (minGap - clearance) / 2
            }
        }

        let displayFraction = MTFractionDisplay(numerator: numeratorDisplay, denominator: denominatorDisplay, range: frac.indexRange)
        displayFraction.position = currentPosition
        displayFraction.numeratorUp = numeratorShiftUp
        displayFraction.denominatorDown = denominatorShiftDown
        displayFraction.lineThickness = barThickness
        displayFraction.linePosition = barLocation

        if frac.leftDelimiter == nil && frac.rightDelimiter == nil {
            return displayFraction
        } else {
            return self.addDelimitersToFractionDisplay(display: displayFraction, frac: frac)
        }
    }

    private func addDelimitersToFractionDisplay(display: MTFractionDisplay, frac: MTFraction) -> MTDisplay {
        precondition(frac.leftDelimiter != nil || frac.rightDelimiter != nil)

        var innerElements: [MTDisplay] = []
        let glyphHeight = self.fractionDelimiterHeight()
        var position = MTCGPoint()

        if let ld = frac.leftDelimiter, !ld.isEmpty {
            let leftGlyph = self.findGlyphForBoundary(delimiter: ld, glyphHeight: glyphHeight)
            leftGlyph.position = position
            position.x += leftGlyph.width
            innerElements.append(leftGlyph)
        }

        display.position = position
        position.x += display.width
        innerElements.append(display)

        if let rd = frac.rightDelimiter, !rd.isEmpty {
            let rightGlyph = self.findGlyphForBoundary(delimiter: rd, glyphHeight: glyphHeight)
            rightGlyph.position = position
            position.x += rightGlyph.width
            innerElements.append(rightGlyph)
        }

        let innerDisplay = MTMathListDisplay(displays: innerElements, range: frac.indexRange)
        innerDisplay.position = currentPosition
        return innerDisplay
    }

    // Radicals
    private func radicalVerticalGap() -> Float {
        if style == .kMTLineStyleDisplay {
            return styleFont.mathTable.radicalDisplayStyleVerticalGap
        } else {
            return styleFont.mathTable.radicalVerticalGap
        }
    }

    private func getRadicalGlyphWithHeight(radicalHeight: Float) -> MTDisplay {

        let radicalGlyph = styleFont.findGlyphForCharacterAtIndex(index: 0, str: "\u{221A}")
        let glyph = self.findGlyph(glyph: radicalGlyph, height: radicalHeight)

        var glyphDisplay: MTDisplay? = nil
        if glyph.glyphAscent + glyph.glyphDescent < radicalHeight {
            // the glyphs is not as large as required. A glyph needs to be constructed using the extenders.
            glyphDisplay = self.constructGlyph(glyph: radicalGlyph, glyphHeight: radicalHeight)
        }

        if glyphDisplay == nil {
            // No constructed display so use the glyph we got.
            glyphDisplay = MTGlyphDisplay(glyph: glyph, range: NSRange(location: -1, length: 0), myFont: styleFont)
            glyphDisplay?.ascent = glyph.glyphAscent
            glyphDisplay?.descent = glyph.glyphDescent
            glyphDisplay?.width = glyph.glyphWidth
        }
        return glyphDisplay!
    }


    private func makeRadical(radicand: MTMathList, range: NSRange) -> MTRadicalDisplay {
        let innerDisplay = MTTypesetter.createLineForMathList(mathList: radicand, font: font, style: style, cramped: true)
        var clearance = self.radicalVerticalGap()
        let radicalRuleThickness = styleFont.mathTable.radicalRuleThickness
        let radicalHeight = innerDisplay.ascent + innerDisplay.descent + clearance + radicalRuleThickness

        let glyph = self.getRadicalGlyphWithHeight(radicalHeight: radicalHeight)


        // Note this is a departure from Latex. Latex assumes that glyphAscent == thickness.
        // Open type math makes no such assumption, and ascent and descent are independent of the thickness.
        // Latex computes delta as descent - (h(inner) + d(inner) + clearance)
        // but since we may not have ascent == thickness, we modify the delta calculation slightly.
        // If the font designer followes Latex conventions, it will be identical.
        let delta = (glyph.descent + glyph.ascent) - (innerDisplay.ascent + innerDisplay.descent + clearance + radicalRuleThickness)
        if delta > 0 {
            clearance += delta / 2  // increase the clearance to center the radicand inside the sign.
        }

        // we need to shift the radical glyph up, to coincide with the baseline of inner.
        // The new ascent of the radical glyph should be thickness + adjusted clearance + h(inner)
        let radicalAscent = radicalRuleThickness + clearance + innerDisplay.ascent
        let shiftUp = radicalAscent - glyph.ascent  // Note: if the font designer followed latex conventions, this is the same as glyphAscent == thickness.
        glyph.shiftDown = -shiftUp

        let radicalDisplay = MTRadicalDisplay(radicand: innerDisplay, radicalGlyph: glyph, range: range)
        radicalDisplay.position = currentPosition
        radicalDisplay.ascent = radicalAscent + styleFont.mathTable.radicalExtraAscender
        radicalDisplay.topKern = styleFont.mathTable.radicalExtraAscender
        radicalDisplay.lineThickness = radicalRuleThickness
        // Note: Until we have radical construction from parts, it is possible that glyphAscent+glyphDescent is less
        // than the requested height of the glyph (i.e. radicalHeight, so in the case the innerDisplay has a larger
        // descent we use the innerDisplay's descent.
        radicalDisplay.descent = max(glyph.ascent + glyph.descent - radicalAscent, innerDisplay.descent)
        radicalDisplay.width = glyph.width + innerDisplay.width
        return radicalDisplay
    }

    // Glyphs
    private func findGlyph(glyph: CGGlyph, height: Float) -> CGGlyph {
        let variants = styleFont.mathTable.getVerticalVariantsForGlyph(glyph: glyph)
        let numVariants = variants.count

        var bboxes: [BoundingBox?]? = Array(repeating: nil, count: numVariants)
        var advances: [Float] = Array(repeating: 0.0, count: numVariants)
        // Get the bounds for these glyphs
        styleFont.mathTable.getBoundingRectsForGlyphs(glyphs: variants, boundingRects: &bboxes, count: numVariants)
        styleFont.mathTable.getAdvancesForGlyphs(glyphs: variants, advances: &advances, count: numVariants)
        var ascent: Float = 0.0
        var descent: Float = 0.0
        var width: Float = 0.0

        for i in 0..<numVariants {
            let bounds = bboxes![i]
            width = advances[i]
            ascent = getBboxDetailsAscent(bbox: bounds)
            descent = getBboxDetailsDescent(bbox: bounds)

            if ascent + descent >= height {
                return CGGlyph(gid: variants[i], glyphAscent: ascent, glyphDescent: descent, glyphWidth: width)
            }
        }
        return CGGlyph(gid: variants[numVariants - 1], glyphAscent: ascent, glyphDescent: descent, glyphWidth: width)
    }

    private func constructGlyph(glyph: CGGlyph, glyphHeight: Float) -> MTGlyphConstructionDisplay? {
        guard let parts = styleFont.mathTable.getVerticalGlyphAssemblyForGlyph(glyph: glyph.gid), !parts.isEmpty else {
            return nil
        }

        var glyphs: [Int] = []
        var offsets: [Float] = []

        let height = constructGlyphWithParts(parts: parts, glyphHeight: glyphHeight, glyphs: &glyphs, offsets: &offsets)
        var advances: [Float] = [0.0]

        styleFont.mathTable.getAdvancesForGlyphs(glyphs: glyphs, advances: &advances, count: 1)
        let display = MTGlyphConstructionDisplay(glyphs: glyphs, offsets: offsets, myFont: styleFont)
        display.width = advances[0] // width of first glyph
        display.ascent = height
        display.descent = 0.0 // it's upto the rendering to adjust the display up or down.
        return display
    }

    private func constructGlyphWithParts(
        parts: [MTGlyphPart],
        glyphHeight: Float,
        glyphs: inout [Int],
        offsets: inout [Float]
    ) -> Float {

        var numExtenders = 0
        while true {
            var prev: MTGlyphPart? = nil
            let minDistance = styleFont.mathTable.minConnectorOverlap
            var minOffset: Float = 0.0
            var maxDelta: Float = 1000000.0 // large float
            glyphs.removeAll()
            offsets.removeAll()

            for part in parts {
                var repeats = 1
                if part.isExtender {
                    repeats = numExtenders
                }
                // add the extender num extender times
                for _ in 0..<repeats {
                    glyphs.append(part.glyph)
                    if let prev = prev {
                        let maxOverlap = min(prev.endConnectorLength, part.startConnectorLength)
                        // the minimum amount we can add to the offset
                        let minOffsetDelta = prev.fullAdvance - maxOverlap
                        // The maximum amount we can add to the offset.
                        let maxOffsetDelta = prev.fullAdvance - minDistance
                        // we can increase the offsets by at most max - min.
                        maxDelta = min(maxDelta, maxOffsetDelta - minOffsetDelta)
                        minOffset += minOffsetDelta
                    }
                    offsets.append(minOffset)
                    prev = part
                }
            }

            guard let prev = prev else {
                numExtenders += 1
                continue // maybe only extenders
            }

            let minHeight = minOffset + prev.fullAdvance
            let maxHeight = minHeight + maxDelta * Float(glyphs.count - 1)
            if minHeight >= glyphHeight {
                // we are done
                return minHeight
            } else if glyphHeight <= maxHeight {
                // spread the delta equally between all the connectors
                let delta = glyphHeight - minHeight
                let deltaIncrease = delta / Float(glyphs.count - 1)
                var lastOffset: Float = 0.0
                for i in 0..<offsets.count {
                    let offset = offsets[i] + Float(i) * deltaIncrease
                    offsets[i] = offset
                    lastOffset = offset
                }
                // we are done
                return lastOffset + prev.fullAdvance
            }
            numExtenders += 1
        }
    }

    // Large Operators
    private func makeLargeOp(op: MTLargeOperator) -> MTDisplay {
        let limits = (op.hasLimits && style == .kMTLineStyleDisplay)
        var delta: Float

        if op.nucleus.count == 1 {
            var glyph: CGGlyph = styleFont.findGlyphForCharacterAtIndex(index: 0, str: op.nucleus)
            if style == .kMTLineStyleDisplay && glyph.isValid {
                // Enlarge the character in display style.
                glyph = CGGlyph(gid: styleFont.mathTable.getLargerGlyph(glyph: glyph.gid))
            }
            // This is be the italic correction of the character.
            delta = styleFont.mathTable.getItalicCorrection(gid: glyph.gid)

            // vertically center
            var bboxes: [BoundingBox?]? = [nil]
            var advances: [Float] = Array(repeating: 0.0, count: 1)
            let variants = [glyph.gid]
            // Get the bounds for these glyphs
            styleFont.mathTable.getBoundingRectsForGlyphs(glyphs: variants, boundingRects: &bboxes, count: variants.count)
            styleFont.mathTable.getAdvancesForGlyphs(glyphs: variants, advances: &advances, count: variants.count)

            let ascent = getBboxDetailsAscent(bbox: bboxes![0])
            let descent = getBboxDetailsDescent(bbox: bboxes![0])
            let shiftDown = 0.5 * (ascent - descent) - styleFont.mathTable.axisHeight
            let glyphDisplay = MTGlyphDisplay(glyph: glyph, range: op.indexRange, myFont: styleFont)
            glyphDisplay.ascent = ascent
            glyphDisplay.descent = descent
            glyphDisplay.width = advances[0]
            if op.subScript != nil && !limits {
                // Remove italic correction from the width of the glyph if
                // there is a subscript and limits is not set.
                glyphDisplay.width -= delta
            }
            glyphDisplay.shiftDown = shiftDown
            glyphDisplay.position = currentPosition
            return addLimitsToDisplay(display: glyphDisplay, op: op, delta: delta)
        } else {
            var atoms = [MTMathAtom]()
            atoms.append(op)
            let displayAtom = MTCTLineDisplay(str: op.nucleus, range: op.indexRange, font: styleFont, atoms: atoms)
            displayAtom.position = currentPosition
            return addLimitsToDisplay(display: displayAtom, op: op, delta: 0.0)
        }
    }

    private func addLimitsToDisplay(display: MTDisplay, op: MTLargeOperator, delta: Float) -> MTDisplay {
        // If there is no subscript or superscript, just return the current display
        if op.subScript == nil && op.superScript == nil {
            currentPosition.x += display.width
            return display
        }
        if op.hasLimits && style == .kMTLineStyleDisplay {
            // make limits
            var superScript: MTMathListDisplay? = nil
            var subScript: MTMathListDisplay? = nil

            if let superScriptList = op.superScript {
                superScript = MTTypesetter.createLineForMathList(
                    mathList: superScriptList,
                    font: font,
                    style: scriptStyle(),
                    cramped: superScriptCramped()
                )
            }
            if let subScriptList = op.subScript {
                subScript = MTTypesetter.createLineForMathList(
                    mathList: subScriptList,
                    font: font,
                    style: scriptStyle(),
                    cramped: subScriptCramped()
                )
            }
            precondition(superScript != nil || subScript != nil) // At least one of superscript or subscript should have been present.

            let opsDisplay = MTLargeOpLimitsDisplay(nucleus: display, upperLimit: superScript, lowerLimit: subScript, limitShift: delta / 2, extraPadding: 0.0)

            if let superScript = superScript {
                let upperLimitGap = max(
                    styleFont.mathTable.upperLimitGapMin,
                    styleFont.mathTable.upperLimitBaselineRiseMin - superScript.descent
                )
                opsDisplay.upperLimitGap = upperLimitGap
            }
            if let subScript = subScript {
                let lowerLimitGap = max(
                    styleFont.mathTable.lowerLimitGapMin,
                    styleFont.mathTable.lowerLimitBaselineDropMin - subScript.ascent
                )
                opsDisplay.lowerLimitGap = lowerLimitGap
            }
            opsDisplay.position = currentPosition
            opsDisplay.range = op.indexRange.copy()
            currentPosition.x += opsDisplay.width
            return opsDisplay
        } else {
            currentPosition.x += display.width
            makeScripts(atom: op, display: display, index: op.indexRange.location, delta: delta)
            return display
        }
    }

    // Large delimiters
    private func makeLeftRight(inner: MTInner) -> MTDisplay {
        precondition(inner.leftBoundary != nil || inner.rightBoundary != nil) // Inner should have a boundary to call this function

        let innerListDisplay = MTTypesetter.createLineForMathList(mathList: inner.innerList!, font: font, style: style, cramped: cramped, spaced: true)
        let axisHeight = styleFont.mathTable.axisHeight
        // delta is the max distance from the axis
        let delta = max(innerListDisplay.ascent - axisHeight, innerListDisplay.descent + axisHeight)
        let d1: Float = (delta / 500.0) * Float(kDelimiterFactor)  // This represents atleast 90% of the formula
        let d2: Float = 2.0 * delta - Float(kDelimiterShortfallPoints)  // This represents a shortfall of 5pt
        // The size of the delimiter glyph should cover at least 90% of the formula or
        // be at most 5pt short.
        let glyphHeight = max(d1, d2)

        var innerElements = [MTDisplay]()
        var position = MTCGPoint()
        if let lb = inner.leftBoundary, !lb.nucleus.isEmpty {
            let leftGlyph = self.findGlyphForBoundary(delimiter: lb.nucleus, glyphHeight: glyphHeight)
            leftGlyph.position = position
            position.x += leftGlyph.width
            innerElements.append(leftGlyph)
        }

        innerListDisplay.position = position
        position.x += innerListDisplay.width
        innerElements.append(innerListDisplay)

        if let rb = inner.rightBoundary, !rb.nucleus.isEmpty {
            let rightGlyph = self.findGlyphForBoundary(delimiter: rb.nucleus, glyphHeight: glyphHeight)
            rightGlyph.position = position
            position.x += rightGlyph.width
            innerElements.append(rightGlyph)
        }
        let innerDisplay = MTMathListDisplay(displays: innerElements, range: inner.indexRange)
        return innerDisplay
    }

    private func findGlyphForBoundary(delimiter: String, glyphHeight: Float) -> MTDisplay {
        let leftGlyph = styleFont.findGlyphForCharacterAtIndex(index: 0, str: delimiter)
        let glyph = self.findGlyph(glyph: leftGlyph, height: glyphHeight)

        var glyphDisplay: MTDisplay? = nil
        if glyph.glyphAscent + glyph.glyphDescent < glyphHeight {
            // the glyphs is not as large as required. A glyph needs to be constructed using the extenders.
            glyphDisplay = self.constructGlyph(glyph: leftGlyph, glyphHeight: glyphHeight)
        }

        if glyphDisplay == nil {
            // No constructed display so use the glyph we got.
            let newGlyphDisplay = MTGlyphDisplay(glyph: glyph, range: NSRange(location: -1, length: 0), myFont: styleFont)
            newGlyphDisplay.ascent = glyph.glyphAscent
            newGlyphDisplay.descent = glyph.glyphDescent
            newGlyphDisplay.width = glyph.glyphWidth
            glyphDisplay = newGlyphDisplay
        }

        // Center the glyph on the axis
        let shiftDown = 0.5 * (glyphDisplay!.ascent - glyphDisplay!.descent) - styleFont.mathTable.axisHeight
        glyphDisplay!.shiftDown = shiftDown
        return glyphDisplay!
    }

    // Underline/Overline
    private func makeUnderline(_ under: MTUnderLine) -> MTDisplay? {
        if let innerList = under.innerList {
            let innerListDisplay = MTTypesetter.createLineForMathList(mathList: innerList, font: font, style: style, cramped: cramped)

            let underDisplay = MTLineDisplay(inner: innerListDisplay, range: under.indexRange)
            // Move the line down by the vertical gap.
            underDisplay.lineShiftUp = -(innerListDisplay.descent + styleFont.mathTable.underbarVerticalGap)
            underDisplay.lineThickness = styleFont.mathTable.underbarRuleThickness
            underDisplay.ascent = innerListDisplay.ascent
            underDisplay.descent = innerListDisplay.descent + styleFont.mathTable.underbarVerticalGap + styleFont.mathTable.underbarRuleThickness + styleFont.mathTable.underbarExtraDescender
            underDisplay.width = innerListDisplay.width
            underDisplay.position = currentPosition
            return underDisplay
        }
        return nil
    }

    private func makeOverline(_ over: MTOverLine) -> MTDisplay? {
        if let innerList = over.innerList {
            let innerListDisplay = MTTypesetter.createLineForMathList(mathList: innerList, font: font, style: style, cramped: cramped)

            let overDisplay = MTLineDisplay(inner: innerListDisplay, range: over.indexRange)
            overDisplay.lineShiftUp = innerListDisplay.ascent + styleFont.mathTable.overbarVerticalGap
            overDisplay.lineThickness = styleFont.mathTable.underbarRuleThickness
            overDisplay.ascent = innerListDisplay.ascent + styleFont.mathTable.overbarVerticalGap + styleFont.mathTable.overbarRuleThickness + styleFont.mathTable.overbarExtraAscender
            overDisplay.descent = innerListDisplay.descent
            overDisplay.width = innerListDisplay.width
            overDisplay.position = currentPosition
            return overDisplay
        }
        return nil
    }

    // Accents
    private func isSingleCharAccentee(accent: MTAccent) -> Bool {
        if let innerList = accent.innerList {

            if innerList.atoms.count != 1 {
                // Not a single char list.
                return false
            }
            let innerAtom = innerList.atoms[0]
            if numberOfGlyphs(innerAtom.nucleus) != 1 {
                // A complex atom, not a simple char.
                return false
            }
            if innerAtom.subScript != nil || innerAtom.superScript != nil {
                return false
            }
            return true
        }
        return false
    }

    // The distance the accent must be moved from the beginning.
    private func getSkew(accent: MTAccent, accenteeWidth: Float, accentGlyph: CGGlyph) -> Float {
        if accent.nucleus.isEmpty {
            // No accent
            return 0.0
        }
        let accentAdjustment = styleFont.mathTable.getTopAccentAdjustment(glyph: accentGlyph.gid)
        var accenteeAdjustment: Float = 0.0
        if !self.isSingleCharAccentee(accent: accent) {
            // use the center of the accentee
            accenteeAdjustment = accenteeWidth / 2
        } else if let innerList = accent.innerList {
            let innerAtom = innerList.atoms[0]
            let accenteeGlyph = styleFont.findGlyphForCharacterAtIndex(index: 0, str: innerAtom.nucleus)
            accenteeAdjustment = styleFont.mathTable.getTopAccentAdjustment(glyph: accenteeGlyph.gid)
        }
        // The adjustments need to aligned, so skew is just the difference.
        return accenteeAdjustment - accentAdjustment
    }

    // Find the largest horizontal variant if exists, with width less than max width.
    private func findVariantGlyph(glyph: CGGlyph, maxWidth: Float) -> CGGlyph {
        let variants = styleFont.mathTable.getHorizontalVariantsForGlyph(glyph: glyph)
        let numVariants = variants.count
        precondition(numVariants > 0) // @"A glyph is always its own variant, so number of variants should be > 0")

        var bboxes: [BoundingBox?]? = Array(repeating: nil, count: numVariants)

        var advances: [Float] = Array(repeating: 0.0, count: numVariants)
        // Get the bounds for these glyphs
        styleFont.mathTable.getBoundingRectsForGlyphs(glyphs: variants, boundingRects: &bboxes, count: numVariants)
        styleFont.mathTable.getAdvancesForGlyphs(glyphs: variants, advances: &advances, count: numVariants)
        var retGlyph = CGGlyph()

        for i in 0..<numVariants {
            if let bounds = bboxes![i] {
                let ascent = getBboxDetailsAscent(bbox: bounds)
                let descent = getBboxDetailsDescent(bbox: bounds)
                let width = max(bounds.lowerLeftX, bounds.upperRightX)

                if width > maxWidth {
                    if i == 0 {
                        // glyph dimensions are not yet set
                        retGlyph.glyphWidth = advances[i]
                        retGlyph.glyphAscent = ascent
                        retGlyph.glyphDescent = descent
                    }
                    return retGlyph
                } else {
                    retGlyph.gid = variants[i]
                    retGlyph.glyphWidth = advances[i]
                    retGlyph.glyphAscent = ascent
                    retGlyph.glyphDescent = descent
                }
            }
        }
        // We exhausted all the variants and none was larger than the width, so we return the largest
        return retGlyph
    }

    private func makeAccent(accent: MTAccent) -> MTDisplay? {
        if let innerList = accent.innerList {
            var accentee = MTTypesetter.createLineForMathList(mathList: innerList, font: font, style: style, cramped: true)
            if accent.nucleus.isEmpty {
                // no accent!
                return accentee
            }
            var accentGlyph = styleFont.findGlyphForCharacterAtIndex(index: 0, str: accent.nucleus)
            let accenteeWidth = accentee.width
            accentGlyph = self.findVariantGlyph(glyph: accentGlyph, maxWidth: accenteeWidth)
            let delta = min(accentee.ascent, styleFont.mathTable.accentBaseHeight)

            let skew = self.getSkew(accent: accent, accenteeWidth: accenteeWidth, accentGlyph: accentGlyph)
            let height = accentee.ascent - delta // This is always positive since delta <= height.
            let accentPosition = MTCGPoint(x: skew, y: height)
            let accentGlyphDisplay = MTGlyphDisplay(glyph: accentGlyph, range: accent.indexRange, myFont: styleFont)
            accentGlyphDisplay.ascent = accentGlyph.glyphAscent
            accentGlyphDisplay.descent = accentGlyph.glyphDescent
            accentGlyphDisplay.width = accentGlyph.glyphWidth
            accentGlyphDisplay.position = accentPosition

            if self.isSingleCharAccentee(accent: accent) && (accent.subScript != nil || accent.superScript != nil) {
                // Attach the super/subscripts to the accentee instead of the accent.
                let innerAtom = accent.innerList!.atoms[0]
                innerAtom.superScript = accent.superScript
                innerAtom.subScript = accent.subScript
                accent.superScript = nil
                accent.subScript = nil
                // Remake the accentee (now with sub/superscripts)
                // Note: Latex adjusts the heights in case the height of the char is different in non-cramped mode. However this shouldn't be the case since cramping
                // only affects fractions and superscripts. We skip adjusting the heights.
                accentee = MTTypesetter.createLineForMathList(mathList: innerList, font: font, style: style, cramped: cramped)
            }

            let display = MTAccentDisplay(accent: accentGlyphDisplay, accentDisplay: accentee, range: accent.indexRange)
            display.width = accentee.width
            display.descent = accentee.descent
            let ascent = accentee.ascent - delta + accentGlyph.glyphAscent
            display.ascent = max(accentee.ascent, ascent)
            display.position = currentPosition

            return display
        } else {
            return nil
        }
    }

    private func makeTable(table: MTMathTable) -> MTDisplay {
        let numColumns = table.numColumns()
        if numColumns == 0 || table.numRows() == 0 {
            // Empty table
            let emptyList: [MTDisplay] = []
            return MTMathListDisplay(displays: emptyList, range: table.indexRange)
        }

        var columnWidths = Array(repeating: Float(0), count: numColumns)
        let displays = self.typesetCells(table: table, columnWidths: &columnWidths)

        // Position all the columns in each row
        var rowDisplays: [MTDisplay] = []
        for row in displays {
            let rowDisplay = self.makeRowWithColumns(cols: row, table: table, columnWidths: columnWidths)
            rowDisplays.append(rowDisplay)
        }

        // Position all the rows
        self.positionRows(rows: &rowDisplays, table: table)
        let tableDisplay = MTMathListDisplay(displays: rowDisplays, range: table.indexRange)
        tableDisplay.position = currentPosition
        return tableDisplay
    }

// Typeset every cell in the table. As a side-effect calculate the max column width of each column.
    private func typesetCells(table: MTMathTable, columnWidths: inout [Float]) -> [[MTDisplay]] {
        var displays = Array(repeating: [MTDisplay](), count: table.numRows())

        for r in 0..<table.numRows() {
            let row = table.cells[r]
            var colDisplays = Array(repeating: MTDisplay(), count: row.count)
            displays[r] = colDisplays
            for i in 0..<row.count {
                let disp = MTTypesetter.createLineForMathList(mathList: row[i], font: font, style: style, cramped: false)
                columnWidths[i] = max(disp.width, columnWidths[i])
                colDisplays[i] = disp
            }
        }
        return displays
    }

    private func makeRowWithColumns(cols: [MTDisplay], table: MTMathTable, columnWidths: [Float]) -> MTMathListDisplay {
        var columnStart: Float = 0
        var rowRange = NSRange()
        for i in 0..<cols.count {
            let col = cols[i]
            let colWidth = columnWidths[i]
            let alignment = table.getAlignmentForColumn(i)

            var cellPos = columnStart
            switch alignment {
            case .KMTColumnAlignmentRight:
                cellPos += colWidth - col.width
            case .KMTColumnAlignmentCenter:
                cellPos += (colWidth - col.width) / 2
            case .KMTColumnAlignmentLeft:
                // No changes if left aligned
                break
            default:
                break
            }

            rowRange = rowRange.location != NSNotFound ? rowRange.union(col.range) : col.range.copy() as! NSRange
            col.position = MTCGPoint(x: cellPos, y: 0)
            columnStart += colWidth + table.interColumnSpacing * styleFont.mathTable.muUnit()
        }

        let rowDisplay = MTMathListDisplay(displays: cols, range: rowRange)
        return rowDisplay
    }

    private func positionRows(rows: inout [MTDisplay], table: MTMathTable) {
        // Position the rows
        // We will first position the rows starting from 0 and then in the second pass center the whole table vertically.
        var currPos: Float = 0
        let openup = table.interRowAdditionalSpacing * kJotMultiplier * styleFont.fontSize
        let baselineSkip = openup + kBaseLineSkipMultiplier * styleFont.fontSize
        let lineSkip = openup + kLineSkipMultiplier * styleFont.fontSize
        let lineSkipLimit = openup + kLineSkipLimitMultiplier * styleFont.fontSize
        var prevRowDescent: Float = 0
        var ascent: Float = 0
        var first = true

        for row in rows {
            if first {
                row.position = MTCGPoint(x: 0, y: 0)
                ascent += row.ascent
                first = false
            } else {
                var skip = baselineSkip
                if skip - (prevRowDescent + row.ascent) < lineSkipLimit {
                    // rows are too close to each other. Space them apart further
                    skip = prevRowDescent + row.ascent + lineSkip
                }
                // We are going down so we decrease the y value.
                currPos -= skip
                row.position = MTCGPoint(x: 0, y: currPos)
            }
            prevRowDescent = row.descent
        }

        // Vertically center the whole structure around the axis
        // The descent of the structure is the position of the last row
        // plus the descent of the last row.
        let descent = -currPos + prevRowDescent
        let shiftDown = 0.5 * (ascent - descent) - styleFont.mathTable.axisHeight

        for row in rows {
            row.position = MTCGPoint(x: row.position.x, y: row.position.y - shiftDown)
        }
    }

    private func getBboxDetailsDescent(bbox: BoundingBox?) -> Float {
        // Descent is how much the line goes below the origin. However if the line is all above the origin, then descent can't be negative.
        if let bbox = bbox {
            return max(0, 0 - min(bbox.upperRightY, bbox.lowerLeftY))
        } else {
            return 0
        }
    }

    private func getBboxDetailsAscent(bbox: BoundingBox?) -> Float {
        if let bbox = bbox {
            return max(0, max(bbox.upperRightY, bbox.lowerLeftY))
        } else {
            return 0
        }
    }
}
