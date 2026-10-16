import ObjectiveC
import QuartzCore
import UIKit

/// Writes every window's layer tree to Documents/traces/<TRACE>.jsonl, one
/// line per display frame: a layer the first time it is seen (class, view,
/// parent) and its geometry again whenever it changes, plus the touches.
/// Values come from the presentation layers, so animations read where they
/// are on screen, not where they are heading.
///
/// Per layer: r = on-screen box [x, y, w, h] in window points, b = bounds
/// size, m = the window-space matrix [a, b, c, d] when it is not identity
/// (scale and rotation), cr = corner radius in the layer's own points.
final class FrameTracer: NSObject {
    static let shared = FrameTracer()

    private struct Seen {
        var id: String
        var identity: String
        var nums: [CGFloat]
        var extra: String
    }

    private var link: CADisplayLink?
    private var handle: FileHandle?
    private var frameIndex = 0
    private var seen: [ObjectIdentifier: Seen] = [:]
    private var touches: [String] = []
    private var stopAt: CFTimeInterval = 0
    private var propsByClass: [ObjectIdentifier: [String]] = [:]
    private var seenAnimations = Set<String>()
    private var anims: [String] = []

    /// Public classes whose own properties are not worth reading every frame.
    private static let stops: [AnyClass] = [
        NSObject.self, CALayer.self, CAShapeLayer.self, CATextLayer.self, CAGradientLayer.self,
        CAScrollLayer.self, CATransformLayer.self, CAReplicatorLayer.self, CAEmitterLayer.self,
        UIView.self, UIControl.self, UIImageView.self, UILabel.self, UIScrollView.self,
    ]

    /// Classes whose private properties (and Swift stored properties) are
    /// read every frame: the glass shapes and what moves them.
    private static let interesting = try! NSRegularExpression(
        pattern: "SDF|Lens|Morph|Pivot|Selection",
        options: [.caseInsensitive])

    /// Animation fields read when an animation first shows up on a layer.
    private static let animationKeys = [
        "keyPath", "beginTime", "duration", "speed", "timeOffset", "repeatCount", "autoreverses",
        "fillMode", "additive", "cumulative", "removedOnCompletion", "fromValue", "toValue", "byValue",
        "mass", "stiffness", "damping", "initialVelocity", "settlingDuration", "perceptualDuration",
        "bounce", "allowsOverdamping", "values", "keyTimes", "calculationMode",
        "sourceLayer", "properties", "sourcePoints", "targetsSuperlayer",
    ]

    /// Corner radii UIKit's glass shapes copy from their source layer
    /// (CALayer's private per-corner radii).
    private static let radiiSelector = NSSelectorFromString("cornerRadii")

    private var running: Bool { handle != nil }

