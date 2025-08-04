import SwiftUI

@main
struct iOSApp: App {
    var body: some Scene {
        WindowGroup {
            ZStack {
                // Use the LaTeX string version for simpler usage
                MTMathViewLatex(
                    latex: "\\cos(\\theta + \\varphi) = \\cos(\\theta)\\cos(\\varphi) - \\sin(\\theta)\\sin(\\varphi)",
                    fontSize: 20,
                    textColor: .black,
                    displayErrorInline: true
                )
            }
        }
    }
}
