import XCTest

/// One gesture script per scene, run against either app.
///
/// The app is picked by TARGET_APP ("apple" or "package"; xcodebuild hands
/// TEST_RUNNER_TARGET_APP through). Every test writes a start/end mark and
/// a screenshot at rest, which tools/record.py turns into synced clips.
/// Positions mirror AppleReference/Layout.swift and package_app/lib/layout.dart.
final class SceneTests: XCTestCase {
    private var which: String { ProcessInfo.processInfo.environment["TARGET_APP"] ?? "apple" }
    private var bundleID: String {
        which == "apple" ? "dev.lgcompare.apple" : "dev.lgcompare.glassPackage"
    }

    private var app: XCUIApplication!
    private var w: CGFloat = 402
    private var h: CGFloat = 874

    override func setUpWithError() throws {
        continueAfterFailure = true
    }

    override func tearDownWithError() throws {
        app?.terminate()
    }

    // MARK: - Scenes

    func test1Glass() {
        run("glass") {
            let big = p(0.5, 0.36)
            hold(big, 1.0)
            drag(big, p(0.5, 0.55), velocity: .slow, hold: 0.5)
            drag(p(0.5, 0.55), p(0.3, 0.36), velocity: .fast, hold: 0.1)
            drag(p(0.3, 0.36), big, velocity: .default, hold: 0.3)
            tap(p(0.28, 0.64))
            pause(0.8)
            tap(p(0.72, 0.64))
            pause(0.8)
            hold(p(0.72, 0.64), 1.0)
        }
    }

    func test2Buttons() {
        run("buttons") {
            tap(p(0.5, 0.30))
            pause(0.8)
            hold(p(0.5, 0.44), 0.8)
            drag(p(0.5, 0.44), CGPoint(x: w / 2 + 90, y: h * 0.44), velocity: .slow, hold: 0.5)
            pause(0.6)
            tap(p(0.5, 0.60))
            pause(0.8)
            tap(p(0.5, 0.72))
            pause(0.8)
            hold(p(0.5, 0.72), 1.0)
        }
    }

    func test3Slider() {
        run("slider") {
            let ys: [CGFloat] = [0.38, 0.50, 0.62]
            drag(thumb(0.40, ys[1]), thumb(0.90, ys[1]), velocity: .slow, hold: 0.4)
            drag(thumb(0.90, ys[1]), thumb(0.10, ys[1]), velocity: .fast, hold: 0)
            pause(0.8)
            hold(thumb(0.65, ys[0]), 1.0)
            pause(0.4)
            drag(thumb(0.65, ys[0]), thumb(0.20, ys[0]), velocity: .fast, hold: 0)
            pause(0.8)
            tap(thumb(0.30, ys[2]))
            pause(0.8)
        }
    }

    func test4Toggle() {
        run("toggle") {
            let ys: [CGFloat] = [0.40, 0.50, 0.60]
            tap(p(0.5, ys[0]))
            pause(1.0)
            tap(p(0.5, ys[0]))
            pause(1.0)
            // Toggle 2 starts off: pull its thumb across by hand.
            drag(CGPoint(x: w / 2 - 17, y: h * ys[1]), CGPoint(x: w / 2 + 17, y: h * ys[1]),
                 velocity: .slow, hold: 0.4)
            pause(1.0)
            hold(p(0.5, ys[2]), 1.0)
            pause(1.0)
        }
    }

    func test5TabBar() {
        run("tabbar") {
            tap(tab(3))
            pause(1.2)
            tap(tab(0))
            pause(1.2)
            tap(tab(2))
            pause(1.2)
            drag(tab(2), tab(0), velocity: .slow, hold: 0.3)
            pause(1.2)
            drag(p(0.5, 0.72), p(0.5, 0.30), velocity: .fast, hold: 0)
            pause(1.5)
            drag(p(0.5, 0.30), p(0.5, 0.72), velocity: .fast, hold: 0)
            pause(1.5)
        }
    }

    // MARK: - Plumbing

    private func run(_ scene: String, _ script: () -> Void) {
        app = XCUIApplication(bundleIdentifier: bundleID)
        app.launchEnvironment["SCENE"] = scene
        app.launch()
        let frame = app.frame
        if frame.width > 0 { w = frame.width; h = frame.height }
        // Let the glass warm up and the photos decode before anything moves.
        pause(3.0)
        screenshot(scene)
        mark(scene, "start")
        script()
        mark(scene, "end")
        pause(1.0)
    }

    private func p(_ fx: CGFloat, _ fy: CGFloat) -> CGPoint { CGPoint(x: w * fx, y: h * fy) }

    /// Where a slider's thumb sits for [value]; the thumb is wide enough
    /// that both apps' slightly different track insets still land on it.
    private func thumb(_ value: CGFloat, _ fy: CGFloat) -> CGPoint {
        let left = w / 2 - 150
        return CGPoint(x: left + 14 + value * (300 - 28), y: h * fy)
    }

    /// Tab centres: read from Apple's tab bar when there is one, else the
    /// package bar's geometry (16 pt side inset, 62 pt tall, 8 pt above
    /// the home indicator inset).
    private func tab(_ i: Int) -> CGPoint {
        if which == "apple" {
            let button = app.tabBars.buttons.element(boundBy: i)
            if button.exists {
                let f = button.frame
                return CGPoint(x: f.midX, y: f.midY)
            }
        }
        let barWidth = w - 32
        let x = 16 + barWidth * (CGFloat(i) + 0.5) / 4
        let y = h - 34 - 8 - 31
        return CGPoint(x: x, y: y)
    }

    private func at(_ point: CGPoint) -> XCUICoordinate {
        app.coordinate(withNormalizedOffset: .zero)
            .withOffset(CGVector(dx: point.x, dy: point.y))
    }

    private func tap(_ point: CGPoint) { at(point).tap() }

    private func hold(_ point: CGPoint, _ seconds: TimeInterval) {
        at(point).press(forDuration: seconds)
    }

    private func drag(_ from: CGPoint, _ to: CGPoint,
                      velocity: XCUIGestureVelocity, hold: TimeInterval) {
        at(from).press(forDuration: 0.25, thenDragTo: at(to),
                       withVelocity: velocity, thenHoldForDuration: hold)
    }

    private func pause(_ seconds: TimeInterval) {
        Thread.sleep(forTimeInterval: seconds)
    }

    private func mark(_ scene: String, _ phase: String) {
        let line = String(format: "MARK %@ %@ %@ %.3f\n",
                          which, scene, phase, Date().timeIntervalSince1970)
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

    private func screenshot(_ scene: String) {
        let shot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: shot)
        attachment.name = "\(which)-\(scene)"
        attachment.lifetime = .keepAlways
        add(attachment)
        guard let dir = ProcessInfo.processInfo.environment["SHOTS_DIR"] else { return }
        let url = URL(fileURLWithPath: dir).appendingPathComponent("\(which)-\(scene).png")
        try? shot.pngRepresentation.write(to: url)
    }
}