    func start(name: String, seconds: Double) {
        let fm = FileManager.default
        let dir = fm.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("traces")
        try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        let url = dir.appendingPathComponent("\(name).jsonl")
        fm.createFile(atPath: url.path, contents: nil)
        handle = try? FileHandle(forWritingTo: url)

        let screen = UIScreen.main
        write("{\"hdr\":1,\"name\":\"\(esc(name))\",\"scale\":\(screen.scale),\"w\":\(f(screen.bounds.width)),\"h\":\(f(screen.bounds.height)),\"fps\":\(screen.maximumFramesPerSecond),\"t\":\(t6(CACurrentMediaTime())),\"wall\":\(t6(Date().timeIntervalSince1970))}\n")

        stopAt = CACurrentMediaTime() + seconds
        TouchTap.install()
        let link = CADisplayLink(target: self, selector: #selector(tick(_:)))
        link.preferredFrameRateRange = CAFrameRateRange(minimum: 60, maximum: 120, preferred: 120)
        link.add(to: .main, forMode: .common)
        self.link = link
    }

    func note(_ event: UIEvent) {
        guard running, event.type == .touches, let all = event.allTouches else { return }
        for touch in all {
            let at = touch.location(in: nil)
            touches.append("{\"t\":\(t6(touch.timestamp)),\"ph\":\(touch.phase.rawValue),\"x\":\(f(at.x)),\"y\":\(f(at.y))}")
        }
    }

    @objc private func tick(_ link: CADisplayLink) {
        let now = CACurrentMediaTime()
        if now > stopAt {
            link.invalidate()
            self.link = nil
            try? handle?.close()
            handle = nil
            return
        }

        var items: [String] = []
        var live = Set<ObjectIdentifier>()
        let windows = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
        for (i, window) in windows.enumerated() {
            walk(window.layer, parent: "w\(i)", depth: 0, parentWorld: .identity, items: &items, live: &live)
        }
        var gone: [String] = []
        for (key, s) in seen where !live.contains(key) {
            gone.append("\"\(s.id)\"")
            seen[key] = nil
        }

        var line = "{\"f\":\(frameIndex),\"t\":\(t6(now)),\"ts\":\(t6(link.targetTimestamp)),\"wall\":\(t6(Date().timeIntervalSince1970))"
        if !touches.isEmpty {
            line += ",\"touch\":[" + touches.joined(separator: ",") + "]"
            touches.removeAll()
        }
        if !items.isEmpty { line += ",\"l\":[" + items.joined(separator: ",") + "]" }
        if !anims.isEmpty {
            line += ",\"anim\":[" + anims.joined(separator: ",") + "]"
            anims.removeAll()
        }
        if !gone.isEmpty { line += ",\"gone\":[" + gone.joined(separator: ",") + "]" }
        line += "}\n"
        write(line)
        frameIndex += 1
    }

    private func walk(_ layer: CALayer, parent: String, depth: Int, parentWorld: CGAffineTransform,
                      items: inout [String], live: inout Set<ObjectIdentifier>) {
        let key = ObjectIdentifier(layer)
        live.insert(key)
        let id = "\(Unmanaged.passUnretained(layer).toOpaque())"
        let p = layer.presentation() ?? layer

        let b = p.bounds
        let ap = p.anchorPoint
        let anchor = CGPoint(x: b.origin.x + ap.x * b.width, y: b.origin.y + ap.y * b.height)
        let t3 = p.transform
        let local = CGAffineTransform(translationX: -anchor.x, y: -anchor.y)
            .concatenating(CATransform3DGetAffineTransform(t3))
            .concatenating(CGAffineTransform(translationX: p.position.x, y: p.position.y))
        let world = local.concatenating(parentWorld)
        let box = b.applying(world)

        let cls = NSStringFromClass(type(of: layer))
        let view = layer.delegate as? UIView
        let viewClass = view.map { NSStringFromClass(type(of: $0)) } ?? ""
        let identity = "\"p\":\"\(parent)\",\"d\":\(depth),\"c\":\"\(esc(cls))\",\"v\":\"\(esc(viewClass))\",\"nm\":\"\(esc(layer.name ?? ""))\""

        var nums: [CGFloat] = [
            box.minX, box.minY, box.width, box.height, b.width, b.height,
            world.a, world.b, world.c, world.d, p.cornerRadius, CGFloat(p.opacity),
            p.isHidden ? 1 : 0, p.masksToBounds ? 1 : 0, CGFloat(p.maskedCorners.rawValue),
            CATransform3DIsAffine(t3) ? 0 : 1,
        ]
        var maskText = ""
        if let m = p.mask {
            let mp = m.presentation() ?? m
            let mf = mp.frame
            nums += [mf.minX, mf.minY, mf.width, mf.height, mp.cornerRadius]
            maskText = ",\"mask\":{\"c\":\"\(esc(NSStringFromClass(type(of: m))))\",\"r\":[\(f(mf.minX)),\(f(mf.minY)),\(f(mf.width)),\(f(mf.height))],\"cr\":\(f(mp.cornerRadius))"
            if let shape = mp as? CAShapeLayer, let path = shape.path {
                let pb = path.boundingBox
                nums += [pb.minX, pb.minY, pb.width, pb.height]
                maskText += ",\"path\":[\(f(pb.minX)),\(f(pb.minY)),\(f(pb.width)),\(f(pb.height))]"
            }
            maskText += "}"
        }
        var radiiText = ""
        if p.responds(to: Self.radiiSelector), let radii = LGIntrospect.text(for: p, key: "cornerRadii"),
           radii.contains(where: { $0 != "0" && $0 != " " }) {
            radiiText = ",\"radii\":\"\(esc(radii))\""
            for part in radii.split(separator: " ") { nums.append(CGFloat(Double(part) ?? 0)) }
        }
        var pathText = ""
        if let shape = p as? CAShapeLayer, let path = shape.path {
            let pb = path.boundingBox
            nums += [pb.minX, pb.minY, pb.width, pb.height]
            pathText = ",\"path\":[\(f(pb.minX)),\(f(pb.minY)),\(f(pb.width)),\(f(pb.height))]"
        }

        var extras: [String] = []
        if Self.isInteresting(cls) {
            extras += props(of: p, cls: type(of: layer), prefix: "")
            extras += mirror(layer, prefix: "swift.")
        }
        if let view, Self.isInteresting(viewClass) {
            extras += props(of: view, cls: type(of: view), prefix: "view.")
            extras += mirror(view, prefix: "view.swift.")
        }
        let extra = extras.joined(separator: ",")

        noteAnimations(on: layer, id: id)

        let old = seen[key]
        let isNew = old == nil || old!.identity != identity
        let extraChanged = isNew || old!.extra != extra
        if extraChanged || !Self.same(old!.nums, nums) {
            var s = "{\"id\":\"\(id)\""
            if isNew { s += "," + identity }
            s += ",\"r\":[\(f(box.minX)),\(f(box.minY)),\(f(box.width)),\(f(box.height))]"
            s += ",\"b\":[\(f(b.width)),\(f(b.height))]"
            if world.a != 1 || world.b != 0 || world.c != 0 || world.d != 1 {
                s += ",\"m\":[\(f4(world.a)),\(f4(world.b)),\(f4(world.c)),\(f4(world.d))]"
            }
            if p.cornerRadius != 0 {
                s += ",\"cr\":\(f(p.cornerRadius)),\"cc\":\"\(p.cornerCurve.rawValue)\""
                if p.maskedCorners.rawValue != 15 { s += ",\"mc\":\(p.maskedCorners.rawValue)" }
            }
            if p.opacity != 1 { s += ",\"o\":\(f4(CGFloat(p.opacity)))" }
            if p.isHidden { s += ",\"h\":1" }
            if p.masksToBounds { s += ",\"clip\":1" }
            if !CATransform3DIsAffine(t3) { s += ",\"t3\":1" }
            s += maskText + pathText + radiiText
            // Properties ride along only when they changed; readers carry
            // the last "x" forward.
            if extraChanged && !extra.isEmpty { s += ",\"x\":{\(extra)}" }
            s += "}"
            items.append(s)
            seen[key] = Seen(id: id, identity: identity, nums: nums, extra: extra)
        }

        var childBase = world
        let st = p.sublayerTransform
        if !CATransform3DIsIdentity(st) {
            childBase = CGAffineTransform(translationX: -anchor.x, y: -anchor.y)
                .concatenating(CATransform3DGetAffineTransform(st))
                .concatenating(CGAffineTransform(translationX: anchor.x, y: anchor.y))
                .concatenating(world)
        }
        for kid in layer.sublayers ?? [] {
            walk(kid, parent: id, depth: depth + 1, parentWorld: childBase, items: &items, live: &live)
        }
    }

    private func props(of object: NSObject, cls: AnyClass, prefix: String) -> [String] {
        let key = ObjectIdentifier(cls)
        let names: [String]
        if let cached = propsByClass[key] {
            names = cached
        } else {
            names = LGIntrospect.printableProperties(of: cls, stopAt: Self.stops)
            propsByClass[key] = names
        }
        return names.compactMap { name in
            LGIntrospect.text(for: object, key: name).map { "\"\(prefix)\(esc(name))\":\"\(esc($0))\"" }
        }
    }

    /// Swift stored properties (UIKit's glass views are Swift classes the
    /// Objective-C runtime cannot list).
    private func mirror(_ object: Any, prefix: String) -> [String] {
        var out: [String] = []
        var m: Mirror? = Mirror(reflecting: object)
        var depth = 0
        while let mm = m, depth < 4 {
            for child in mm.children {
                guard let label = child.label else { continue }
                var text = String(describing: child.value)
                if text.count > 240 { text = String(text.prefix(240)) }
                out.append("\"\(prefix)\(esc(label))\":\"\(esc(text))\"")
            }
            m = mm.superclassMirror
            depth += 1
        }
        return out
    }

    /// Writes each animation once, the frame it is first seen on a layer.
    private func noteAnimations(on layer: CALayer, id: String) {
        guard let keys = layer.animationKeys(), !keys.isEmpty else { return }
        for key in keys {
            guard let a = layer.animation(forKey: key) else { continue }
            let sig = "\(id)|\(key)|\(Unmanaged.passUnretained(a).toOpaque())|\(a.beginTime)"
            guard seenAnimations.insert(sig).inserted else { continue }
            let now = CACurrentMediaTime()
            anims.append("{\"id\":\"\(id)\",\"key\":\"\(esc(key))\",\"now\":\(t6(now)),\"layerNow\":\(t6(layer.convertTime(now, from: nil))),\(describe(a))}")
        }
    }

    private func describe(_ a: CAAnimation) -> String {
        var parts = ["\"cls\":\"\(esc(NSStringFromClass(type(of: a))))\""]
        var names = Self.animationKeys
        for name in LGIntrospect.printableProperties(of: type(of: a), stopAt: [NSObject.self]) where !names.contains(name) {
            names.append(name)
        }
        for name in names where a.responds(to: NSSelectorFromString(name)) {
            if let text = LGIntrospect.text(for: a, key: name) {
                parts.append("\"\(esc(name))\":\"\(esc(text.count > 400 ? String(text.prefix(400)) : text))\"")
            }
        }
        if let tf = a.timingFunction {
            var c1: [Float] = [0, 0], c2: [Float] = [0, 0]
            tf.getControlPoint(at: 1, values: &c1)
            tf.getControlPoint(at: 2, values: &c2)
            parts.append("\"timing\":[\(c1[0]),\(c1[1]),\(c2[0]),\(c2[1])]")
        }
        if let group = a as? CAAnimationGroup, let children = group.animations {
            parts.append("\"children\":[" + children.map { "{" + describe($0) + "}" }.joined(separator: ",") + "]")
        }
        return parts.joined(separator: ",")
    }

    private static func isInteresting(_ name: String) -> Bool {
        interesting.firstMatch(in: name, range: NSRange(name.startIndex..., in: name)) != nil
    }

    private static func same(_ a: [CGFloat], _ b: [CGFloat]) -> Bool {
        guard a.count == b.count else { return false }
        for i in a.indices where abs(a[i] - b[i]) > 0.004 { return false }
        return true
    }

    private func write(_ s: String) {
        handle?.write(Data(s.utf8))
    }

    private func f(_ v: CGFloat) -> String { String(format: "%.2f", Double(v)) }
    private func f4(_ v: CGFloat) -> String { String(format: "%.4f", Double(v)) }
    private func t6(_ v: Double) -> String { String(format: "%.6f", v) }

    private func esc(_ s: String) -> String {
        var out = ""
        for ch in s.unicodeScalars {
            switch ch {
            case "\"": out += "\\\""
            case "\\": out += "\\\\"
            case "\n": out += "\\n"
            case "\r", "\t": out += " "
            default:
                if ch.value < 0x20 { out += " " } else { out.unicodeScalars.append(ch) }
            }
        }
        return out
    }
}

/// Hands every touch event to the tracer on its way into the app.
enum TouchTap {
    private static var installed = false

    static func install() {
        guard !installed,
              let original = class_getInstanceMethod(UIApplication.self, #selector(UIApplication.sendEvent(_:))),
              let tap = class_getInstanceMethod(UIApplication.self, #selector(UIApplication.lgTraceSendEvent(_:)))
        else { return }
        method_exchangeImplementations(original, tap)
        installed = true
    }
}

extension UIApplication {
    @objc func lgTraceSendEvent(_ event: UIEvent) {
        FrameTracer.shared.note(event)
        lgTraceSendEvent(event)
    }
}
