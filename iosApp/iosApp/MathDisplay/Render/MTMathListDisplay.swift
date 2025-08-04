//
//  CGPoint.swift
//  iosApp
//
//  Created by 刘振辉 on 2025/8/2.
//


import Foundation
import SwiftUI

let IS_DEBUG = false

struct MTCGPoint {
    var x: Float = 0.0
    var y: Float = 0.0
}

struct MTCGRect {
    var x: Float = 0.0
    var y: Float = 0.0
    var width: Float = 0.0
    var height: Float = 0.0
}

class MTDisplay {
    var ascent: Float = 0.0
    var descent: Float = 0.0
    var width: Float = 0.0
    var range: NSRange = .init()
    var hasScript: Bool = false
    var shiftDown: Float = 0.0
    var position: MTCGPoint = .init() {
        didSet {
            positionChanged()
        }
    }
    var textColor: Color = .black {
        didSet {
            colorChanged()
        }
    }
    var localTextColor: Color = .clear {
        didSet {
            colorChanged()
        }
    }

    init(ascent: Float = 0.0, descent: Float = 0.0, width: Float = 0.0, range: NSRange = .init(), hasScript: Bool = false) {
        self.ascent = ascent
        self.descent = descent
        self.width = width
        self.range = range
        self.hasScript = hasScript
    }

    func positionChanged() {
    }

    func colorChanged() {
    }

    func draw(canvas: GraphicsContext) {
        // 绘制逻辑
    }

    func displayBounds() -> MTCGRect {
        return MTCGRect(x: position.x, y: position.y - descent, width: width, height: ascent + descent)
    }
}

// List of normal atoms to display that would be an attributed string on iOS
// Since we do not allow kerning attribute changes this is a string displayed using the advances for the font
// Normally this is a single character. In some cases the string will be fused atoms
class MTCTLineDisplay: MTDisplay {
    let str: String
    let font: MTFont
    let atoms: [MTMathAtom]

    init(str: String, range: NSRange, font: MTFont, atoms: [MTMathAtom]) {
        self.str = str
        self.font = font
        self.atoms = atoms
        super.init(range: range)
        computeDimensions()
    }

    // Our own implementation of the ios6 function to get glyph path bounds.
    func computeDimensions() {
        let glyphs = font.getGidListForString(str: str)
        let num = glyphs.count
        var bboxes: [BoundingBox?]? = Array(repeating: nil, count: num)
        var advances: [Float] = Array(repeating: 0.0, count: num)
        // Get the bounds for these glyphs
        font.mathTable.getBoundingRectsForGlyphs(glyphs: glyphs, boundingRects: &bboxes, count: num)
        font.mathTable.getAdvancesForGlyphs(glyphs: glyphs, advances: &advances, count: num)

        self.width = 0.0
        for i in 0..<num {
            if let b = bboxes![i] {
                let ascent = max(0.0, b.upperRightY - 0)
                // Descent is how much the line goes below the origin. However if the line is all above the origin, then descent can't be negative.
                let descent = max(0.0, 0.0 - b.lowerLeftY)
                if ascent > self.ascent {
                    self.ascent = ascent
                }
                if descent > self.descent {
                    self.descent = descent
                }
                self.width += advances[i]
            }
        }
    }

    override func draw(canvas: GraphicsContext) {
        var canvas = canvas
        super.draw(canvas: canvas)
        let color = textColor
        let drawer = MTDrawFreeType(mathFont: font.mathTable)

        let glyphs = font.getGidListForString(str: str)
        let num = glyphs.count
        var advances: [Float] = Array(repeating: 0.0, count: num)
        font.mathTable.getAdvancesForGlyphs(glyphs: glyphs, advances: &advances, count: num)

        canvas.withCGContext { context in
            context.saveGState()
        }
        canvas.translateBy(x: CGFloat(position.x), y: CGFloat(position.y))
        canvas.scaleBy(x: CGFloat(1.0), y: CGFloat(-1.0))
        var x: Float = 0.0
        for i in 0..<num {
            try! drawer.drawGlyph(canvas: canvas, gid: glyphs[i], x: x, y: 0.0)
            x += advances[i]
        }
//        textPaint.color = Color.red
        canvas.withCGContext { context in
            context.restoreGState()
        }
    }
}


enum MTLinePosition {
    /// Regular
    case kMTLinePositionRegular

