import Bestline
import Foundation
import Testing

@Suite("Bestline Tests", .serialized)
struct BestlineTests {
    @Test
    func historyOperations() {
        let testHistoryFile = FileManager.default.temporaryDirectory.appendingPathComponent(
            "bestline_test_history.txt"
        ).path

        // Clean up any existing history
        Bestline.freeHistory()

        // Add some items to history
        #expect(Bestline.addToHistory("first command"))
        #expect(Bestline.addToHistory("second command"))
        #expect(Bestline.addToHistory("third command"))

        // Save history
        #expect(Bestline.saveHistory(to: testHistoryFile))

        // Clear and reload
        Bestline.freeHistory()
        #expect(Bestline.loadHistory(from: testHistoryFile))

        // Clean up
        try? FileManager.default.removeItem(atPath: testHistoryFile)
        Bestline.freeHistory()
    }

    @Test
    func modeSettings() {
        // These just test that the functions can be called without crashing
        Bestline.setBalanceMode(true)
        Bestline.setBalanceMode(false)

        Bestline.setEmacsMode(true)
        Bestline.setEmacsMode(false)

        Bestline.setMultilineMode(true)
        Bestline.setMultilineMode(false)

        Bestline.enableMaskMode()
        Bestline.disableMaskMode()
    }

    @Test
    func completionCallback() {
        // Set up a simple completion callback
        Bestline.setCompletionCallback { input, position in
            if input.hasPrefix("git ") {
                return ["add", "commit", "push", "pull", "status"]
            } else if input.hasPrefix("he") {
                return ["hello", "help", "heap"]
            }
            return []
        }

        // Note: We can't test the actual completion behavior without
        // interacting with a terminal, but we can verify the callback
        // is set without crashing
        #expect(Bool(true))
    }

    @Test
    func hintsCallback() {
        // Set up a simple hints callback
        Bestline.setHintsCallback { input in
            if input == "git" {
                return " <command>"
            } else if input == "help" {
                return " - Show help information"
            }
            return nil
        }

        // Note: We can't test the actual hints behavior without
        // interacting with a terminal, but we can verify the callback
        // is set without crashing
        #expect(Bool(true))
    }
}
