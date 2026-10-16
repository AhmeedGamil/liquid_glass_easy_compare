import XCTest

/// Frame-by-frame traces of Apple's glass, one app launch per case.
///
/// The app writes its own layer tree every frame (AppleReference/Tracer.swift)
/// to Documents/traces/<case>.jsonl; the test only moves the finger and
/// writes a mark per step. Skipped unless TRACE_RUN is set, so the Compare
/// recordings never run them.
final class TraceTests: XCTestCase {
    private var app: XCUIApplication!
    private var w: CGFloat = 402
    private var h: CGFloat = 874
    private var caseName = ""

    override func setUpWithError() throws {
        try XCTSkipUnless(ProcessInfo.processInfo.environment["TRACE_RUN"] != nil,
                          "trace runs only (TRACE_RUN)")
        continueAfterFailure = true
    }

    override func tearDownWithError() throws {
        app?.terminate()
    }

    // MARK: - Tab bar (starts on tab 0)

    func testTab01TapFar() {
        trace("tab_tap_far", "tabbar") { step("tap3"); tap(tab(3)); pause(2.0) }
    }

    func testTab02TapNear() {
        trace("tab_tap_near", "tabbar") { step("tap1"); tap(tab(1)); pause(2.0) }
    }

    func testTab03TapInterrupted() {
        trace("tab_tap_interrupted", "tabbar") {
            step("tap3"); tap(tab(3)); pause(0.3)
            step("tap0"); tap(tab(0)); pause(2.0)
        }
    }

    func testTab04HoldSelected() {
        trace("tab_hold_selected", "tabbar") { step("hold0"); hold(tab(0), 2.0); step("up"); pause(2.0) }
    }

    func testTab05HoldUnselected() {
        trace("tab_hold_unselected", "tabbar") { step("hold2"); hold(tab(2), 2.0); step("up"); pause(2.0) }
    }

    func testTab06DragSlow() {
        trace("tab_drag_slow", "tabbar") {
            step("drag0to3"); drag(tab(0), tab(3), press: 0.4, velocity: 200, hold: 0.8); step("up"); pause(2.0)
        }
    }

    func testTab07DragFast() {
        trace("tab_drag_fast", "tabbar") {
            step("drag0to3"); drag(tab(0), tab(3), press: 0.15, velocity: 1500, hold: 0); step("up"); pause(2.0)
        }
    }

    func testTab08Swipe() {
        trace("tab_swipe", "tabbar") {
            step("swipe0to2"); drag(tab(0), tab(2), press: 0.02, velocity: 3000, hold: 0); step("up"); pause(2.0)
        }
    }

    func testTab09DragFromUnselected() {
        trace("tab_drag_from_unselected", "tabbar") {
            step("drag2to1"); drag(tab(2), tab(1), press: 0.4, velocity: 200, hold: 0.6); step("up"); pause(2.0)
        }
    }

    func testTab10DragPastEnd() {
        trace("tab_drag_past_end", "tabbar") {
            let start = tab(0)
            step("drag0toEdge"); drag(start, CGPoint(x: 4, y: start.y), press: 0.4, velocity: 150, hold: 0.8)
            step("up"); pause(2.0)
        }
    }

    func testTab11DragUpOut() {
        trace("tab_drag_up_out", "tabbar") {
            let start = tab(0)
            step("drag0up"); drag(start, CGPoint(x: start.x, y: start.y - 160), press: 0.4, velocity: 200, hold: 0.6)
            step("up"); pause(2.0)
        }
    }

    // MARK: - Morph: circle to list and back

    func testMorph1Menu() {
        trace("morph_menu", "menu", warmUp: { self.warmMenu(self.morphSource()) }) {
            step("open"); tap(morphSource()); pause(2.0)
            step("close"); tap(p(0.3, 0.85)); pause(2.0)
        }
    }

    func testMorph2MenuHold() {
        trace("morph_menu_hold", "menu", warmUp: { self.warmMenu(self.morphSource()) }) {
            step("hold"); hold(morphSource(), 1.2); step("up"); pause(2.0)
            step("close"); tap(p(0.3, 0.85)); pause(2.0)
        }
    }

