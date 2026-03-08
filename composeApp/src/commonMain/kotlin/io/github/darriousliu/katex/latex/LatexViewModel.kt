package io.github.darriousliu.katex.latex

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import io.github.darriousliu.katex.core.MathItem
import io.github.darriousliu.katex.mathdisplay.parse.MTLineStyle
import io.github.darriousliu.katex.mathdisplay.parse.MTMathList
import io.github.darriousliu.katex.mathdisplay.parse.MTMathListBuilder
import io.github.darriousliu.katex.mathdisplay.parse.MTParseError
import io.github.darriousliu.katex.mathdisplay.parse.MTParseErrors
import io.github.darriousliu.katex.mathdisplay.render.MTFontManager
import io.github.darriousliu.katex.mathdisplay.render.MTTypesetter
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.launch
import org.koin.android.annotation.KoinViewModel
import kotlin.random.Random


@KoinViewModel
class LatexViewModel : ViewModel() {
    val mathItems = MutableStateFlow(emptyList<MathItem>())
    val mathList = MutableStateFlow(emptyList<MTMathList>())
    val latexList = MutableStateFlow(emptyList<String>())
    val font = MTFontManager.defaultFont().copyFontWithSize(60f) // 使用固定大小预计算

    fun parseMathItems() {
        viewModelScope.launch(Dispatchers.Default) {
            mathItems.value = SAMPLE_LATEX.mapNotNull { latex ->
                if (latex.isNotEmpty()) {
                    val newParseError = MTParseError()
                    val list = MTMathListBuilder.buildFromString(latex, newParseError)
                    if (list != null && newParseError.errorCode == MTParseErrors.ErrorNone) {
                        val displayList = MTTypesetter.createLineForMathList(
                            list,
                            font,
                            MTLineStyle.KMTLineStyleDisplay
                        )
                        MathItem(
                            displayList = displayList,
                            width = displayList.width,
                            height = displayList.ascent + displayList.descent,
                            latex = latex
                        )
                    } else null

                } else {
                    null
                }
            }
        }
    }

    fun parseMathList() {
        viewModelScope.launch(Dispatchers.Default) {
            mathList.value = SAMPLE_LATEX.mapNotNull { latex ->
                if (latex.isNotEmpty()) {
                    val newParseError = MTParseError()
                    val list = MTMathListBuilder.buildFromString(latex, newParseError)
                    if (list != null && newParseError.errorCode == MTParseErrors.ErrorNone) {
                        list
                    } else null
                } else {
                    null
                }
            }
        }
    }

    fun parseLatexList() {
        viewModelScope.launch(Dispatchers.Default) {
            latexList.value = SAMPLE_LATEX.filter { it.isNotBlank() && !it.startsWith("#") }
                .distinct()
                .map { it.trim() }
        }
    }
}