    /// Positioned at a subscript
    case kMTLinePositionSubscript

    /// Positioned at a superscript
    case kMTLinePositionSuperscript
}

class MTMathListDisplay: MTDisplay {

    /// Where the line is positioned
    var type: MTLinePosition = .kMTLinePositionRegular

    /**
     * An array of MTDisplays which are positioned relative to the position of the
     * the current display.
     */
    var subDisplays: [MTDisplay]? = nil

    /**
     * If a subscript or superscript this denotes the location in the parent MTList. For a
     * regular list this is NSNotFound
     */
    var index: Int = NSNotFound

    init(displays: [MTDisplay], range: NSRange) {
        super.init(range: range)
        self.subDisplays = displays
        self.recomputeDimensions()
    }

    override func colorChanged() {
        if let sd = self.subDisplays {
            for displayAtom in sd {
                // set the global color, if there is no local color
                if displayAtom.localTextColor == .clear {
                    displayAtom.textColor = self.textColor
                } else {
                    displayAtom.textColor = displayAtom.localTextColor
                }
            }
        }
    }

    override func draw(canvas: GraphicsContext) {
        var canvas = canvas
        canvas.save()
        if IS_DEBUG {
            canvas.drawArc(left: -4.0, top: -4.0, right: 4.0, bottom: 4.0, startAngle: 4.0, sweepAngle: 180.0, useCenter: false, color: .black)
        }

        canvas.translateBy(x: CGFloat(position.x), y: CGFloat(position.y))
        if IS_DEBUG {
            canvas.drawArc(left: -3.0, top: -3.0, right: 3.0, bottom: 3.0, startAngle: 0.0, sweepAngle: 360.0, useCenter: false, color: .blue)
        }
        // draw each atom separately
        if let sd = self.subDisplays {
            for displayAtom in sd {
                displayAtom.draw(canvas: canvas)
            }
        }
        canvas.restore()
    }

    func recomputeDimensions() {
        var maxAscent: Float = 0.0
        var maxDescent: Float = 0.0
        var maxWidth: Float = 0.0
        if let sd = self.subDisplays {
            for atom in sd {
                let ascent = max(0.0, atom.position.y + atom.ascent)
                if ascent > maxAscent {
                    maxAscent = ascent
                }

                let descent = max(0.0, -(atom.position.y - atom.descent))
                if descent > maxDescent {
                    maxDescent = descent
                }

                let width = atom.width + atom.position.x
                if width > maxWidth {
                    maxWidth = width
                }
            }
        }
        self.ascent = maxAscent
        self.descent = maxDescent
        self.width = maxWidth
    }
}

// MTFractionDisplay
class MTFractionDisplay: MTDisplay {
    var numerator: MTMathListDisplay
    var denominator: MTMathListDisplay
    var linePosition: Float = 0.0
    var lineThickness: Float = 0.0

    // NSAssert(self.range.length == 1, @"Fraction range length not 1 - range (%lu, %lu)", (unsigned long)range.location, (unsigned long)range.length)
    var numeratorUp: Float = 0.0 {
        didSet {
            self.updateNumeratorPosition()
        }
    }
    var denominatorDown: Float = 0.0 {
        didSet {
            self.updateDenominatorPosition()
        }
    }

    override var ascent: Float {
        get {
            return self.numerator.ascent + self.numeratorUp
        }
        set {
            // No additional functionality
        }
    }

    override var descent: Float {
        get {
            return self.denominator.descent + self.denominatorDown
        }
        set {
            // No additional functionality
        }
    }

    override var width: Float {
        get {
            return max(self.numerator.width, self.denominator.width)
        }
        set {
            // No additional functionality
        }
    }

    init(numerator: MTMathListDisplay, denominator: MTMathListDisplay, range: NSRange) {
        self.numerator = numerator
        self.denominator = denominator
        super.init(range: range)
    }

    func updateDenominatorPosition() {
        self.denominator.position = MTCGPoint(
            x: self.position.x + (self.width - self.denominator.width) / 2,
            y: self.position.y - self.denominatorDown
        )
    }

    func updateNumeratorPosition() {
        self.numerator.position = MTCGPoint(
            x: self.position.x + (self.width - self.numerator.width) / 2,
            y: self.position.y + self.numeratorUp
        )
    }

    override func positionChanged() {
        self.updateDenominatorPosition()
        self.updateNumeratorPosition()
    }

