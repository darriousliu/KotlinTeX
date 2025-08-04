import Foundation
/*
  greg@agog.com

  Read the math table from a opentype font and create tables ready for typesetting math.
  freetype doesn't supply a library call to parse this table.
  The whole table is retrieved as a bytearray and then parsed in kotlin


  Best reference I've found for math table format
  https://docs.microsoft.com/en-us/typography/opentype/spec/math


 */
private let constTable = [
    "int16", "ScriptPercentScaleDown",
    "int16", "ScriptScriptPercentScaleDown",
    "uint16", "DelimitedSubFormulaMinHeight",
    "uint16", "DisplayOperatorMinHeight",
    "MathValueRecord", "MathLeading",
    "MathValueRecord", "AxisHeight",
    "MathValueRecord", "AccentBaseHeight",
    "MathValueRecord", "FlattenedAccentBaseHeight",
    "MathValueRecord", "SubscriptShiftDown",
    "MathValueRecord", "SubscriptTopMax",
    "MathValueRecord", "SubscriptBaselineDropMin",
    "MathValueRecord", "SuperscriptShiftUp",
    "MathValueRecord", "SuperscriptShiftUpCramped",
    "MathValueRecord", "SuperscriptBottomMin",
    "MathValueRecord", "SuperscriptBaselineDropMax",
    "MathValueRecord", "SubSuperscriptGapMin",
    "MathValueRecord", "SuperscriptBottomMaxWithSubscript",
    "MathValueRecord", "SpaceAfterScript",
    "MathValueRecord", "UpperLimitGapMin",
    "MathValueRecord", "UpperLimitBaselineRiseMin",
    "MathValueRecord", "LowerLimitGapMin",
    "MathValueRecord", "LowerLimitBaselineDropMin",
    "MathValueRecord", "StackTopShiftUp",
    "MathValueRecord", "StackTopDisplayStyleShiftUp",
    "MathValueRecord", "StackBottomShiftDown",
    "MathValueRecord", "StackBottomDisplayStyleShiftDown",
    "MathValueRecord", "StackGapMin",
    "MathValueRecord", "StackDisplayStyleGapMin",
    "MathValueRecord", "StretchStackTopShiftUp",
    "MathValueRecord", "StretchStackBottomShiftDown",
    "MathValueRecord", "StretchStackGapAboveMin",
    "MathValueRecord", "StretchStackGapBelowMin",
    "MathValueRecord", "FractionNumeratorShiftUp",
    "MathValueRecord", "FractionNumeratorDisplayStyleShiftUp",
    "MathValueRecord", "FractionDenominatorShiftDown",
    "MathValueRecord", "FractionDenominatorDisplayStyleShiftDown",
    "MathValueRecord", "FractionNumeratorGapMin",
    "MathValueRecord", "FractionNumDisplayStyleGapMin",
    "MathValueRecord", "FractionRuleThickness",
    "MathValueRecord", "FractionDenominatorGapMin",
    "MathValueRecord", "FractionDenomDisplayStyleGapMin",
    "MathValueRecord", "SkewedFractionHorizontalGap",
    "MathValueRecord", "SkewedFractionVerticalGap",
    "MathValueRecord", "OverbarVerticalGap",
    "MathValueRecord", "OverbarRuleThickness",
    "MathValueRecord", "OverbarExtraAscender",
    "MathValueRecord", "UnderbarVerticalGap",
    "MathValueRecord", "UnderbarRuleThickness",
    "MathValueRecord", "UnderbarExtraDescender",
    "MathValueRecord", "RadicalVerticalGap",
    "MathValueRecord", "RadicalDisplayStyleVerticalGap",
    "MathValueRecord", "RadicalRuleThickness",
    "MathValueRecord", "RadicalExtraAscender",
    "MathValueRecord", "RadicalKernBeforeDegree",
    "MathValueRecord", "RadicalKernAfterDegree",
    "uint16", "RadicalDegreeBottomRaisePercent"
]

class MTFreeTypeMathTable {
    let pointer: Int
    let data: NativeBinaryBuffer
    private var constants: [String: Int] = [:]
    private var italicscorrectioninfo: [Int: Int] = [:]
    private var topaccentattachment: [Int: Int] = [:]
    private var vertglyphconstruction: [Int: MathGlyphConstruction] = [:]
    private var horizglyphconstruction: [Int: MathGlyphConstruction] = [:]
    var minConnectorOverlap: Int = 0

