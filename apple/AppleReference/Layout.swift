import SwiftUI
import UIKit

// Mirrors package_app/lib/layout.dart and CompareUITests/SceneTests.swift.
// Change all three together, or the scripted gestures land on different
// spots in the two apps.

enum Spots {
    static let glassBigY: CGFloat = 0.36
    static let glassCirclesY: CGFloat = 0.64
    static let glassCircleLeftX: CGFloat = 0.28
    static let glassCircleRightX: CGFloat = 0.72
    static let glassCapsuleY: CGFloat = 0.80

    static let buttonCircleY: CGFloat = 0.30
    static let buttonWideY: CGFloat = 0.44
    static let buttonSystemY: CGFloat = 0.60
    static let buttonProminentY: CGFloat = 0.72

    static let sliderY: [CGFloat] = [0.38, 0.50, 0.62]
    static let sliderValues: [Double] = [0.65, 0.40, 0.80]
    static let sliderWidth: CGFloat = 300

    static let toggleY: [CGFloat] = [0.40, 0.50, 0.60]
    static let toggleValues: [Bool] = [true, false, true]
}

extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }

    static let lightPage = Color(hex: 0xE9E9EC)
    static let ink = Color(hex: 0x11131A)
}

/// A photo from Backgrounds, filling the screen like Flutter's
/// `BoxFit.cover`.
struct Backdrop: View {
    let name: String

    var body: some View {
        GeometryReader { geo in
            Image(uiImage: UIImage(named: name) ?? UIImage())
                .resizable()
                .scaledToFill()
                .frame(width: geo.size.width, height: geo.size.height)
                .clipped()
        }
        .ignoresSafeArea()
    }
}
