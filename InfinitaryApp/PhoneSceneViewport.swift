import CoreGraphics

/// One owner for the scene's placement: roster growth preserves the viewed world point,
/// while a new connection centers home. The scroll view must not also resize-anchor its content.
struct PhoneSceneViewport: Equatable {
    let generation: Int
    let size: CGSize
    let content: CGSize
    let offset: CGSize
    let home: CGPoint

    init(scene: CGSize, home: CGPoint, size: CGSize, generation: Int) {
        self.generation = generation; self.size = size
        // Even a wide viewport can center home without asking for a negative scroll offset.
        let margin = max(0, size.width / 2 - home.x)
        content = CGSize(width: max(scene.width + margin * 2, size.width), height: max(scene.height, size.height))
        offset = CGSize(width: (content.width - scene.width) / 2, height: (content.height - scene.height) / 2)
        self.home = CGPoint(x: home.x + offset.width, y: home.y + offset.height)
    }

    var centered: CGPoint { clamped(CGPoint(x: home.x - size.width / 2, y: home.y - size.height / 2)) }

    func preserving(_ point: CGPoint, from previous: Self) -> CGPoint {
        guard generation == previous.generation else { return centered }
        let x = point.x + home.x - previous.home.x - (size.width - previous.size.width) / 2
        let y = point.y + home.y - previous.home.y - (size.height - previous.size.height) / 2
        return clamped(CGPoint(x: x, y: y))
    }

    func clamped(_ point: CGPoint) -> CGPoint {
        CGPoint(x: min(max(0, content.width - size.width), max(0, point.x)),
                y: min(max(0, content.height - size.height), max(0, point.y)))
    }
}