    init(pointer: Int, data: NativeBinaryBuffer) {
        self.pointer = pointer
        self.data = data
        let i = data.remaining()
        let success = FreeType.loadMathTable1(pointer, data: data, length: data.remaining())

        if success {
            let version = data.int
            if version == 0x00010000 {
                let mathConstantsOffset = getDataSInt()
                let mathGlyphInfoOffset = getDataSInt()
                let mathVariantsOffset = getDataSInt()
                //println("MathConstants \(MathConstants) MathGlyphInfo \(MathGlyphInfo) MathVariants \(MathVariants)")
                readConstants(foffset: mathConstantsOffset)

                // Glyph Info Table
                data.position(mathGlyphInfoOffset)
                let mathItalicsCorrectionInfo = getDataSInt()
                let mathTopAccentAttachment = getDataSInt()
                //let extendedShapeCoverage = getDataSInt()

                // This is unused
                //let mathKernInfo = getDataSInt()

                readMatchedTable(foffset: mathGlyphInfoOffset + mathItalicsCorrectionInfo, table: &italicscorrectioninfo)
                readMatchedTable(foffset: mathGlyphInfoOffset + mathTopAccentAttachment, table: &topaccentattachment)

                readVariants(foffset: mathVariantsOffset)
            }
        }
    }

    private func getDataSInt() -> Int {
        let v = Int(data.short)
        return v
    }

    func getConstant(name: String) -> Int {
        return constants[name]!
    }

    func getItalicCorrection(gid: Int) -> Int {
        return italicscorrectioninfo[gid] ?? 0
    }

    func getTopAccentAttachment(gid: Int) -> Int? {
        return topaccentattachment[gid]
    }

    private func getVariantsForGlyph(construction: [Int: MathGlyphConstruction], gid: Int) -> [Int] {
        guard let v = construction[gid], !v.variants.isEmpty else {
            return [gid]
        }
        return v.variants.map {
            $0.variantGlyph
        }
    }

    func getVerticalVariantsForGlyph(gid: Int) -> [Int] {
        return getVariantsForGlyph(construction: vertglyphconstruction, gid: gid)
    }

    func getHorizontalVariantsForGlyph(gid: Int) -> [Int] {
        return getVariantsForGlyph(construction: horizglyphconstruction, gid: gid)
    }

    func getVerticalGlyphAssemblyForGlyph(gid: Int) -> [GlyphPartRecord]? {
        return vertglyphconstruction[gid]?.assembly?.partRecords
    }

    private func getDataRecord() -> Int {
        let value = getDataSInt()
        _ = getDataSInt() // deviceTable
        return value
    }

    // Read either a correction or offset table that has a table of glyphs covered that correspond
    // to an array of MathRecords of the values
    private func readMatchedTable(foffset: Int, table: inout [Int: Int]) {
        data.position(foffset)
        let coverageOffset = getDataSInt()
        let coverage = readCoverageTable(foffset: foffset + coverageOffset)
        let count = getDataSInt()
        for i in 0..<count {
            table[coverage[i]] = getDataRecord()
        }
    }

    private func readConstants(foffset: Int) {
        data.position(foffset)
        var i = 0
        while i < constTable.count {
            let recordType = constTable[i]
            let recordName = constTable[i + 1]
            switch recordType {
            case "uint16", "int16":
                let value = getDataSInt()
                constants[recordName] = value
            default:
                let value = getDataSInt()
                _ = getDataSInt() // offset
                constants[recordName] = value
            }
            i += 2
        }
    }

    // https://docs.microsoft.com/en-us/typography/opentype/spec/chapter2
    /*
        Read an array of glyph ids
     */
    private func readCoverageTable(foffset: Int) -> [Int] {
        let currentPosition = data.getPosition()
        data.position(foffset)
        let format = getDataSInt()
        var ra: [Int]?

        switch format {
        case 1:
            let glyphCount = getDataSInt()
            ra = (0..<glyphCount).map { _ in
                getDataSInt()
            }
        case 2:
            let rangeCount = getDataSInt()
            var rr = [Int]()
            for _ in 0..<rangeCount {
                let startGlyphID = getDataSInt()
                let endGlyphID = getDataSInt()
                var startCoverageIndex = getDataSInt()
                for g in startGlyphID...endGlyphID {
                    rr.append(startCoverageIndex)
                    startCoverageIndex += 1
                }
            }
            ra = rr
        default:
            fatalError("Invalid coverage format")
        }

        data.position(currentPosition)
        return ra!
    }