    override func colorChanged() {
        self.numerator.textColor = self.textColor
        self.denominator.textColor = self.textColor
    }

    override func draw(canvas: GraphicsContext) {
        var canvas = canvas
        self.numerator.draw(canvas: canvas)
        self.denominator.draw(canvas: canvas)

        if lineThickness != 0 {
            canvas.drawLine(
                x1: position.x,
                y1: position.y + linePosition,
                x2: position.x + width,
                y2: position.y + linePosition,
                lineWidth: lineThickness,
                color: self.textColor
            )
        }
    }
}

// MTRadicalDisplay
class MTRadicalDisplay: MTDisplay {
    let radicand: MTMathListDisplay
    let radicalGlyph: MTDisplay
    var radicalShift: Float = 0.0
    var degree: MTMathListDisplay? = nil
    var topKern: Float = 0.0
    var lineThickness: Float = 0.0

    init(radicand: MTMathListDisplay, radicalGlyph: MTDisplay, range: NSRange) {
        self.radicand = radicand
        self.radicalGlyph = radicalGlyph
        super.init(range: range)
        updateRadicandPosition()
    }

    func setDegree(degree: MTMathListDisplay, fontMetrics: MTFontMathTable) {
        // sets up the degree of the radical
        var kernBefore = fontMetrics.radicalKernBeforeDegree
        let kernAfter = fontMetrics.radicalKernAfterDegree
        let raise = fontMetrics.radicalDegreeBottomRaisePercent * (self.ascent - self.descent)

        // The layout is:
        // kernBefore, raise, degree, kernAfter, radical
        self.degree = degree

        // the radical is now shifted by kernBefore + degree.width + kernAfter
        self.radicalShift = kernBefore + degree.width + kernAfter
        if radicalShift < 0 {
            // we can't have the radical shift backwards, so instead we increase the kernBefore such
            // that _radicalShift will be 0.
            kernBefore -= radicalShift
            radicalShift = 0.0
        }

        // Note: position of degree is relative to parent.
        if let deg = self.degree {
            deg.position = MTCGPoint(x: self.position.x + kernBefore, y: self.position.y + raise)
            // Update the width by the _radicalShift
            self.width = radicalShift + radicalGlyph.width + self.radicand.width
        }
        // update the position of the radicand
        self.updateRadicandPosition()
    }

    override func positionChanged() {
        updateRadicandPosition()
    }

    func updateRadicandPosition() {
        // The position of the radicand includes the position of the MTRadicalDisplay
        // This is to make the positioning of the radical consistent with fractions and
        // have the cursor position finding algorithm work correctly.
        // move the radicand by the width of the radical sign
        self.radicand.position = MTCGPoint(
            x: self.position.x + radicalShift + radicalGlyph.width,
            y: self.position.y
        )
    }

    override func colorChanged() {
        self.radicand.textColor = self.textColor
        self.radicalGlyph.textColor = self.textColor
        if let deg = self.degree {
            deg.textColor = self.textColor
        }
    }

    override func draw(canvas: GraphicsContext) {
        var canvas = canvas
        self.radicand.draw(canvas: canvas)
        degree?.draw(canvas: canvas)

        canvas.save()

        // Make the current position the origin as all the positions of the sub atoms are relative to the origin.
        canvas.translateBy(x: CGFloat(self.position.x + radicalShift), y: CGFloat(self.position.y))

        // Draw the glyph.
        radicalGlyph.draw(canvas: canvas)

        // Draw the VBOX
        // for the kern of, we don't need to draw anything.
        let heightFromTop = topKern

        // draw the horizontal line with the given thickness
        let x = radicalGlyph.width
        let y = ascent - heightFromTop - lineThickness / 2
        canvas.drawLine(
            x1: x,
            y1: y,
            x2: x + radicand.width,
            y2: y,
            lineWidth: lineThickness,
            color: self.textColor
        )

        canvas.restore()
    }
}

// MTGlyphDisplay
class MTGlyphDisplay: MTDisplay {
    let glyph: CGGlyph
    let myFont: MTFont

    init(glyph: CGGlyph, range: NSRange, myFont: MTFont) {
        self.glyph = glyph
        self.myFont = myFont
        super.init(range: range)
    }

