import CBestline
import Foundation

/// A Swift wrapper for the Bestline library, providing enhanced readline functionality
public final class Bestline: @unchecked Sendable {

    /// Completion callback type
    public typealias CompletionCallback = (String, Int) -> [String]

    /// Hints callback type
    public typealias HintsCallback = (String) -> String?

    fileprivate var completionCallback: CompletionCallback?
    fileprivate var hintsCallback: HintsCallback?

    /// Singleton instance for managing callbacks
    fileprivate static let shared = Bestline()

    /// Read a line of input from the user with the given prompt
    /// - Parameter prompt: The prompt to display
    /// - Returns: The line entered by the user, or nil if EOF/error
    public static func readLine(prompt: String) -> String? {
        guard let cString = bestline(prompt) else {
            return nil
        }
        defer { bestlineFree(cString) }
        return String(cString: cString)
    }

    /// Read a line of input with initial text
    /// - Parameters:
    ///   - prompt: The prompt to display
    ///   - initialText: Initial text to show in the input line
    /// - Returns: The line entered by the user, or nil if EOF/error
    public static func readLine(prompt: String, initialText: String) -> String? {
        guard let cString = bestlineInit(prompt, initialText) else {
            return nil
        }
        defer { bestlineFree(cString) }
        return String(cString: cString)
    }

    /// Read a line of input with history support
    /// - Parameters:
    ///   - prompt: The prompt to display
    ///   - historyFile: Path to the history file
    /// - Returns: The line entered by the user, or nil if EOF/error
    public static func readLineWithHistory(prompt: String, historyFile: String) -> String? {
        guard let cString = bestlineWithHistory(prompt, historyFile) else {
            return nil
        }
        defer { bestlineFree(cString) }
        return String(cString: cString)
    }

    /// Add a line to the history
    /// - Parameter line: The line to add
    /// - Returns: true if successful
    @discardableResult
    public static func addToHistory(_ line: String) -> Bool {
        return bestlineHistoryAdd(line) != 0
    }

    /// Load history from a file
    /// - Parameter filename: Path to the history file
    /// - Returns: true if successful
    @discardableResult
    public static func loadHistory(from filename: String) -> Bool {
        return bestlineHistoryLoad(filename) == 0
    }

    /// Save history to a file
    /// - Parameter filename: Path to the history file
    /// - Returns: true if successful
    @discardableResult
    public static func saveHistory(to filename: String) -> Bool {
        return bestlineHistorySave(filename) == 0
    }

    /// Free the history
    public static func freeHistory() {
        bestlineHistoryFree()
    }

    /// Clear the screen
    /// - Parameter fileDescriptor: The file descriptor to clear (default: STDOUT_FILENO)
    public static func clearScreen(fileDescriptor: Int32 = STDOUT_FILENO) {
        bestlineClearScreen(fileDescriptor)
    }

    /// Enable mask mode (for password input)
    public static func enableMaskMode() {
        bestlineMaskModeEnable()
    }

    /// Disable mask mode
    public static func disableMaskMode() {
        bestlineMaskModeDisable()
    }

    /// Set balance mode (for matching parentheses, brackets, etc.)
    /// - Parameter enabled: Whether to enable balance mode
    public static func setBalanceMode(_ enabled: Bool) {
        bestlineBalanceMode(enabled ? 1 : 0)
    }

    /// Set Emacs keybindings mode
    /// - Parameter enabled: Whether to enable Emacs mode
    public static func setEmacsMode(_ enabled: Bool) {
        bestlineEmacsMode(enabled ? 1 : 0)
    }

    /// Set multiline mode for Ollama-style input delimited by triple quotes
    ///
    /// When enabled, allows multi-line input using triple quotes (""") as delimiters,
    /// similar to Ollama's multiline input format. Users can enter:
    /// ```
    /// """
    /// This is a multi-line
    /// input that spans
    /// multiple lines
    /// """
    /// ```
    ///
    /// - Parameter enabled: Whether to enable multiline mode
    public static func setMultilineMode(_ enabled: Bool) {
        bestlineLlamaMode(enabled ? 1 : 0)
    }

    /// Set completion callback
    /// - Parameter callback: The completion callback
    public static func setCompletionCallback(_ callback: @escaping CompletionCallback) {
        shared.completionCallback = callback
        bestlineSetCompletionCallback(completionCallbackFunction)
    }

    /// Set hints callback
    /// - Parameter callback: The hints callback
    public static func setHintsCallback(_ callback: @escaping HintsCallback) {
        shared.hintsCallback = callback
        bestlineSetHintsCallback(hintsCallbackFunction)

        // Set free hints callback to properly deallocate memory
        bestlineSetFreeHintsCallback { ptr in
            free(ptr)
        }
    }

    /// Disable raw mode (useful for cleanup)
    public static func disableRawMode() {
        bestlineDisableRawMode()
    }
}

// MARK: - C Function Wrappers
private func completionCallbackFunction(
    _ cString: UnsafePointer<CChar>?, _ position: Int32,
    _ lc: UnsafeMutablePointer<bestlineCompletions>?
) {
    guard let cString = cString, let lc = lc else { return }

    let input = String(cString: cString)
    let completions = Bestline.shared.completionCallback?(input, Int(position)) ?? []

    for completion in completions {
        bestlineAddCompletion(lc, completion)
    }
}

private func hintsCallbackFunction(
    _ cString: UnsafePointer<CChar>?, _ color: UnsafeMutablePointer<UnsafePointer<CChar>?>?,
    _ bold: UnsafeMutablePointer<UnsafePointer<CChar>?>?
) -> UnsafeMutablePointer<CChar>? {
    guard let cString = cString else { return nil }

    let input = String(cString: cString)
    guard let hint = Bestline.shared.hintsCallback?(input) else { return nil }

    return strdup(hint)
}
