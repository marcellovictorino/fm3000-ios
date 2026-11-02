import Foundation

extension PhoneSceneRoster {
    /// Each crewmate's remembered orbit and seat on one computer, and each program ring's seat on the first orbit,
    /// chosen as the desktop chooses them (orbit.ts: spawn, fillPlaneVacancies, respacePlanes, openPlaneSlot).
    /// A seat is an angle at the scene's start; the plane's own turn is added when it is drawn.
    struct SeatBook {
        struct Seat { var plane: Int; var slot: Double; let order: Int }
        private enum Occupant { case crew(String), mark(String) }
        private(set) var crew: [String: Seat] = [:]
        private(set) var marks: [String: Double] = [:]
        private var hidden = Set<String>()
        private var next = 0
        private static let tau = 2 * Double.pi
        private var planes: [CharacterCatalog.Plane] { CharacterCatalog.shared.planes }

        init() {}
        /// A new scene, as the desktop's boot roster: everyone seated in creation order, then evenly spaced.
        init(crew ids: [String], marks roots: [String]) {
            for id in ids { crew[id] = Seat(plane: arrivalPlane(), slot: 0, order: next); next += 1 }
            for id in roots { marks[id] = 0 }
            space()
        }

        var isEmpty: Bool { crew.isEmpty && marks.isEmpty }
        /// Crew on each orbit: what sizes the growing ring.
        var counts: [Int] { planes.indices.map { plane in crew.values.filter { $0.plane == plane }.count } }

        /// One read of the board: departures leave first, then each arrival takes its seat in creation order, then new program rings.
        mutating func update(crew ids: [String], marks roots: [String]) {
            let present = Set(ids), rooted = Set(roots)
            for (id, _) in roster() where !present.contains(id) {
                crew[id] = nil
                fillVacancies(); respace()
            }
            let ended = marks.keys.filter { !rooted.contains($0) }
            if !ended.isEmpty {
                for id in ended { marks[id] = nil }
                respace()
            }
            for id in ids where crew[id] == nil {
                let empty = isEmpty, plane = arrivalPlane()
                crew[id] = Seat(plane: plane, slot: openSlot(plane), order: next); next += 1
                respace()
                // An empty stage spaces its first arrival from the orbit's own phase.
                if empty { space() }
            }
            let started = roots.filter { marks[$0] == nil }.sorted()
            if !started.isEmpty {
                let empty = isEmpty
                for id in started { marks[id] = openSlot(0) }
                respace()
                if empty { space() }
            }
        }

        /// Drawing seats remember visible order independently of the logical book's allocation and growth.
        mutating func synchronize(_ logical: Self) {
            var changed = false
            for id in Array(crew.keys) where logical.crew[id] == nil { crew[id] = nil; hidden.remove(id); changed = true }
            for item in logical.roster() {
                if crew[item.id]?.plane != item.seat.plane {
                    crew[item.id] = Seat(plane: item.seat.plane, slot: openSlot(item.seat.plane), order: item.seat.order)
                    changed = true
                }
            }
            for id in Array(marks.keys) where logical.marks[id] == nil { marks[id] = nil; changed = true }
            for id in logical.marks.keys.sorted() where marks[id] == nil { marks[id] = openSlot(0); changed = true }
            if changed { respace() }
        }
        /// Only occupants actually drawn here take angular space. Returning crew enter the widest visible gap.
        mutating func show(excluding next: Set<String>) {
            guard hidden != next else { return }
            for item in roster() where hidden.contains(item.id) && !next.contains(item.id) {
                let slot = openSlot(item.seat.plane)
                crew[item.id]?.slot = slot
                hidden.remove(item.id)
            }
            hidden = next
            respace()
        }

