import Foundation

/// Geometry and timing generated from the desktop owners. Decoded once, never in a drawing callback.
struct CharacterCatalog: Decodable, Sendable {
    struct Solid: Decodable, Sendable { let v: [[Double]]; let e: [[Int]]; let ink: [Double]; let nodes: Int? }
    struct Plane: Decodable, Sendable { let radius: Double; let capacity: Int; let inclination: Double; let node: Double; let speedDegPerSec: Double; let phase: Double }
    struct Star: Decodable, Sendable { let x: Double; let y: Double; let mag: Double; let white: Bool?; let nebula: Bool? }
    struct Constellation: Decodable, Sendable { let scale: Double; let offset: [Double]; let stars: [Star]; let slots: [Int]; let order: [Int]; let lines: [[Int]]; let gaze: [Double] }
    let orbit: [String: Double]
    let remoteTrip: [String: Double]
    let program: [String: Double]
    let dependency: [String: Double]
    let firstmateID: String
    let targets: [String: CharacterTargets]
    let durations: [String: Double]
    let fidgets: [String: Double]
    let solids: [String: Solid]
    let planes: [Plane]
    /// The growing ring's lone-crewmate radius and a remote computer's share of home's size.
    let ring: [String: Double]
    let constellations: [String: Constellation]
    let galaxy: [String: Double]
    let algol: [String: Double]
    let flicker: [String: Double]
    /// The waiting-on-you beacon (INF-1543): ring share, breath light, swell, halo, wire strength and breath period.
    let captain: [String: Double]
    /// The background-wait ring (INF-676, INF-1777): banked strength, ring share, arc sweep and rate, and its dashes.
    let wait: [String: Double]
    struct Saturn: Decodable, Sendable {
        let q: Double; let tilt: Double; let globe: Double; let ringA: Double; let ringB: Double
        let spinA: Double; let spinB: Double; let spinBelt: Double; let streamlines: [[Double]]
    }
    let saturn: Saturn
    /// The warp fidgets (INF-1755): settings, schedule, travel table and stars.
    let warp: CharacterWarp.Data
    static let shared: CharacterCatalog = {
        // A generated app resource, checked alongside the theme and contract at the phone gate.
        let url = Bundle.main.url(forResource: "PhoneSceneData.generated", withExtension: "json")!
        return try! JSONDecoder().decode(CharacterCatalog.self, from: Data(contentsOf: url))
    }()
}
