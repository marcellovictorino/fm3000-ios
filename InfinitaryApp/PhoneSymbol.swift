import SwiftUI
import UIKit

/// The approved phone preview's Lucide outlines, drawn once as native template images.
/// System bars supply their own tint, size and accessibility treatment.
enum PhoneSymbol: CaseIterable {
    case cards, activity, tasks, computer, scan, settings
    /// INF-1312: the welcome screen's ways in, a row's chevron and the key box's copy mark.
    case link, at, chevron, copy

    @MainActor var image: Image { Image(uiImage: Self.images[self]!) }

    @MainActor private static let images: [PhoneSymbol: UIImage] = Dictionary(uniqueKeysWithValues: allCases.map { symbol in
        let image = UIGraphicsImageRenderer(size: CGSize(width: 24, height: 24)).image { renderer in
            let context = renderer.cgContext
            context.setStrokeColor(UIColor.label.cgColor)
            context.setLineWidth(1.5)
            context.setLineCap(.round); context.setLineJoin(.round)
            func line(_ points: [CGPoint]) {
                guard let first = points.first else { return }
                context.move(to: first)
                for point in points.dropFirst() { context.addLine(to: point) }
                context.strokePath()
            }
            func points(_ values: [(CGFloat, CGFloat)]) { line(values.map { CGPoint(x: $0.0, y: $0.1) }) }
            switch symbol {
            case .cards, .copy:
                context.addPath(UIBezierPath(roundedRect: CGRect(x: 8, y: 8, width: 14, height: 14), cornerRadius: 2).cgPath)
                context.strokePath()
                points([(4, 16), (4, 4), (18, 4)])
            case .activity: points([(2, 12), (6, 12), (9, 3), (15, 21), (18, 12), (22, 12)])
            case .tasks:
                points([(3, 7), (5, 9), (9, 5)]); points([(3, 17), (5, 19), (9, 15)])
                for y: CGFloat in [6, 12, 18] { points([(13, y), (21, y)]) }
            case .computer:
                context.addPath(UIBezierPath(roundedRect: CGRect(x: 4, y: 5, width: 16, height: 11), cornerRadius: 2).cgPath)
                context.strokePath(); points([(4, 16), (2, 20), (22, 20), (20, 16)])
            case .scan:
                points([(3, 7), (3, 3), (7, 3)]); points([(17, 3), (21, 3), (21, 7)])
                points([(21, 17), (21, 21), (17, 21)]); points([(7, 21), (3, 21), (3, 17)])
                points([(7, 12), (17, 12)])
            case .link:
                // Lucide's link-2: two open ends of a chain and the bar between them.
                let left = UIBezierPath(); left.move(to: CGPoint(x: 9, y: 17)); left.addLine(to: CGPoint(x: 7, y: 17))
                left.addArc(withCenter: CGPoint(x: 7, y: 12), radius: 5, startAngle: .pi / 2, endAngle: 3 * .pi / 2, clockwise: true)
                left.addLine(to: CGPoint(x: 9, y: 7))
                let right = UIBezierPath(); right.move(to: CGPoint(x: 15, y: 7)); right.addLine(to: CGPoint(x: 17, y: 7))
                right.addArc(withCenter: CGPoint(x: 17, y: 12), radius: 5, startAngle: -.pi / 2, endAngle: .pi / 2, clockwise: true)
                right.addLine(to: CGPoint(x: 15, y: 17))
                context.addPath(left.cgPath); context.addPath(right.cgPath); context.strokePath()
                points([(8, 12), (16, 12)])
            case .at:
                // Lucide's at-sign: a ring, and the stroke that leaves it to curl round it.
                context.addEllipse(in: CGRect(x: 8, y: 8, width: 8, height: 8)); context.strokePath()
                let tail = UIBezierPath(); tail.move(to: CGPoint(x: 16, y: 8)); tail.addLine(to: CGPoint(x: 16, y: 13))
                tail.addArc(withCenter: CGPoint(x: 19, y: 13), radius: 3, startAngle: .pi, endAngle: 0, clockwise: false)
                tail.addLine(to: CGPoint(x: 22, y: 12))
                tail.addArc(withCenter: CGPoint(x: 12, y: 12), radius: 10, startAngle: 0, endAngle: atan2(8, 6), clockwise: false)
                context.addPath(tail.cgPath); context.strokePath()
            case .chevron: points([(9, 6), (15, 12), (9, 18)])
            case .settings:
                // Lucide's settings: a six-toothed wheel whose every corner is rounded at radius 2, around a hub.
                context.addEllipse(in: CGRect(x: 9, y: 9, width: 6, height: 6)); context.strokePath()
                let corners: [(CGFloat, CGFloat)] = [
                    (9.78, 2), (9.78, 5.33), (7.35, 6.74), (4.47, 5.08), (2.25, 8.92), (5.12, 10.59), (5.13, 13.41), (2.25, 15.08),
                    (4.47, 18.92), (7.35, 17.26), (9.78, 18.67), (9.78, 22), (14.22, 22), (14.22, 18.67), (16.65, 17.26), (19.53, 18.92),
                    (21.75, 15.07), (18.87, 13.41), (18.87, 10.59), (21.75, 8.92), (19.53, 5.08), (16.65, 6.74), (14.22, 5.33), (14.22, 2),
                ]
                context.move(to: CGPoint(x: 12, y: 2))
                for (index, corner) in corners.enumerated() {
                    let next = corners[(index + 1) % corners.count]
                    context.addArc(tangent1End: CGPoint(x: corner.0, y: corner.1), tangent2End: CGPoint(x: next.0, y: next.1), radius: 2)
                }
                context.closePath(); context.strokePath()
            }
        }.withRenderingMode(.alwaysTemplate)
        return (symbol, image)
    })
}
