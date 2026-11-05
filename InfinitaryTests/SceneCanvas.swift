import SwiftUI
@testable import Infinitary

/// The tests photograph the production painters in a SwiftUI Canvas through the same pen the render thread uses.
extension PhoneCrewPainter {
    static func draw(_ frame: PhoneSceneMotion.Frame, roster: PhoneSceneRoster, now: Double, still: Bool,
                     in context: inout GraphicsContext, palette: CharacterPainter.Palette) {
        context.withCGContext { cg in
            var pen = ScenePen(cg)
            draw(frame, roster: roster, now: now, still: still, in: &pen, palette: palette)
        }
    }
}
