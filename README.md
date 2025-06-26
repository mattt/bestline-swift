# Swift Bestline

A Swift package that wraps the [bestline][bestline] library,
providing enhanced readline functionality with features like
syntax highlighting, autocompletion, and history support.

## Features

- [x] **Line editing** with emacs/vi key bindings
- [x] **History support** with file persistence
- [x] **Tab completion** with custom callbacks
- [x] **Syntax hints** displayed in muted gray
- [x] **Password mode** for secure input
- [x] **Multi-line editing** support
- [x] **Unicode support**
- [x] **Undo/redo** functionality

## Installation

### Swift Package Manager

Add this package to your `Package.swift` dependencies:

```swift
dependencies: [
    .package(url: "https://github.com/loopwork-ai/bestline-swift.git", from: "1.0.0")
]
```

Then add `Bestline` to your target dependencies:

```swift
targets: [
    .target(
        name: "YourTarget",
        dependencies: ["Bestline"]
    )
]
```

## Usage

### Basic Line Reading

```swift
import Bestline

// Simple prompt
if let input = Bestline.readLine(prompt: "> ") {
    print("You entered: \(input)")
}

// With initial text
if let input = Bestline.readLine(prompt: "> ", initialText: "Hello ") {
    print("You entered: \(input)")
}
```

> [!TIP]
> When running without proper terminal capabilities
> (e.g., in CI/CD pipelines, piped I/O, or unsupported terminals),
> bestline automatically falls back to basic input mode 
> without interactive features.
> 
> **Full Mode** (all features available):
> - Requires a real TTY (not piped input/output)
> - Terminal type (`TERM` environment variable) must not be `dumb`, `cons25`, or > `emacs`
> - Must support raw mode via termios
> - Must support ANSI escape sequences
> 
> **Fallback Mode** (basic line reading only):
> - Used when terminal capabilities are insufficient
> - No line editing, completion, hints, or history navigation
> - Simple `fgets()`-based input

### History Support

History support lets the user recall previous commands
with <kbd>↑</kbd> / <kbd>↓</kbd> arrow keys.
Commands can be persisted to a file for access across sessions.

```swift
// Read with history file
let historyFile = "\(NSHomeDirectory())/.myapp_history"
if let input = Bestline.readLineWithHistory(prompt: "> ", historyFile: historyFile) {
    print("You entered: \(input)")
    Bestline.addToHistory(input)
}

// Manual history management
Bestline.loadHistory(from: historyFile)
Bestline.addToHistory("command 1")
Bestline.addToHistory("command 2")
Bestline.saveHistory(to: historyFile)
```

### Tab Completion

Tab completion provides automatic suggestions as users type,
letting them to quickly complete commands, file names, or other inputs
by pressing the <kbd>Tab</kbd> key.

```swift
Bestline.setCompletionCallback { input, position in
    // Return completions based on current input
    if input.hasPrefix("git ") {
        return ["add", "commit", "push", "pull", "status", "branch"]
    } else if input.hasPrefix("he") {
        return ["hello", "help", "heap"]
    }
    return []
}
```

### Syntax Hints

Syntax hints provide real-time contextual information as users type,
displaying helpful suggestions or usage tips in muted gray text
to the right of the cursor.

```swift
Bestline.setHintsCallback { input in
    switch input {
    case "git":
        return " <command>"
    case "help":
        return " - Show help information"
    case "exit":
        return " - Exit the program"
    default:
        return nil
    }
}
```

### Password Input

When handling sensitive input like passwords,
you can enable mask mode to hide the characters as they're typed:

```swift
Bestline.enableMaskMode()
if let password = Bestline.readLine(prompt: "Password: ") {
    // Terminal prints asterisks (*) instead of the actual characters typed
}
Bestline.disableMaskMode()
```

#### Multiline Mode

Multiline mode enables Ollama-style multiline input
using triple quotes as delimiters.
This is particularly useful for entering
longer text, code snippets, or structured data.

```swift
// Enable multiline mode
Bestline.setMultilineMode(true)
```

When enabled, users can enter multiline content by:
1. Typing `"""` to start multiline input
2. Entering text across multiple lines (pressing Enter creates new lines)
3. Typing `"""` on its own line to end multiline input

Example interaction:
```
> """
... This is a multiline
... text input that spans
... multiple lines.
... """
```

