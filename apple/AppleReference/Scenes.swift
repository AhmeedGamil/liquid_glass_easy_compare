import SwiftUI

// Each scene is laid out on the full screen (safe areas ignored) with its
// pieces centred at the fractions in Spots, like the Flutter app.

struct GlassScene: View {
    @State private var offset: CGSize = .zero
    @State private var drag: CGSize = .zero

    private let label = Font.system(size: 15, weight: .semibold)

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            ZStack {
                Backdrop(name: "flower.jpg")

                Text("Glass")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 280, height: 176)
                    .glassEffect(
                        .regular.interactive(),
                        in: RoundedRectangle(cornerRadius: 44, style: .continuous)
                    )
                    .position(
                        x: w / 2 + offset.width + drag.width,
                        y: h * Spots.glassBigY + offset.height + drag.height
                    )
                    .gesture(
                        DragGesture()
                            .onChanged { drag = $0.translation }
                            .onEnded {
                                offset.width += $0.translation.width
                                offset.height += $0.translation.height
                                drag = .zero
                            }
                    )

                Text("Regular")
                    .font(label)
                    .foregroundStyle(.white)
                    .frame(width: 88, height: 88)
                    .glassEffect(.regular.interactive(), in: Circle())
                    .position(x: w * Spots.glassCircleLeftX, y: h * Spots.glassCirclesY)

                Text("Clear")
                    .font(label)
                    .foregroundStyle(.white)
                    .frame(width: 88, height: 88)
                    .glassEffect(.clear.interactive(), in: Circle())
                    .position(x: w * Spots.glassCircleRightX, y: h * Spots.glassCirclesY)

                Text("Capsule")
                    .font(label)
                    .foregroundStyle(.white)
                    .frame(width: 260, height: 64)
                    .glassEffect(.regular, in: Capsule())
                    .position(x: w / 2, y: h * Spots.glassCapsuleY)
            }
            .frame(width: w, height: h)
        }
        .ignoresSafeArea()
    }
}

struct ButtonsScene: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            ZStack {
                Backdrop(name: "mountain.jpg")

                Image(systemName: "heart.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(.white)
                    .frame(width: 88, height: 88)
                    .glassEffect(.regular.interactive(), in: Circle())
                    .position(x: w / 2, y: h * Spots.buttonCircleY)

                Label("Add to library", systemImage: "plus")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 340, height: 64)
                    .glassEffect(.regular.interactive(), in: Capsule())
                    .position(x: w / 2, y: h * Spots.buttonWideY)

                // The real system buttons, sized by the system.
                Button("Glass") {}
                    .buttonStyle(.glass)
                    .controlSize(.large)
                    .position(x: w / 2, y: h * Spots.buttonSystemY)

                Button("Prominent") {}
                    .buttonStyle(.glassProminent)
                    .controlSize(.large)
                    .position(x: w / 2, y: h * Spots.buttonProminentY)
            }
            .frame(width: w, height: h)
        }
        .ignoresSafeArea()
    }
}

struct SliderScene: View {
    @State private var values = Spots.sliderValues

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            ZStack {
                Color.lightPage
                ForEach(values.indices, id: \.self) { i in
                    Slider(value: $values[i])
                        .frame(width: Spots.sliderWidth)
                        .position(x: w / 2, y: h * Spots.sliderY[i])
                }
            }
            .frame(width: w, height: h)
        }
        .ignoresSafeArea()
    }
}

struct ToggleScene: View {
    @State private var values = Spots.toggleValues

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            ZStack {
                Color.lightPage
                ForEach(values.indices, id: \.self) { i in
                    Toggle("", isOn: $values[i])
                        .labelsHidden()
                        .position(x: w / 2, y: h * Spots.toggleY[i])
                }
            }
            .frame(width: w, height: h)
        }
        .ignoresSafeArea()
    }
}

/// Card colours, shared with the Flutter app's feed so both bars bend the
/// same content.
private let cardColors: [(UInt32, UInt32)] = [
    (0xFF3B30, 0xFF9500),
    (0x5856D6, 0x0A84FF),
    (0x34C759, 0x30B0C7),
    (0xFF2D55, 0xAF52DE),
]

struct TabBarScene: View {
    @State private var tab = 0

    var body: some View {
        TabView(selection: $tab) {
            Tab("Home", systemImage: "house.fill", value: 0) { Feed(title: "Home") }
            Tab("Browse", systemImage: "square.grid.2x2.fill", value: 1) { Feed(title: "Browse") }
            Tab("Radio", systemImage: "dot.radiowaves.left.and.right", value: 2) { Feed(title: "Radio") }
            Tab("Library", systemImage: "music.note.list", value: 3) { Feed(title: "Library") }
        }
    }
}

private struct Feed: View {
    let title: String

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text(title)
                    .font(.system(size: 32, weight: .heavy))
                    .foregroundStyle(Color.ink)
                Image(uiImage: UIImage(named: "control_center.jpg") ?? UIImage())
                    .resizable()
                    .scaledToFill()
                    .frame(height: 220)
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                ForEach(0..<14, id: \.self) { i in
                    let c = cardColors[i % cardColors.count]
                    Text("Card \(i + 1)")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(18)
                        .frame(maxWidth: .infinity, minHeight: 120, maxHeight: 120, alignment: .bottomLeading)
                        .background(
                            LinearGradient(
                                colors: [Color(hex: c.0), Color(hex: c.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            in: RoundedRectangle(cornerRadius: 22, style: .continuous)
                        )
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 110)
            .padding(.bottom, 140)
        }
        .ignoresSafeArea(edges: .top)
        .background(Color(hex: 0xE7E5EB).ignoresSafeArea())
    }
}
