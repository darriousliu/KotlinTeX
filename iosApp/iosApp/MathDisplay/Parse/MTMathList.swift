import Foundation

class MTMathList: CustomStringConvertible {
    var atoms = [MTMathAtom]()

    init(_ alist: MTMathAtom...) {
        for atom in alist {
            atoms.append(atom)
        }
    }

    init(alist: [MTMathAtom]) {
        atoms.append(contentsOf: alist)
    }

    private func isAtomAllowed(atom: MTMathAtom) -> Bool {
        return atom.type != .kMTMathAtomBoundary
    }

    func addAtom(_ atom: MTMathAtom) {
        if !isAtomAllowed(atom: atom) {
            let s = MTMathAtom.Factory.shared.typeToText(atom.type)
            fatalError("Cannot add atom of type \(s) in a mathList ")
        }
        atoms.append(atom)
    }

    func insertAtom(_ atom: MTMathAtom, at index: Int) {
        if !isAtomAllowed(atom: atom) {
            let s = MTMathAtom.Factory.shared.typeToText(atom.type)
            fatalError("Cannot add atom of type \(s) in a mathList ")
        }
        atoms.insert(atom, at: index)
    }

    func append(list: MTMathList) {
        atoms.append(contentsOf: list.atoms)
    }

    var description: String {
        var str = ""
        for atom in atoms {
            str += atom.description
        }
        return str
    }

    func finalized() -> MTMathList {
        let newList = MTMathList()
        let zeroRange = NSRange(location: 0, length: 0)

        var prevNode: MTMathAtom? = nil
        for atom in atoms {
            let newNode = atom.finalized()
            var skip = false  // Skip adding this node it has been fused
            // Each character is given a separate index.
            if zeroRange == atom.indexRange {
                let index: Int = prevNode == nil ? 0 : (prevNode!.indexRange.location + prevNode!.indexRange.length)
                newNode.indexRange = NSRange(location: index, length: 1)
            }

            switch newNode.type {
            case .kMTMathAtomBinaryOperator:
                if MTMathAtom.Factory.shared.isNotBinaryOperator(prevNode) {
                    newNode.type = .kMTMathAtomUnaryOperator
                }

            case .kMTMathAtomRelation, .kMTMathAtomPunctuation, .kMTMathAtomClose:
                if let prev = prevNode, prev.type == .kMTMathAtomBinaryOperator {
                    prev.type = .kMTMathAtomUnaryOperator
                }

            case .kMTMathAtomNumber:
                // combine numbers together
                if let prev = prevNode, prev.type == .kMTMathAtomNumber, prev.subScript == nil, prev.superScript == nil {
                    prev.fuse(atom: newNode)
                    // skip the current node, we are done here.
                    skip = true
                }

            default:
                // Do nothing
                break
            }
            if !skip {
                newList.addAtom(newNode)
                prevNode = newNode
            }
        }
        if let prev = prevNode, prev.type == .kMTMathAtomBinaryOperator {
            // it isn't a binary since there is noting after it. Make it a unary
            prev.type = .kMTMathAtomUnaryOperator
        }
        return newList
    }

    func copyDeep() -> MTMathList {
        let newList = MTMathList()
        for atom in atoms {
            newList.addAtom(atom.copyDeep())
        }
        return newList
    }
}
