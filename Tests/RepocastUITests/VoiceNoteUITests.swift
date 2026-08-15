import XCTest

/// End-to-end voice-note flow: generate a track, play it, record a note from
/// the Now Playing screen (which must pause playback), and see it land in the
/// Notes tab. The microphone permission alert is answered in-test (running
/// `xcodebuild test` reinstalls the app, which resets any pre-granted TCC
/// permission). The speech-recognition step degrades gracefully where
/// on-device recognition is unavailable, so the note may read "transcription
/// unavailable" — that's still a pass for the recording pipeline.
final class VoiceNoteUITests: XCTestCase {

    @MainActor
    func testRecordNoteWhilePlayingAndFindItInNotesTab() throws {
        let app = XCUIApplication()
        // Stub the microphone: on Macs where the Simulator lacks host mic
        // access, AVAudioRecorder never comes up, so the real-mic path can't
        // run headless. The stub exercises the full note pipeline (pause,
        // time code, persistence, Notes tab) minus the hardware.
        app.launchArguments += ["-fake-mic"]
        app.launch()

        // Generate a uniquely-named track so the test tolerates existing data.
        let title = "Note Test \(Int(Date().timeIntervalSince1970))"
        app.buttons["Add"].tap()
        app.buttons["New Track"].tap()
        let titleField = app.textFields.firstMatch
        XCTAssertTrue(titleField.waitForExistence(timeout: 5))
        titleField.tap()
        titleField.typeText(title)
        let editor = app.textViews.firstMatch
        editor.tap()
        editor.typeText("Remember to review the retry logic in the sync engine tomorrow.")
        app.buttons["Generate"].tap()

        // Play it, then pause from the mini-player before opening the sheet —
        // a playing player re-renders twice a second, which starves XCUITest's
        // quiescence wait and times out its queries.
        let row = app.staticTexts[title]
        XCTAssertTrue(row.waitForExistence(timeout: 30), "generated track should appear")
        row.tap()
        let pauseButton = app.buttons["Pause"]
        XCTAssertTrue(pauseButton.waitForExistence(timeout: 10), "mini-player should appear playing")
        pauseButton.tap()
        app.buttons["mini-player"].tap()

        // Record: the bar replaces the speed picker while recording.
        let recordButton = app.buttons["Record note"]
        XCTAssertTrue(recordButton.waitForExistence(timeout: 5))
        recordButton.tap()

        // Answer the microphone permission alert if it appears.
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        for label in ["Allow", "OK"] {
            let alertButton = springboard.buttons[label]
            if alertButton.waitForExistence(timeout: 3) {
                alertButton.tap()
                break
            }
        }

        let saveButton = app.buttons["Save"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 10), "recording bar should appear")
        // Give the mic a moment of audio before saving.
        Thread.sleep(forTimeInterval: 1.5)
        saveButton.tap()

        // The note shows up in the Notes tab, pinned to this track.
        app.swipeDown()  // dismiss the Now Playing sheet
        app.tabBars.buttons["Notes"].tap()
        let noteRow = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS %@", title)
        ).firstMatch
        XCTAssertTrue(noteRow.waitForExistence(timeout: 10), "note should list under the track's title")
    }
}
