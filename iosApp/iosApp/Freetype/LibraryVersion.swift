import Foundation

struct LibraryVersion: CustomStringConvertible {
    let major: Int
    let minor: Int // Example: 2.6.0
    let patch: Int
    
    var description: String {
        "\(major).\(minor).\(patch)"
    }
}
