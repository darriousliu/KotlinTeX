# KotlinTeX

# The current project is no longer maintained. It is recommended to refer to the new project [RaTeX-CMP](https:github.comdarriousliuRaTeX-CMP) based on [RaTeX](https:github.comerweixinRaTeX)

[English Version](README-en.md) | [中文版本](README.md)

[![License](https://img.shields.io/badge/License-BSD%202--Clause-orange.svg)](https://opensource.org/licenses/BSD-2-Clause)
[![Kotlin](https://img.shields.io/badge/kotlin-multiplatform-blue.svg?logo=kotlin)]([http://kotlinlang.org](https://www.jetbrains.com/kotlin-multiplatform/))

A cross-platform LaTeX mathematical expression rendering library based on Kotlin Multiplatform,
supporting Android / iOS / Jvm platforms.

## Display

https://github.com/user-attachments/assets/b240a3e7-7a29-437d-8f36-2c248b55669c

## About the Project

This project is rewritten based on the open-source project
[**AndroidMath**](https://github.com/gregcockroft/AndroidMath),
converting all code to Kotlin and implementing cross-platform support using Kotlin Multiplatform
technology. It provides high-quality LaTeX mathematical expression rendering functionality for
Android / iOS / Jvm platforms through Compose Multiplatform.

## Features

- 🚀 Based on Kotlin Multiplatform technology
    - Android integrates FreeType library via JNI
    - iOS integrates FreeType library via C interop
    - JVM platform integrates FreeType library via lwjgl library
- 📱 Supports Android / iOS / Jvm platforms
- 🎨 UI rendering using Compose Multiplatform
- 📊 Complete LaTeX mathematical expression support
- 🔧 Easy integration and usage

## Platform Support

- ✅ Android (API 23+), already adapted for 16KB Page Size
- ✅ iOS (iOS 13+)
- ✅ JVM (Compose MultiplatformDesktop applications)

## Dependencies

### Gradle (Kotlin DSL)

Add the following to your `settings.gradle.kts`:

```kotlin
pluginManagement {
    repositories {
        mavenCentral() // or maven { url = uri("https://jitpack.io") }
    }
}
```

Then, add the dependency in your `build.gradle.kts`:

### Android

```kotlin
dependencies {
    implementation("io.github.darriousliu:katex-core:0.3.2")
}
```

### Kotlin Multiplatform

```kotlin
kotlin {
    sourceSets {
        commonMain.dependencies {
            implementation("io.github.darriousliu:katex-core:0.3.2")
        }
    }
}
```

### Project Configuration

Please ensure your project is properly configured with Kotlin Multiplatform and Compose
Multiplatform.

### JVM Platform Specific Configuration

When using on the JVM platform, you need to add platform-specific FreeType native library
dependencies:

```kotlin
jvmMain.dependencies {
    implementation(compose.desktop.currentOs)
    // Detect platform
    val currentOs = OperatingSystem.current()
    val lwjglPlatform = when {
        currentOs.isMacOsX -> "macos"
        currentOs.isWindows -> "windows"
        currentOs.isLinux -> "linux"
        else -> error("Unsupported OS: $currentOs")
    }
    val processor = ArchUtils.getProcessor()
    val lwjglArch = when {
        processor.isAarch64 -> "arm64"
        processor.is64Bit -> "x64"
        else -> error("Unsupported architecture: ${processor.arch} ${processor.type}")
    }
    val lwjglNatives = "natives-$lwjglPlatform-$lwjglArch"
    // Platform-specific native libraries
    runtimeOnly("org.lwjgl:lwjgl:${version}:$lwjglNatives")
    runtimeOnly("org.lwjgl:lwjgl-freetype:${version}:$lwjglNatives")
}
```

## Usage

1. Direct usage with LaTeX string

```kotlin
@Composable
fun LatexExample() {
    MTMathView(
        latex = "\\frac{a}{b}",
        modifier = Modifier.fillMaxWidth(),
        fontSize = 20.sp,
        textColor = Color.Black,
        font = null,
        mode = MTMathViewMode.KMTMathViewModeDisplay,
        textAlignment = MTTextAlignment.KMTTextAlignmentLeft,
        displayErrorInline = true,
        errorFontSize = 20.sp,
    )
}
```

2. Parse LaTeX in background thread such as in ViewModel

```kotlin
val latexFormulas = listOf(
    "\\frac{a}{b}",
    "\\sqrt{x^2 + y^2}",
    "\\int_0^1 x^2 dx",
    "\\sum_{i=1}^n i^2"
)

@KoinViewModel
class LatexViewModel : ViewModel() {
    val state = MutableStateFlow(emptyList<MTMathList>())

    fun parseLatex() {
        viewModelScope.launch(Dispatchers.Default) {
            state.value = latexFormulas.mapNotNull { latex ->
                if (latex.isNotEmpty()) {
                    val newParseError = MTParseError()
                    val list = MTMathListBuilder.buildFromString(latex, newParseError)
                    if (newParseError.errorCode != MTParseErrors.ErrorNone) {
                        null
                    } else {
                        list
                    }
                } else {
                    null
                }
            }
        }
    }
}
```

```kotlin
@Composable
fun LatexList(
    viewModel: LatexViewModel = koinViewModel(),
    modifier: Modifier = Modifier
) {
    LaunchedEffect(Unit) {
        viewModel.parseLatex()
    }
    val state by viewModel.state.collectAsStateWithLifecycle()

    LazyColumn(modifier = modifier) {
        items(state) { mathList ->
            MTMathView(
                mathList = mathList,
                fontSize = 20.sp,
                textColor = Color.Black,
                font = null,
                mode = MTMathViewMode.KMTMathViewModeDisplay,
                textAlignment = MTTextAlignment.KMTTextAlignmentLeft,
                displayErrorInline = false,
                errorFontSize = 20.sp,
            )
        }
    }
}
```

3. Custom fonts

Load predefined fonts synchronously:

```kotlin
@Composable
fun CustomFontLatexExample() {
    val predefinedFont = rememberMTFont(
        fontSize = 20.sp,
        mathFont = MTMathFont.LatinModernMath,
    )

    MTMathView(
        latex = "\\frac{a}{b}",
        modifier = Modifier.fillMaxWidth(),
        fontSize = 20.sp,
        textColor = Color.Black,
        font = predefinedFont,
        mode = MTMathViewMode.KMTMathViewModeDisplay,
        textAlignment = MTTextAlignment.KMTTextAlignmentLeft,
        displayErrorInline = true,
        errorFontSize = 20.sp,
    )
}
```

Asynchronously load custom fonts for LaTeX rendering:

```kotlin
@Composable
fun CustomFontLatexExample() {
    val customFont by rememberMTFont(
        fontSize = 20.sp,
        fontName = "CustomFont"
    ) {
        // Load custom font files here
        // Example：Res.readBytes("files/fonts/CustomFont.otf")
        Res.readBytes("files/fonts/CustomFont.otf")
    }

    // Make sure the font is loaded before rendering, 
    // otherwise the default font will be used first and then switch to custom fonts
    if (customFont != null) {
        MTMathView(
            latex = "\\frac{a}{b}",
            modifier = Modifier.fillMaxWidth(),
            fontSize = 20.sp,
            textColor = Color.Black,
            font = customFont,
            mode = MTMathViewMode.KMTMathViewModeDisplay,
            textAlignment = MTTextAlignment.KMTTextAlignmentLeft,
            displayErrorInline = true,
            errorFontSize = 20.sp,
        )
    }
}
```

## Building from Source

```shell
# Build iOS artifacts

# Download freetype library to external directory
git submodule update --init --recursive
cd external/freetype

# Build FreeType library
./build-ios-cmake.sh
```

### CI/CD Configuration

For JVM applications distributed on different platforms, the appropriate local library is
automatically selected by building on different platforms (Windows/macOS/Linux).

## Acknowledgments

This project is developed based on the [AndroidMath](https://github.com/gregcockroft/AndroidMath)
project. Thanks to the original authors for their contributions.

## Contributing

Issues and Pull Requests are welcome to help improve this project.

## Contact

For questions or suggestions, please contact us through GitHub Issues.