The entire content between the triple quotes
is returned as a single string with embedded newlines preserved.

### Balance Mode

Balance mode enables automatic bracket matching for
parentheses, brackets, and braces.
When enabled, bestline will visually highlight matching pairs as you type:

```swift
// Enable bracket matching
Bestline.setBalanceMode(true)
```

This helps when writing code or complex expressions
by showing which brackets match.
For example, when you type a closing bracket,
the corresponding opening bracket will be briefly highlighted.

### Emacs Mode

Emacs mode enables advanced keyboard shortcuts for line editing.
This provides a familiar experience to users of 
readline, emacs, vi, and other editing software.

```swift
// Enable Emacs key bindings
Bestline.setEmacsMode(true)
```

#### Disabling Raw Mode

In some cases, you may need to explicitly disable raw mode
(useful for cleanup or when switching between different input modes):

```swift
// Disable raw mode
Bestline.disableRawMode()
```

This returns the terminal to its normal "cooked" mode,
where input is line-buffered and special characters are processed by the terminal.

## Example Application

Here's a complete example of a command-line application using [swift-argument-parser](https://github.com/apple/swift-argument-parser):

First, add the dependency to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/loopwork-ai/swift-bestline.git", from: "1.0.0"),
    .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.0.0")
]
```

Then create your executable:

```swift
import Foundation
import Bestline
import ArgumentParser

@main
struct MyREPL: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "An interactive REPL with enhanced line editing",
        version: "1.0.0"
    )

    @Option(name: .shortAndLong, help: "History file location")
    var historyFile: String?

    @Option(name: .shortAndLong, help: "Custom prompt string")
    var prompt: String = "repl> "

    @Flag(name: .shortAndLong, help: "Enable verbose output")
    var verbose: Bool = false

    @Flag(help: "Disable history persistence")
    var noHistory: Bool = false

    func run() throws {
        let historyPath = resolveHistoryFile()

        if verbose {
            print("Starting REPL with history file: \(historyPath)")
        }

        // Load history unless disabled
        if !noHistory {
            Bestline.loadHistory(from: historyPath)
        }

        setupCompletion()
        setupHints()

        print("Welcome to MyREPL. Type 'exit' to quit.")
        if verbose {
            print("History: \(noHistory ? "disabled" : "enabled")")
        }

        while true {
            guard let line = Bestline.readLine(prompt: prompt) else {
                // EOF (Ctrl-D)
                break
            }

            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty { continue }

            // Add to history unless disabled
            if !noHistory {
                Bestline.addToHistory(line)
            }

            // Process command
            if !processCommand(trimmed) {
                break // Exit requested
            }
        }

        // Save history unless disabled
        if !noHistory {
            Bestline.saveHistory(to: historyFile)
        }

        print("\nGoodbye!")
    }

    private func resolveHistoryFile() -> String {
        if let customPath = historyFile {
            return customPath
        }

        let stateHome = ProcessInfo.processInfo.environment["XDG_STATE_HOME"]
            ?? "\(FileManager.default.homeDirectoryForCurrentUser.path)/.local/state"
        return "\(stateHome)/myrepl_history"
    }

    private func setupCompletion() {
        Bestline.setCompletionCallback { input, position in
            let commands = ["exit", "clear", "echo", "version"]
            return commands.filter { $0.hasPrefix(input) }
        }
    }

    private func setupHints() {
        Bestline.setHintsCallback { input in
            switch input {
            case "exit":
                return " - Exit the REPL"
            case "clear":
                return " - Clear the screen"
            case "version":
                return " - Show version information"
            default:
                return nil
            }
        }
    }

    private func processCommand(_ command: String) -> Bool {
        switch command {
        case "exit":
            return false
        case "clear":
            Bestline.clearScreen()
        case "version":
            print("MyREPL version \(Self.configuration.version ?? "unknown")")
        default:
            if command.hasPrefix("echo ") {
                let text = String(command.dropFirst(5))
                print(text)
            } else {
                print("Unknown command: \(command)")
                print("Available: exit, clear, echo, version")
            }
        }
        return true
    }
}
```

## License

This Swift wrapper is provided under the same 2-clause BSD license
as the original bestline library.
See the [bestline repository][bestline] for details.

[bestline]: https://github.com/jart/bestline