    func testMorph3ToolbarMenu() {
        trace("morph_toolbar_menu", "toolbarmenu", warmUp: { self.warmMenu(self.toolbarMore()) }) {
            step("open"); tap(toolbarMore()); pause(2.0)
            step("close"); tap(p(0.3, 0.85)); pause(2.0)
        }
    }

    func testMorph4GlassEffectID() {
        // The scene opens and closes itself (4 s and 7 s after launch).
        trace("morph_glass_effect_id", "glassmorph") { pause(7.0) }
    }

    // MARK: - Plumbing

    private func toolbarMore() -> CGPoint {
        let more = app.buttons["More"].firstMatch
        return more.exists ? CGPoint(x: more.frame.midX, y: more.frame.midY) : CGPoint(x: w - 36, y: 84)
    }

    /// The first menu an app shows freezes it while UIKit builds the menu,
    /// swallowing the start of the morph: open and close one first.
    private func warmMenu(_ at: CGPoint) {
        tap(at); pause(2.0)
        tap(p(0.3, 0.85)); pause(2.0)
    }

    /// The tab bar's first touch builds the lifted glass (a ~100 ms stall):
    /// press the selected tab once first.
    private func warmTabs() {
        hold(tab(0), 0.6); pause(1.5)
    }

    private func trace(_ name: String, _ scene: String, warmUp: (() -> Void)? = nil,
                       _ script: () -> Void) {
        caseName = name
        app = XCUIApplication(bundleIdentifier: "dev.lgcompare.apple")
        app.launchEnvironment["SCENE"] = scene
        app.launchEnvironment["TRACE"] = name
        app.launchEnvironment["TRACE_SECONDS"] = "30"
        for key in ["TRACE_LITE", "TRACE_DEEP"] {
            if let value = ProcessInfo.processInfo.environment[key] {
                app.launchEnvironment[key] = value
            }
        }
        app.launch()
        let frame = app.frame
        if frame.width > 0 { w = frame.width; h = frame.height }
        pause(3.0)
        if let warmUp {
            warmUp()
        } else if scene == "tabbar" {
            warmTabs()
        }
        step("start")
        script()
        step("end")
        pause(0.5)
    }

    /// Centre of the circle the morph scenes open from (MorphSpot).
    private func morphSource() -> CGPoint { CGPoint(x: w - 24 - 28, y: 140 + 28) }

    private func tab(_ i: Int) -> CGPoint {
        let titles = ["Home", "Browse", "Radio", "Library"]
        let button = app.buttons[titles[i]].firstMatch
        if button.exists {
            let f = button.frame
            return CGPoint(x: f.midX, y: f.midY)
        }
        let barWidth = w - 50
        return CGPoint(x: 25 + barWidth * (CGFloat(i) + 0.5) / 4, y: h - 34 - 31)
    }

    private func p(_ fx: CGFloat, _ fy: CGFloat) -> CGPoint { CGPoint(x: w * fx, y: h * fy) }

    private func at(_ point: CGPoint) -> XCUICoordinate {
        app.coordinate(withNormalizedOffset: .zero)
            .withOffset(CGVector(dx: point.x, dy: point.y))
    }

    private func tap(_ point: CGPoint) { at(point).tap() }

    private func hold(_ point: CGPoint, _ seconds: TimeInterval) {
        at(point).press(forDuration: seconds)
    }

    private func drag(_ from: CGPoint, _ to: CGPoint, press: TimeInterval,
                      velocity: CGFloat, hold: TimeInterval) {
        at(from).press(forDuration: press, thenDragTo: at(to),
                       withVelocity: XCUIGestureVelocity(rawValue: velocity),
                       thenHoldForDuration: hold)
    }

    private func pause(_ seconds: TimeInterval) {
        Thread.sleep(forTimeInterval: seconds)
    }

    private func step(_ label: String) {
        let line = String(format: "MARK %@ %@ %.4f\n", caseName, label, Date().timeIntervalSince1970)
        print(line, terminator: "")
        guard let path = ProcessInfo.processInfo.environment["MARKS_FILE"] else { return }
        if let handle = FileHandle(forWritingAtPath: path) {
            handle.seekToEndOfFile()
            handle.write(Data(line.utf8))
            handle.closeFile()
        } else {
            FileManager.default.createFile(atPath: path, contents: Data(line.utf8))
        }
    }
}