private val SAMPLE_LATEX = """
#
# Sample lines of Latex from raw/samples.txt
# Empty lines are ignored lines
# Lines starting with # displayed in TextViews
#
x = \frac{-b \pm \sqrt{b^2-4ac}}{2a}

\color{#ff3399}{(a_1+a_2)^2}=a_1^2+2a_1a_2+a_2^2

\cos(\theta + \varphi) = \cos(\theta)\cos(\varphi) - \sin(\theta)\sin(\varphi)

\frac{1}{\left(\sqrt{\phi \sqrt{5}}-\phi\right) e^{\frac25 \pi}} = 1+\frac{e^{-2\pi}} {1 +\frac{e^{-4\pi}} {1+\frac{e^{-6\pi}} {1+\frac{e^{-8\pi}} {1+\cdots} } } }

\sigma = \sqrt{\frac{1}{N}\sum_{i=1}^N (x_i - \mu)^2}

\neg(P\land Q) \iff (\neg P)\lor(\neg Q)

\log_b(x) = \frac{\log_a(x)}{\log_a(b)}

\lim_{x\to\infty}\left(1 + \frac{k}{x}\right)^x = e^k

\int_{-\infty}^\infty \! e^{-x^2} dx = \sqrt{\pi}

\frac 1 n \sum_{i=1}^{n}x_i \geq \sqrt[n]{\prod_{i=1}^{n}x_i}

f^{(n)}(z_0) = \frac{n!}{2\pi i}\oint_\gamma\frac{f(z)}{(z-z_0)^{n+1}}\,dz

i\hbar\frac{\partial}{\partial t}\mathbf\Psi(\mathbf{x},t) = -\frac{\hbar}{2m}\nabla^2\mathbf\Psi(\mathbf{x},t) + V(\mathbf{x})\mathbf\Psi(\mathbf{x},t)
    
\left(\sum_{k=1}^n a_k b_k \right)^2 \le \left(\sum_{k=1}^n a_k^2\right)\left(\sum_{k=1}^n b_k^2\right)
    
{n \brace k} = \frac{1}{k!}\sum_{j=0}^k (-1)^{k-j}\binom{k}{j}(k-j)^n

f(x) = \int\limits_{-\infty}^\infty\!\hat f(\xi)\,e^{2 \pi i \xi x}\,\mathrm{d}\xi

\begin{gather} \dot{x} = \sigma(y-x) \\ \dot{y} = \rho x - y - xz \\ \dot{z} = -\beta z + xy \end{gather}

\vec \bf V_1 \times \vec \bf V_2 =  \begin{vmatrix} \hat \imath &\hat \jmath &\hat k \\ \frac{\partial X}{\partial u} &  \frac{\partial Y}{\partial u} & 0 \\ \frac{\partial X}{\partial v} &  \frac{\partial Y}{\partial v} & 0 \end{vmatrix}

\begin{eqalign} \nabla \cdot \vec{\bf{E}} & = \frac {\rho} {\varepsilon_0} \\ \nabla \cdot \vec{\bf{B}} & = 0 \\ \nabla \times \vec{\bf{E}} &= - \frac{\partial\vec{\bf{B}}}{\partial t} \\ \nabla \times \vec{\bf{B}} & = \mu_0\vec{\bf{J}} + \mu_0\varepsilon_0 \frac{\partial\vec{\bf{E}}}{\partial t} \end{eqalign}

\begin{pmatrix} a & b\\ c & d \end{pmatrix} \begin{pmatrix} \alpha & \beta \\ \gamma & \delta \end{pmatrix} =  \begin{pmatrix} a\alpha + b\gamma & a\beta + b \delta \\ c\alpha + d\gamma & c\beta + d \delta  \end{pmatrix}

\frak Q(\lambda,\hat{\lambda}) =  -\frac{1}{2} \mathbb P(O \mid \lambda ) \sum_s \sum_m \sum_t \gamma_m^{(s)} (t) +\\  \quad \left( \log(2 \pi ) + \log \left| \cal C_m^{(s)} \right| +  \left( o_t - \hat{\mu}_m^{(s)} \right) ^T \cal C_m^{(s)-1} \right)

f(x) = \begin{cases} \frac{e^x}{2} & x \geq 0 \\ 1 & x < 0 \end{cases}
    
\color{#ff3333}{c}\color{#9933ff}{o}\color{#ff0080}{l}+\color{#99ff33}{\frac{\color{#ff99ff}{o}}{\color{#990099}{r}}}-\color{#33ffff}{\sqrt[\color{#3399ff}{e}]{\color{#3333ff}{d}}}


# Test formula
3+2-5 = 0

# Infix and prefix Operators
12+-3 > +14

# Punct, parens
(-3-5=-8, -6-7=-13)

# Latex commands
5\times(-2 \div 1) = -10
-h - (5xy+2) = z

# Text mode fraction
\frac12x + \frac{3\div4}2y = 25

# Fractions. Compare difference of change display/text in Mode menu
\frac{x+\frac{12}{5}}{y}+\frac1z = \frac{xz+y+\frac{12}{5}z}{yz}

# Exponents and subscripts
\frac{x^{2+3y}}{x^{2+4y}} = x^y \times \frac{z_1^{y+1}}{z_1^{y+1}}

# Prime notation (f' = f^{\prime})
f'(x) = \lim_{h \to 0} \frac{f(x+h) - f(x)}{h}

# Square root
5+\sqrt{2}+3

# Square root inside square roots and with fractions
\sqrt{\frac{\sqrt{\frac{1}{2}} + 3}{\sqrt5^x}}+\sqrt{3x}+x^{\sqrt2}

# General root
\sqrt[3]{24} + 3\sqrt{2}24

# Fractions and formulae in root
\sqrt[x+\frac{3}{4}]{\frac{2}{4}+1}

# Non-symbol operators with no limits
\sin^2(\theta)=\log_3^2(\pi)

# Non-symbol operators with limits
\lim_{x\to\infty}\frac{e^2}{1-x}=\limsup_{\sigma}5

# Symbol operators with limits
\sum_{n=1}^{\infty}\frac{1+n}{1-n}=\bigcup_{A\in\Im}C\cup B

# Symbol operators with limits text style
\sum_{n=1}^{\infty}\frac{1+n}{1-n}=\bigcup_{A\in\Im}C\cup B

# Non-symbol operators with limits text style
\lim_{x\to\infty}\frac{e^2}{1-x}=\limsup_{\sigma}5

# Symbol operators with no limits
\int_{0}^{\infty}e^x \,dx=\oint_0^{\Delta}5\Gamma

# Test italic correction for large ops
\int\int\int^{\infty}\int_0\int^{\infty}_0\int

# Test italic correction for superscript/subscript
U_3^2UY_3^2U_3Y^2f_1f^2ff

#   Inline error display below
\notacommand
\sqrt{1}
\sqrt[|]{1}
{n \choose k}
{n \choose k}
\left({n \atop k}\right)
\left({n \atop k}\right)
\underline{xyz}+\overline{abc}
\underline{\frac12}+\overline{\frac34}
\underline{x^\overline{y}_\overline{z}+5}
    
# spacing examples from the TeX book
\int\!\!\!\int_D dx\,dy

# no spacing
\int\int_D dxdy
y\,dx-x\,dy
y dx - x dy
    
# large spaces
hello\ from \quad the \qquad other\ side

# Accents
\vec x \; \hat y \; \breve {x^2} \; \tilde x \tilde x^2 x^2 
\hat{xyz} \; \widehat{xyz}\; \vec{2ab}
\hat{\frac12} \; \hat{\sqrt 3}

# large roots
\sqrt{1+\sqrt{1+\sqrt{1+\sqrt{1+\sqrt{1+\cdots}}}}}
    
\begin{bmatrix} a & b\\ c & d \\ e & f \\ g &  h \\ i & j \end{bmatrix}
x{\scriptstyle y}z
x \mathrm x \mathbf x \mathcal X \mathfrak x \mathsf x \bm x \mathtt x \mathit \Lambda \cal g
\mathrm{using\ mathrm}
\text{using text}
\text{Mary has }\$500 + \$200.

a = \begin{cases} \nabla \cdot \mathbf{E} = \frac{\rho}{\epsilon_0} \end{cases}

\nabla \cdot \mathbf{E} = \frac{\rho}{\epsilon_0}

\diamond = \frac{1}{2} \sqrt{3} a^2

# surd
\surd{2} + \surd{3} = \surd{5}

# cbrt
\cbrt{8} + \cbrt{27} = \cbrt{35}

# angle
\angle ABC = 90^\degree 90^\circ

# square
\square{2} + \square{3} = \square{5}
\blacksquare{2} + \blacksquare{3} = \blacksquare{5}

# box
\Box{2} + \Box{3} = \Box{5}
\boxed{2} + \boxed{3} = \boxed{5}

f(x) &= \frac{1}{\sqrt{2\pi\sigma^2}} \int_{-\infty}^{\infty} e^{-\frac{(t - \mu)^2}{2\sigma^2}} \, dt \\&= \text{Some explanation here}

""".lines()
    .filter { !it.startsWith("#") && it.isNotBlank() }
    .distinct()

