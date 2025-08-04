import SwiftUI

@main
struct iOSApp: App {
    @State var mathList: MTMathList?
    @State var parseError: MTParseError?
    @State var currentFormula = 0
    
    // Test different types of formulas
    let testFormulas = [
        "\\cos(\\theta + \\varphi) = \\cos(\\theta)\\cos(\\varphi) - \\sin(\\theta)\\sin(\\varphi)",
        "\\frac{a}{b}",
        "\\sqrt{x^2 + y^2}",
        "\\int_0^1 x^2 dx",
        "\\sum_{i=1}^n i^2",
        "x = \\frac{-b \\pm \\sqrt{b^2 - 4ac}}{2a}"
    ]
    
    var body: some Scene {
        WindowGroup {
            VStack {
                Text("KotlinTeX Swift Math Rendering Test")
                    .padding()
                
                // Display current formula
                MTMathView(mathList: mathList, parseError: parseError, fontSize: 24, textColor: .black)
                    .frame(minHeight: 100)
                    .border(Color.gray, width: 1)
                    .padding()
                
                // Show current LaTeX
                Text("LaTeX: \(testFormulas[currentFormula])")
                    .font(.caption)
                    .padding()
                
                // Navigation buttons
                HStack {
                    Button("Previous") {
                        currentFormula = (currentFormula - 1 + testFormulas.count) % testFormulas.count
                        updateFormula()
                    }
                    .disabled(testFormulas.count <= 1)
                    
                    Spacer()
                    
                    Text("\(currentFormula + 1) / \(testFormulas.count)")
                    
                    Spacer()
                    
                    Button("Next") {
                        currentFormula = (currentFormula + 1) % testFormulas.count
                        updateFormula()
                    }
                    .disabled(testFormulas.count <= 1)
                }
                .padding()
                
                // Error display
                if let error = parseError, error.errorCode != .ErrorNone {
                    Text("Parse Error: \(error.errorDesc)")
                        .foregroundColor(.red)
                        .padding()
                }
            }
            .onAppear {
                updateFormula()
            }
        }
    }
    
    private func updateFormula() {
        let result = parseMathList(testFormulas[currentFormula])
        mathList = result.0
        parseError = result.1
    }
}
