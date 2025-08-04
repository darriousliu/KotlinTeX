/**
@typedef MTColumnAlignment
@brief Alignment for a column of MTMathTable
 */
enum MTColumnAlignment {
    /// Align left.
    case KMTColumnAlignmentLeft

    /// Align center.
    case KMTColumnAlignmentCenter

    /// Align right.
    case KMTColumnAlignmentRight
}

class MTMathTable: MTMathAtom {

    private var alignments: [MTColumnAlignment] = []

    // 2D variable size array of MathLists
    var cells: [[MTMathList]] = []

    /// The name of the environment that this table denotes.
    var environment: String? = nil

    /// Spacing between each column in mu units.
    var interColumnSpacing: Float = 0.0

    /// Additional spacing between rows in jots (one jot is 0.3 times font size).
    /// If the additional spacing is 0, then normal row spacing is used are used.
    var interRowAdditionalSpacing: Float = 0.0

    init(env: String? = nil) {
        self.environment = env
        super.init(type: .kMTMathAtomTable, nucleus: "")
    }

    override func copyDeep() -> MTMathTable {
        let atom = MTMathTable(env: self.environment)
        super.copyDeepContent(atom: atom)

        atom.alignments = Array(self.alignments)

        atom.cells = []
        for row in self.cells {
            var newRow: [MTMathList] = []
            for i in 0..<row.count {
                let newCol = row[i].copyDeep()
                newRow.append(newCol)
            }
            atom.cells.append(newRow)
        }

        atom.interColumnSpacing = self.interColumnSpacing
        atom.interRowAdditionalSpacing = self.interRowAdditionalSpacing

        return atom
    }

    override func finalized() -> MTMathTable {
        let newMathTable = self.copyDeep()
        super.finalized(newNode: newMathTable)
        for var row in newMathTable.cells {
            for i in 0..<row.count {
                row[i] = row[i].finalized()
            }
        }
        return newMathTable
    }

    func setCell(_ list: MTMathList, row: Int, column: Int) {
        if self.cells.count <= row {
            // Add more rows
            var i = self.cells.count
            while i <= row {
                self.cells.insert([], at: i)
                i += 1
            }
        }
        var rowArray = self.cells[row]
        if rowArray.count <= column {
            // Add more columns
            var i = rowArray.count
            while i <= column {
                rowArray.insert(MTMathList(), at: i)
                i += 1
            }
        }
        rowArray[column] = list
        self.cells[row] = rowArray
    }

    func setAlignment(_ alignment: MTColumnAlignment, column: Int) {
        if self.alignments.count <= column {
            // Add more columns
            var i = self.alignments.count
            while i <= column {
                self.alignments.append(.KMTColumnAlignmentCenter)
                i += 1
            }
        }
        self.alignments[column] = alignment
    }

    func getAlignmentForColumn(_ column: Int) -> MTColumnAlignment {
        if self.alignments.count <= column {
            return .KMTColumnAlignmentCenter
        } else {
            return self.alignments[column]
        }
    }

    func numColumns() -> Int {
        var numColumns = 0
        for row in self.cells {
            numColumns = max(numColumns, row.count)
        }
        return numColumns
    }

    func numRows() -> Int {
        return self.cells.count
    }
}