// Function to generate a random LaTeX formula with variety
fun generateRandomFormula(index: Int): String {
    val rand = Random(index) // Seed with index for reproducibility
    val category = rand.nextInt(20) // 20 categories for diversity

    val a = rand.nextInt(1, 20)
    val b = rand.nextInt(1, 20)
    val n = rand.nextInt(2, 5)
    val varName = listOf("x", "y", "z", "a", "b")[rand.nextInt(5)]
    val greek = listOf("\\alpha", "\\beta", "\\gamma", "\\delta", "\\epsilon")[rand.nextInt(5)]
    val symbol = listOf("\\infty", "\\partial", "\\nabla", "\\forall", "\\exists")[rand.nextInt(5)]
    val color = listOf("red", "blue", "green", "black")[rand.nextInt(4)]
    val size = listOf("\\tiny", "\\small", "\\large", "\\huge")[rand.nextInt(4)]
    val style = listOf("\\mathbf", "\\mathit", "\\mathrm", "\\mathsf")[rand.nextInt(4)]

    return when (category) {
        0 -> "\\frac{$a}{$b}"  // Basic fraction
        1 -> "\\sqrt[$n]{${a * index}}"  // Nth root
        2 -> "${varName}^{$a}_{$b}"  // Superscript and subscript
        3 -> "\\int_{$a}^{$b} ${varName} \\, d${varName}"  // Integral
        4 -> "\\sum_{k=1}^{$index} k^2"  // Summation
        5 -> "\\prod_{i=1}^{$a} i"  // Product
        6 -> "\\lim_{${varName} \\to $a} \\frac{${varName} - $a}{${varName}^2}"  // Limit
        7 -> "\\begin{pmatrix} $a & $b \\\\ $b & $a \\end{pmatrix}"  // Matrix
        8 -> "\\begin{cases} $a & \\text{if } ${varName} > 0 \\\\ $b & \\text{otherwise} \\end{cases}"  // Cases
        9 -> "\\begin{align*} ${varName} &= $a + $b \\\\ &= \\sqrt{$a^2 + $b^2} \\end{align*}"  // Aligned equations
        10 -> "$greek + $symbol"  // Greek letters and symbols
        11 -> "\\text{Hello, world! Index: $index}"  // Text in math mode
        12 -> "\\color{$color}{${varName}^{$index}}"  // Colored expression
        13 -> "$size \\{ $a + $b \\}"  // Sized expression
        14 -> "$style \\{ ${varName} \\}"  // Styled text
        15 -> "\\binom{$a}{$b}"  // Binomial coefficient
        16 -> "\\frac{\\partial f}{\\partial ${varName}} = $a ${varName}^{$b-1}"  // Partial derivative
        17 -> "\\vec{${varName}} = \\begin{bmatrix} $a \\\\ $b \\end{bmatrix}"  // Vector
        18 -> "\\left( \\frac{$a}{$b} \\right)^{$index}"  // Delimiters with exponents
        19 -> "\\begin{array}{cc} $a & $b \\\\ \\hline $b & $a \\end{array}"  // Array/table
        else -> "${varName} = $a $symbol $b"  // Fallback simple expression
    }
}

