import SwiftUI

@main
struct iOSApp: App {
    var body: some Scene {
        WindowGroup {
            VStack(spacing: 20) {
                Text("KotlinTeX Swift Test")
                    .font(.title2)
                    .padding()
                
                ScrollView {
                    VStack(spacing: 15) {
                        // Test different formulas to verify width/height calculations
                        ForEach(testFormulas, id: \.self) { formula in
                            VStack(alignment: .leading, spacing: 5) {
                                Text("LaTeX: \(formula)")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                
                                MTMathViewLatex(
                                    latex: formula,
                                    fontSize: 20,
                                    textColor: .black,
                                    displayErrorInline: true
                                )
                                .border(Color.blue, width: 1) // Border to visualize bounds
                            }
                            .padding(.horizontal)
                        }
                    }
                }
            }
        }
    }
}

// Test formulas to verify the fix
private let testFormulas = [
    "\\cos(\\theta + \\varphi) = \\cos(\\theta)\\cos(\\varphi) - \\sin(\\theta)\\sin(\\varphi)",
    "\\frac{a}{b}",
    "\\sqrt{x^2 + y^2}",
    "\\int_0^1 x^2 dx",
    "\\sum_{i=1}^n i^2",
    "x = \\frac{-b \\pm \\sqrt{b^2 - 4ac}}{2a}"
]