    class MathGlyphConstruction {
        let assembly: GlyphAssembly?
        let variants: [MathGlyphVariantRecord]

        init(assembly: GlyphAssembly?, variants: [MathGlyphVariantRecord]) {
            self.assembly = assembly
            self.variants = variants
        }
    }

    class MathGlyphVariantRecord {
        let variantGlyph: Int
        let advanceMeasurement: Int

        init(variantGlyph: Int, advanceMeasurement: Int) {
            self.variantGlyph = variantGlyph
            self.advanceMeasurement = advanceMeasurement
        }
    }

    class GlyphPartRecord {
        let glyph: Int
        let startConnectorLength: Int
        let endConnectorLength: Int
        let fullAdvance: Int
        let partFlags: Int

        init(glyph: Int, startConnectorLength: Int, endConnectorLength: Int, fullAdvance: Int, partFlags: Int) {
            self.glyph = glyph
            self.startConnectorLength = startConnectorLength
            self.endConnectorLength = endConnectorLength
            self.fullAdvance = fullAdvance
            self.partFlags = partFlags
        }
    }

    class GlyphAssembly {
        let italicsCorrection: Int
        let partRecords: [GlyphPartRecord]

        init(italicsCorrection: Int, partRecords: [GlyphPartRecord]) {
            self.italicsCorrection = italicsCorrection
            self.partRecords = partRecords
        }
    }

    private func readConstruction(foffset: Int) -> MathGlyphConstruction {
        let currentPosition = data.getPosition()
        data.position(foffset)

        let glyphAssemblyOff = getDataSInt()
        let variantCount = getDataSInt()
        var variants = [MathGlyphVariantRecord]()
        for _ in 0..<variantCount {
            let variantGlyph = getDataSInt()
            let advanceMeasurement = getDataSInt()
            variants.append(MathGlyphVariantRecord(variantGlyph: variantGlyph, advanceMeasurement: advanceMeasurement))
        }
        let assembly = glyphAssemblyOff == 0 ? nil : readAssembly(foffset: foffset + glyphAssemblyOff)
        let construction = MathGlyphConstruction(assembly: assembly, variants: variants)
        data.position(currentPosition)
        return construction
    }

    private func readAssembly(foffset: Int) -> GlyphAssembly {
        let currentPosition = data.getPosition()
        data.position(foffset)

        let italicsCorrection = getDataRecord()
        let partCount = getDataSInt()
        var parts = [GlyphPartRecord]()
        for _ in 0..<partCount {
            let glyph = getDataSInt()
            let startConnectorLength = getDataSInt()
            let endConnectorLength = getDataSInt()
            let fullAdvance = getDataSInt()
            let partFlags = getDataSInt()
            parts.append(GlyphPartRecord(glyph: glyph, startConnectorLength: startConnectorLength, endConnectorLength: endConnectorLength, fullAdvance: fullAdvance, partFlags: partFlags))
        }
        let assembly = GlyphAssembly(italicsCorrection: italicsCorrection, partRecords: parts)
        data.position(currentPosition)
        return assembly
    }

    private func readVariants(foffset: Int) {
        data.position(foffset)

        self.minConnectorOverlap = getDataSInt()
        let vertGlyphCoverage = getDataSInt()
        let horizGlyphCoverage = getDataSInt()
        let vertGlyphCount = getDataSInt()
        let horizGlyphCount = getDataSInt()

        let vertCoverage = readCoverageTable(foffset: foffset + vertGlyphCoverage)
        let horizCoverage = readCoverageTable(foffset: foffset + horizGlyphCoverage)

        for g in 0..<vertGlyphCount {
            let glyphConstruction = getDataSInt()
            vertglyphconstruction[vertCoverage[g]] = readConstruction(foffset: foffset + glyphConstruction)
        }

        for g in 0..<horizGlyphCount {
            let glyphConstruction = getDataSInt()
            horizglyphconstruction[horizCoverage[g]] = readConstruction(foffset: foffset + glyphConstruction)
        }
    }
}