// Generate the list of 1000 diverse LaTeX formulas
val formulas: List<String> = (1..1000).map { i ->
    generateRandomFormula(i)
}

val latexFormulas = listOf(
    // 基础代数
    "x = \\frac{-b \\pm \\sqrt{b^2-4ac}}{2a}",
    "(a + b)^2 = a^2 + 2ab + b^2",
    "\\sum_{i=1}^n i = \\frac{n(n+1)}{2}",

    // 微积分
    "\\frac{d}{dx} \\left( \\int_{a}^{x} f(t) \\, dt \\right) = f(x)",
    "\\iiint_{\\Omega} (\\nabla \\cdot \\mathbf{F}) \\, dV = \\oiint_{\\partial \\Omega} \\mathbf{F} \\cdot d\\mathbf{S}",
    "\\lim_{x \\to 0} \\frac{\\sin x}{x} = 1",

    // 线性代数
    "\\begin{vmatrix} a & b \\\\ c & d \\end{vmatrix} = ad - bc",
    "\\mathbf{A} = \\begin{pmatrix} a_{11} & a_{12} \\\\ a_{21} & a_{22} \\end{pmatrix}",
    "\\text{rank}(A) + \\text{nullity}(A) = n",

    // 概率统计
    "P(A \\mid B) = \\frac{P(B \\mid A) P(A)}{P(B)}",
    "\\sigma = \\sqrt{\\frac{1}{N} \\sum_{i=1}^N (x_i - \\mu)^2}",
    "E[X] = \\int_{-\\infty}^{\\infty} x f(x) \\, dx",

    // 物理公式
    "F = G \\frac{m_1 m_2}{r^2}",
    "\\nabla \\times \\mathbf{E} = -\\frac{\\partial \\mathbf{B}}{\\partial t}",
    "\\psi(x, t) = A e^{i(kx - \\omega t)}",

    // 化学公式
    "\\ce{2H2 + O2 -> 2H2O}",
    "\\ce{CH4 + 2O2 -> CO2 + 2H2O}",
    "\\ce{HA <=> H+ + A-}",

    // 量子力学
    "\\hat{H} \\psi = E \\psi",
    "[\\hat{x}, \\hat{p}] = i \\hbar",
    "\\Delta x \\Delta p \\geq \\frac{\\hbar}{2}",

    // 微分方程
    "\\frac{\\partial^2 u}{\\partial t^2} = c^2 \\nabla^2 u",
    "\\frac{dy}{dx} + P(x)y = Q(x)",
    "\\nabla^2 \\phi = \\frac{1}{c^2} \\frac{\\partial^2 \\phi}{\\partial t^2}",

    // 数论
    "e^{i\\pi} + 1 = 0",
    "\\zeta(s) = \\sum_{n=1}^{\\infty} \\frac{1}{n^s}",
    "a^p \\equiv a \\ (\\text{mod} \\ p)",

    // 几何
    "A = \\pi r^2",
    "V = \\frac{4}{3} \\pi r^3",
    "\\cos \\theta = \\frac{a^2 + b^2 - c^2}{2ab}",

    // 张量
    "R_{\\mu\\nu} - \\frac{1}{2} R g_{\\mu\\nu} = \\frac{8 \\pi G}{c^4} T_{\\mu\\nu}",
    "F_{\\mu\\nu} = \\partial_\\mu A_\\nu - \\partial_\\nu A_\\mu",
    "\\Gamma^{\\lambda}_{\\mu\\nu} = \\frac{1}{2} g^{\\lambda\\rho} (\\partial_\\mu g_{\\nu\\rho} + \\partial_\\nu g_{\\rho\\mu} - \\partial_\\rho g_{\\mu\\nu})",

    // 复变函数
    "f(z) = u(x,y) + iv(x,y)",
    "\\oint_{\\gamma} f(z) \\, dz = 2\\pi i \\cdot \\text{Res}(f, a)",
    "\\sin z = \\frac{e^{iz} - e^{-iz}}{2i}",

    // 特殊函数
    "\\Gamma(z) = \\int_0^{\\infty} t^{z-1} e^{-t} \\, dt",
    "J_n(x) = \\sum_{k=0}^{\\infty} \\frac{(-1)^k}{k! \\Gamma(n+k+1)} \\left( \\frac{x}{2} \\right)^{n+2k}",
    "\\text{erf}(x) = \\frac{2}{\\sqrt{\\pi}} \\int_0^x e^{-t^2} \\, dt",

    // 矩阵运算
    "e^{A} = \\sum_{k=0}^{\\infty} \\frac{1}{k!} A^k",
    "\\text{det}(e^{A}) = e^{\\text{tr}(A)}",
    "\\frac{d}{dt} e^{tA} = A e^{tA}",

    // 傅里叶变换
    "\\hat{f}(\\xi) = \\int_{-\\infty}^{\\infty} f(x) e^{-2\\pi i x \\xi} \\, dx",
    "f(x) = \\int_{-\\infty}^{\\infty} \\hat{f}(\\xi) e^{2\\pi i x \\xi} \\, d\\xi",
    "\\mathcal{F}\\{f * g\\} = \\mathcal{F}\\{f\\} \\cdot \\mathcal{F}\\{g\\}",

    // 群论
    "[A, B] = AB - BA",
    "G / H = \\{ gH \\mid g \\in G \\}",
    "\\text{Ker} \\phi = \\{ g \\in G \\mid \\phi(g) = e \\}",

    // 拓扑学
    "\\chi = V - E + F",
    "\\partial \\partial S = \\emptyset",
    "H_n(X) \\cong H_n(Y) \\text{ for } n \\geq 0",

    "\\int_{\\mathbb{R}^n} e^{-|x|^2} \\, dx = \\pi^{n/2}"
)