        private func roster() -> [(id: String, seat: Seat)] {
            crew.map { (id: $0.key, seat: $0.value) }.sorted { $0.seat.order < $1.seat.order }
        }
        /// Fill each orbit's seats before opening the next; past both, the orbit with fewer crew, the first on a tie.
        private func arrivalPlane() -> Int {
            let counts = counts
            return counts.indices.first { counts[$0] < planes[$0].capacity } ?? counts.indices.min { counts[$0] < counts[$1] } ?? 0
        }
        /// Every occupant of a plane: its crew in arrival order, and on the first orbit the program rings too.
        private func occupants(_ plane: Int) -> [(who: Occupant, slot: Double)] {
            let crew = roster().filter { $0.seat.plane == plane && !hidden.contains($0.id) }.map { (who: Occupant.crew($0.id), slot: $0.seat.slot) }
            return plane == 0 ? crew + marks.keys.sorted().map { (who: Occupant.mark($0), slot: marks[$0]!) } : crew
        }
        private mutating func set(_ who: Occupant, _ slot: Double) {
            switch who {
            case .crew(let id): crew[id]?.slot = slot
            case .mark(let id): marks[id] = slot
            }
        }
        private static func wrapped(_ angle: Double) -> Double {
            (angle.truncatingRemainder(dividingBy: tau) + tau).truncatingRemainder(dividingBy: tau)
        }
        /// A crewmate leaving an earlier orbit is replaced by the oldest on a later one.
        private mutating func fillVacancies() {
            for plane in 0..<(planes.count - 1) {
                var count = crew.values.filter { $0.plane == plane }.count
                while count < planes[plane].capacity {
                    let roster = roster()
                    guard let mover = (plane + 1..<planes.count).compactMap({ source in roster.first { $0.seat.plane == source } }).first else { break }
                    let slot = openSlot(plane)
                    crew[mover.id]?.slot = slot; crew[mover.id]?.plane = plane
                    count += 1
                }
            }
        }
        /// Every orbit keeps its occupants evenly spaced, in their order around it, turned as little as possible.
        private mutating func respace() {
            for plane in planes.indices {
                let members = occupants(plane).enumerated()
                    .sorted { let a = Self.wrapped($0.element.slot), b = Self.wrapped($1.element.slot); return a == b ? $0.offset < $1.offset : a < b }
                    .map(\.element)
                let m = Double(members.count)
                if members.isEmpty { continue }
                var sine = 0.0, cosine = 0.0
                for (i, member) in members.enumerated() {
                    let d = member.slot - Double(i) / m * Self.tau
                    sine += sin(d); cosine += cos(d)
                }
                let base = atan2(sine, cosine)
                for (i, member) in members.enumerated() {
                    let target = base + Double(i) / m * Self.tau
                    set(member.who, target + ((member.slot - target) / Self.tau).rounded() * Self.tau)
                }
            }
        }
        /// Where a newcomer enters: the middle of the widest gap, program rings counted.
        private func openSlot(_ plane: Int) -> Double {
            let slots = occupants(plane).map { Self.wrapped($0.slot) }.sorted()
            var best = planes[plane].phase, widest = 0.0
            for i in slots.indices {
                let a = slots[i], b = slots[(i + 1) % slots.count] + (i == slots.count - 1 ? Self.tau : 0)
                if b - a > widest { widest = b - a; best = (a + b) / 2 }
            }
            return best
        }
        /// Each orbit evenly from its phase, the program rings spread among the crew, never bunched.
        private mutating func space() {
            for plane in planes.indices {
                let crew = roster().filter { $0.seat.plane == plane }.map { Occupant.crew($0.id) }
                let rings = plane == 0 ? marks.keys.sorted().map { Occupant.mark($0) } : []
                let total = crew.count + rings.count
                var c = 0, m = 0
                for i in 0..<total {
                    let due = m < rings.count && i >= Int((Double(m) + 0.5) * Double(total) / Double(rings.count))
                    let who: Occupant
                    if (due || c >= crew.count) && m < rings.count { who = rings[m]; m += 1 } else { who = crew[c]; c += 1 }
                    set(who, Double(i) / Double(total) * Self.tau + planes[plane].phase)
                }
            }
        }
    }
}