    override func draw(canvas: GraphicsContext) {
        var canvas = canvas
        super.draw(canvas: canvas)
//        textPaint.color = Color(textColor)
        let drawer = MTDrawFreeType(mathFont: myFont.mathTable)

        canvas.save()
        canvas.translateBy(x: CGFloat(position.x), y: CGFloat(position.y - self.shiftDown))
        canvas.scaleBy(x: 1.0, y: -1.0)
        try! drawer.drawGlyph(canvas: canvas, gid: glyph.gid, x: 0.0, y: 0.0)
        canvas.restore()
    }

    override var ascent: Float {
        get {
            return super.ascent - self.shiftDown
        }
        set {
            super.ascent = newValue
        }
    }

    override var descent: Float {
        get {
            return super.descent + self.shiftDown
        }
        set {
            super.descent = newValue
        }
    }
}

// MTGlyphConstructionDisplay
class MTGlyphConstructionDisplay: MTDisplay {
    var glyphs: [Int]
    var offsets: [Float]
    var myFont: MTFont

    init(glyphs: [Int], offsets: [Float], myFont: MTFont) {
        self.glyphs = glyphs
        self.offsets = offsets
        self.myFont = myFont
        super.init()
        precondition(glyphs.count == offsets.count)
    }

    override func draw(canvas: GraphicsContext) {
        var canvas = canvas
        let drawer = MTDrawFreeType(mathFont: myFont.mathTable)
        canvas.save()

        // Make the current position the origin as all the positions of the sub atoms are relative to the origin.
        canvas.translateBy(x: CGFloat(position.x), y: CGFloat(position.y - shiftDown))

        // Draw the glyphs.
        // positions these are x&y (0,offsets[i])
//        let textPaint = createPlatformPaint()
//        textPaint.isAntiAlias = true
//        textPaint.color = Color(textColor)
        //textPaint.setTextSize(myFont.fontSize)
        //textPaint.setTypeface(myFont.typeface)

        for i in 0..<glyphs.count {
            //let textStr = myFont.getGlyphString(glyphs[i])
            canvas.save()
            canvas.translateBy(x: 0.0, y: CGFloat(offsets[i]))
            canvas.scaleBy(x: 1.0, y: -1.0)
            try! drawer.drawGlyph(canvas: canvas, gid: glyphs[i], x: 0.0, y: 0.0)

            //canvas.drawText(textStr, 0.0, 0.0, textPaint)
            canvas.restore()
        }

        canvas.restore()
    }

    override var ascent: Float {
        get {
            return super.ascent - self.shiftDown
        }
        set {
            super.ascent = newValue
        }
    }

    override var descent: Float {
        get {
            return super.descent + self.shiftDown
        }
        set {
            super.descent = newValue
        }
    }
}

// MTLargeOpLimitsDisplay
class MTLargeOpLimitsDisplay: MTDisplay {
    let nucleus: MTDisplay
    var upperLimit: MTMathListDisplay?
    var lowerLimit: MTMathListDisplay?
    var limitShift: Float
    var extraPadding: Float

    init(nucleus: MTDisplay, upperLimit: MTMathListDisplay?, lowerLimit: MTMathListDisplay?, limitShift: Float, extraPadding: Float) {
        self.nucleus = nucleus
        self.upperLimit = upperLimit
        self.lowerLimit = lowerLimit
        self.limitShift = limitShift
        self.extraPadding = extraPadding

        var maxWidth = nucleus.width
        if let upperLimit = upperLimit {
            maxWidth = max(maxWidth, upperLimit.width)
        }
        if let lowerLimit = lowerLimit {
            maxWidth = max(maxWidth, lowerLimit.width)
        }
        super.init()
        self.width = maxWidth
    }

    override var ascent: Float {
        get {
            if let upperLimit = self.upperLimit {
                return nucleus.ascent + extraPadding + upperLimit.ascent + upperLimitGap + upperLimit.descent
            } else {
                return nucleus.ascent
            }
        }
        set {
        }
    }

    override var descent: Float {
        get {
            if let lowerLimit = self.lowerLimit {
                return nucleus.descent + extraPadding + lowerLimitGap + lowerLimit.descent + lowerLimit.ascent
            } else {
                return nucleus.descent
            }
        }
        set {
        }
    }

    var lowerLimitGap: Float = 0.0 {
        didSet {
            self.updateLowerLimitPosition()
        }
    }

    var upperLimitGap: Float = 0.0 {
        didSet {
            self.updateUpperLimitPosition()
        }
    }

