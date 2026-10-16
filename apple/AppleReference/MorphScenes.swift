import SwiftUI

// Glass that changes shape: a circle that opens into a list. The source
// circle sits top-trailing in every scene (MorphSpot), where the trace
// tests tap it.

enum MorphSpot {
    static let size: CGFloat = 56
    static let top: CGFloat = 140
    static let trailing: CGFloat = 24
}

private let rows: [(String, String)] = [
    ("Copy", "doc.on.doc"),
    ("Share", "square.and.arrow.up"),
    ("Rename", "pencil"),
    ("Move", "folder"),
    ("Delete", "trash"),
]

/// The system menu, opened from a glass circle.
struct MenuScene: View {
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Backdrop(name: "mountain.jpg")
            Menu {
                ForEach(rows.indices, id: \.self) { i in
                    Button(rows[i].0, systemImage: rows[i].1) {}
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: MorphSpot.size, height: MorphSpot.size)
                    .glassEffect(.regular.interactive(), in: Circle())
            }
            .padding(.top, MorphSpot.top)
            .padding(.trailing, MorphSpot.trailing)
        }
        .ignoresSafeArea()
    }
}

/// The system menu from a toolbar button, the way Apple's own apps do it.
struct ToolbarMenuScene: View {
    var body: some View {
        NavigationStack {
            Backdrop(name: "mountain.jpg")
                .navigationTitle("Notes")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            ForEach(rows.indices, id: \.self) { i in
                                Button(rows[i].0, systemImage: rows[i].1) {}
                            }
                        } label: {
                            Label("More", systemImage: "ellipsis")
                        }
                    }
                }
        }
    }
}

/// SwiftUI's own morph: one glass shape, matched by glassEffectID, going
/// from a circle to a list panel and back.
struct GlassMorphScene: View {
    @State private var open = false
    @Namespace private var space

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Backdrop(name: "mountain.jpg")
                .contentShape(Rectangle())
                .onTapGesture { withAnimation(.bouncy) { open = false } }
            GlassEffectContainer {
                if open {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(rows.indices, id: \.self) { i in
                            Label(rows[i].0, systemImage: rows[i].1)
                                .font(.system(size: 17))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 20)
                                .frame(height: 48)
                        }
                    }
                    .padding(.vertical, 8)
                    .frame(width: 250)
                    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 30, style: .continuous))
                    .glassEffectID("menu", in: space)
                } else {
                    // A Button: interactive glass swallows a plain tap gesture.
                    Button {
                        withAnimation(.bouncy) { open = true }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: MorphSpot.size, height: MorphSpot.size)
                    }
                    .buttonStyle(.plain)
                    .glassEffect(.regular.interactive(), in: Circle())
                    .glassEffectID("menu", in: space)
                }
            }
            .padding(.top, MorphSpot.top)
            .padding(.trailing, MorphSpot.trailing)
        }
        .ignoresSafeArea()
    }
}
