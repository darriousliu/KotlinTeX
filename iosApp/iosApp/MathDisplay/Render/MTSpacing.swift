import Foundation

/**
 * Created by greg on 3/13/18.
 */

enum MTInterElementSpaceType: Comparable {
    case KMTSpaceInvalid
    case KMTSpaceNone
    case KMTSpaceThin
    case KMTSpaceNSThin   // Thin but not in script mode
    case KMTSpaceNSMedium
    case KMTSpaceNSThick
}

let interElementSpaceArray: [[MTInterElementSpaceType]] = [
    //   ordinary             operator             binary               relation            open                 close               punct               // fraction
    [
        .KMTSpaceNone,
        .KMTSpaceThin,
        .KMTSpaceNSMedium,
        .KMTSpaceNSThick,
        .KMTSpaceNone,
        .KMTSpaceNone,
        .KMTSpaceNone,
        .KMTSpaceNSThin
    ], // ordinary
    [
        .KMTSpaceThin,
        .KMTSpaceThin,
        .KMTSpaceInvalid,
        .KMTSpaceNSThick,
        .KMTSpaceNone,
        .KMTSpaceNone,
        .KMTSpaceNone,
        .KMTSpaceNSThin
    ], // operator
    [
        .KMTSpaceNSMedium,
        .KMTSpaceNSMedium,
        .KMTSpaceInvalid,
        .KMTSpaceInvalid,
        .KMTSpaceNSMedium,
        .KMTSpaceInvalid,
        .KMTSpaceInvalid,
        .KMTSpaceNSMedium
    ], // binary
    [
        .KMTSpaceNSThick,
        .KMTSpaceNSThick,
        .KMTSpaceInvalid,
        .KMTSpaceNone,
        .KMTSpaceNSThick,
        .KMTSpaceNone,
        .KMTSpaceNone,
        .KMTSpaceNSThick
    ], // relation
    [
        .KMTSpaceNone,
        .KMTSpaceNone,
        .KMTSpaceInvalid,
        .KMTSpaceNone,
        .KMTSpaceNone,
        .KMTSpaceNone,
        .KMTSpaceNone,
        .KMTSpaceNone
    ], // open
    [
        .KMTSpaceNone,
        .KMTSpaceThin,
        .KMTSpaceNSMedium,
        .KMTSpaceNSThick,
        .KMTSpaceNone,
        .KMTSpaceNone,
        .KMTSpaceNone,
        .KMTSpaceNSThin
    ], // close
    [
        .KMTSpaceNSThin,
        .KMTSpaceNSThin,
        .KMTSpaceInvalid,
        .KMTSpaceNSThin,
        .KMTSpaceNSThin,
        .KMTSpaceNSThin,
        .KMTSpaceNSThin,
        .KMTSpaceNSThin
    ], // punct
    [
        .KMTSpaceNSThin,
        .KMTSpaceThin,
        .KMTSpaceNSMedium,
        .KMTSpaceNSThick,
        .KMTSpaceNSThin,
        .KMTSpaceNone,
        .KMTSpaceNSThin,
        .KMTSpaceNSThin
    ], // fraction
    [
        .KMTSpaceNSMedium,
        .KMTSpaceNSThin,
        .KMTSpaceNSMedium,
        .KMTSpaceNSThick,
        .KMTSpaceNone,
        .KMTSpaceNone,
        .KMTSpaceNone,
        .KMTSpaceNSThin
    ] // radical
]

// Get's the index for the given type. If row is true, the index is for the row (i.e. left element) otherwise it is for the column (right element)
func getInterElementSpaceArrayIndexForType(type: MTMathAtomType, row: Bool) throws -> Int {
    switch type {
        // A placeholder is treated as ordinary
    case .kMTMathAtomColor, .kMTMathAtomTextColor, .kMTMathAtomOrdinary, .kMTMathAtomPlaceholder:
        return 0
    case .kMTMathAtomLargeOperator:
        return 1
    case .kMTMathAtomBinaryOperator:
        return 2
    case .kMTMathAtomRelation:
        return 3
    case .kMTMathAtomOpen:
        return 4
    case .kMTMathAtomClose:
        return 5
    case .kMTMathAtomPunctuation:
        return 6
    case .kMTMathAtomFraction, .kMTMathAtomInner:
        return 7
    case .kMTMathAtomRadical:
        if row {
            // Radicals have inter element spaces only when on the left side.
            // Note: This is a departure from latex but we don't want \sqrt{4}4 to look weird so we put a space in between.
            // They have the same spacing as ordinary except with ordinary.
            return 8
        } else {
            throw MathDisplayException("Interelement space undefined for radical on the right. Treat radical as ordinary.")
        }
    default:
        throw MathDisplayException("Interelement space undefined for type \(type)")
    }
}
