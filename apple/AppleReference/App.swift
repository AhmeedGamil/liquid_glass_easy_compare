import SwiftUI

@main
struct AppleReferenceApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}

enum CompareScene: String, CaseIterable, Identifiable {
    case glass, buttons, slider, toggle, tabbar

    var id: String { rawValue }

    /// Whether the scene sits on a photo (white caption) or a light page.
    var onPhoto: Bool { self == .glass || self == .buttons }
}

struct RootView: View {
    // The UI tests launch straight into a scene through the SCENE variable;
    // without it the app opens on the scene list, for poking at by hand.
    @State private var scene: CompareScene? =
        ProcessInfo.processInfo.environment["SCENE"].flatMap(CompareScene.init(rawValue:))

    var body: some View {
        if let scene {
            ZStack(alignment: .top) {
                switch scene {
                case .glass: GlassScene()
                case .buttons: ButtonsScene()
                case .slider: SliderScene()
                case .toggle: ToggleScene()
                case .tabbar: TabBarScene()
                }
                Caption(scene: scene) { self.scene = nil }
            }
        } else {
            HomeView { scene = $0 }
        }
    }
}

struct Caption: View {
    let scene: CompareScene
    let onBack: () -> Void

    var body: some View {
        let ink: Color = scene.onPhoto ? .white : .ink
        ZStack {
            Text("APPLE · \(scene.rawValue)")
                .font(.system(size: 13, weight: .bold))
                .tracking(1.2)
                .foregroundStyle(ink)
            HStack {
                Text("‹ Scenes")
                    .font(.system(size: 15))
                    .foregroundStyle(ink)
                    .onTapGesture(perform: onBack)
                Spacer()
            }
            .padding(.leading, 16)
        }
        .frame(height: 32)
        .padding(.top, 4)
    }
}

struct HomeView: View {
    let onOpen: (CompareScene) -> Void

    var body: some View {
        ZStack {
            Backdrop(name: "flower.jpg")
            VStack(spacing: 14) {
                Text("Apple Liquid Glass")
                    .font(.system(size: 30, weight: .heavy))
                    .foregroundStyle(.white)
                    .padding(.bottom, 10)
                ForEach(CompareScene.allCases) { s in
                    Text(s.rawValue)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 240, height: 52)
                        .glassEffect(.regular.interactive(), in: Capsule())
                        .onTapGesture { onOpen(s) }
                }
            }
        }
    }
}