    override func positionChanged() {
        self.updateLowerLimitPosition()
        self.updateUpperLimitPosition()
        self.updateNucleusPosition()
    }

    func updateLowerLimitPosition() {
        if let ll = self.lowerLimit {
            // The position of the lower limit includes the position of the MTLargeOpLimitsDisplay
            // This is to make the positioning of the radical consistent with fractions and radicals
            // Move the starting point to below the nucleus leaving a gap of _lowerLimitGap and subtract
            // the ascent to to get the baseline. Also center and shift it to the left by _limitShift.
            ll.position = MTCGPoint(
                x: position.x - limitShift + (self.width - ll.width) / 2,
                y: position.y - nucleus.descent - lowerLimitGap - ll.ascent
            )
        }
    }

    func updateUpperLimitPosition() {
        if let ul = self.upperLimit {
            // The position of the upper limit includes the position of the MTLargeOpLimitsDisplay
            // This is to make the positioning of the radical consistent with fractions and radicals
            // Move the starting point to above the nucleus leaving a gap of _upperLimitGap and add
            // the descent to to get the baseline. Also center and shift it to the right by _limitShift.
            ul.position = MTCGPoint(
                x: position.x + limitShift + (self.width - ul.width) / 2,
                y: position.y + nucleus.ascent + upperLimitGap + ul.descent
            )
        }
    }

    func updateNucleusPosition() {
        // Center the nucleus
        nucleus.position = MTCGPoint(x: position.x + (self.width - nucleus.width) / 2, y: position.y)
    }

    override func colorChanged() {
        self.nucleus.textColor = self.textColor
        if let ul = self.upperLimit {
            ul.textColor = self.textColor
        }
        if let ll = self.lowerLimit {
            ll.textColor = self.textColor
        }
    }

    override func draw(canvas: GraphicsContext) {
        // Draw the elements.
        upperLimit?.draw(canvas: canvas)
        lowerLimit?.draw(canvas: canvas)
        nucleus.draw(canvas: canvas)
    }
}

// MTLineDisplay  overline or underline
class MTLineDisplay: MTDisplay {
    let inner: MTMathListDisplay
    // How much the line should be moved up.
    var lineShiftUp: Float = 0.0
    var lineThickness: Float = 0.0

    init(inner: MTMathListDisplay, range: NSRange) {
        self.inner = inner
        super.init(range: range)
    }

    override func colorChanged() {
        self.inner.textColor = self.textColor
    }

    override func draw(canvas: GraphicsContext) {
        var canvas = canvas
        self.inner.draw(canvas: canvas)

        if lineThickness != 0 {
//            let strokePaint = createPlatformPaint()
//            strokePaint.isAntiAlias = true
//            strokePaint.color = Color(textColor)
//            strokePaint.strokeWidth = lineThickness
            canvas.drawLine(
                x1: position.x,
                y1: position.y + lineShiftUp,
                x2: position.x + width,
                y2: position.y + lineShiftUp,
                lineWidth: lineThickness,
                color: textColor
            )
        }
    }

    override func positionChanged() {
        self.updateInnerPosition()
    }

    func updateInnerPosition() {
        self.inner.position = MTCGPoint(x: self.position.x, y: self.position.y)
    }
}


// MTAccentDisplay
class MTAccentDisplay: MTDisplay {
    let accent: MTGlyphDisplay
    let accentDisplay: MTMathListDisplay

    init(accent: MTGlyphDisplay, accentDisplay: MTMathListDisplay, range: NSRange) {
        self.accent = accent
        self.accentDisplay = accentDisplay
        super.init(range: range)
        self.accentDisplay.position = MTCGPoint()
        super.range = range.copy()
    }

    override func colorChanged() {
        self.accentDisplay.textColor = self.textColor
        self.accent.textColor = self.textColor
    }

    override func positionChanged() {
        self.updateAccentPosition()
    }

    func updateAccentPosition() {
        self.accentDisplay.position = MTCGPoint(x: self.position.x, y: self.position.y)
    }

    override func draw(canvas: GraphicsContext) {
        var canvas = canvas
        self.accentDisplay.draw(canvas: canvas)

        canvas.save()

        canvas.translateBy(x: CGFloat(position.x), y: CGFloat(position.y))
        self.accent.draw(canvas: canvas)
        canvas.restore()
    }
}
