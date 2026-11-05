import Foundation
import Testing
@testable import InfinitaryKit

/// INF-1926, the captain's pick of the desktop's summary in a sheet: the phone says each task's facts in the desktop's
/// words. scripts/generate-phone-scene.ts records `taskFactsOf` and the summary's line for rows in each state it reads.
struct PhoneTaskFactsTests {
    private struct Fixture: Decodable { let now: Double; let modelNames: [String: String]; let cases: [Case] }
    private struct Case: Decodable { let name: String; let row: PhoneTask; let facts: Facts }
    private struct Status: Decodable {
        let mark: String; let word: String; let reason: String
        let outOfReach: Bool?; let wait: String?; let since: Double?; let waitsOn: [String]?
    }
    private struct Now: Decodable { let text: String; let at: Double }
    private struct Span: Decodable { let startedAt: Double; let finishedAt: Double?; let joint: String }
    private struct Checks: Decodable { let problem: String?; let dot: String; let words: String; let state: String; let at: Double?; let span: Span? }
    private struct Review: Decodable { let dot: String; let words: String }
    private struct Change: Decodable { let noun: String; let label: String?; let url: String? }
    private struct Delivery: Decodable { let change: Change?; let checks: Checks?; let review: Review? }
    private struct PlanWords: Decodable { let count: String; let skipped: Int; let current: String }
    private struct PlanDot: Decodable { let label: String; let short: String; let state: String; let group: Int? }
    private struct Facts: Decodable {
        let key: String; let title: String; let label: String; let status: Status
        /// The desktop leaves Now and the plan out until the record answers, and reads them null after.
        let read: Bool
        let now: Now?; let plan: PhoneTask.Plan?
        let model: String?; let tier: String?; let reasoningWords: String?; let reason: String?
        let delivery: Delivery?
        let nowAge: String?; let planAge: String?; let checksWords: String?; let checksAgo: String?
        /// INF-2528, the captain's direction B: the summary's footer says the checks as one state with its time.
        let checksStateWords: String?
        let planWords: PlanWords?; let planDots: [PlanDot]?

        enum CodingKeys: String, CodingKey {
            case key, title, label, status, now, plan, model, tier, reasoningWords, reason, delivery, nowAge, planAge,
                 checksWords, checksAgo, checksStateWords, planWords, planDots
        }
        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            key = try c.decode(String.self, forKey: .key)
            title = try c.decode(String.self, forKey: .title)
            label = try c.decode(String.self, forKey: .label)
            status = try c.decode(Status.self, forKey: .status)
            read = c.contains(.now)
            now = try c.decodeIfPresent(Now.self, forKey: .now)
            plan = try c.decodeIfPresent(PhoneTask.Plan.self, forKey: .plan)
            model = try c.decodeIfPresent(String.self, forKey: .model)
            tier = try c.decodeIfPresent(String.self, forKey: .tier)
            reasoningWords = try c.decodeIfPresent(String.self, forKey: .reasoningWords)
            reason = try c.decodeIfPresent(String.self, forKey: .reason)
            delivery = try c.decodeIfPresent(Delivery.self, forKey: .delivery)
            nowAge = try c.decodeIfPresent(String.self, forKey: .nowAge)
            planAge = try c.decodeIfPresent(String.self, forKey: .planAge)
            checksWords = try c.decodeIfPresent(String.self, forKey: .checksWords)
            checksAgo = try c.decodeIfPresent(String.self, forKey: .checksAgo)
            checksStateWords = try c.decodeIfPresent(String.self, forKey: .checksStateWords)
            planWords = try c.decodeIfPresent(PlanWords.self, forKey: .planWords)
            planDots = try c.decodeIfPresent([PlanDot].self, forKey: .planDots)
        }
    }

    private func fixture() throws -> Fixture {
        let url = Bundle.module.url(forResource: "PhoneTaskFacts.generated", withExtension: "json", subdirectory: "Fixtures")!
        return try JSONDecoder().decode(Fixture.self, from: Data(contentsOf: url))
    }

    @Test func saysEachTaskAsTheDesktopSummaryDoes() throws {
        let sample = try fixture()
        #expect(sample.cases.count > 40)
        for item in sample.cases {
            let want = item.facts
            let facts = PhoneTaskFacts(item.row) { model in
                sample.modelNames[model] ?? model.firstIndex(of: "/").map { String(model[model.index(after: $0)...]) } ?? model
            }
            let named = Comment(rawValue: item.name)
            #expect(facts.key == want.key, named)
            #expect(facts.title == want.title, named)
            #expect(facts.status.mark == want.status.mark, named)
            #expect(facts.status.word == want.status.word, named)
            #expect(facts.status.reason == want.status.reason, named)
            #expect(facts.status.label == want.label, named)
            #expect(facts.status.outOfReach == (want.status.outOfReach ?? false), named)
            #expect(facts.status.wait == want.status.wait, named)
            #expect(facts.status.since == want.status.since, named)
            #expect(facts.status.waitsOn == want.status.waitsOn, named)
            #expect(facts.read == want.read, named)
            #expect(facts.now?.text == want.now?.text, named)
            #expect(facts.now?.at == want.now?.at, named)
            #expect(facts.now.map { PhoneTaskFacts.relativeAge($0.at, now: sample.now) } == want.nowAge, named)
            #expect(facts.plan?.items.map(\.label) == want.plan?.items.map(\.label), named)
            #expect(facts.plan?.items.map(\.state) == want.plan?.items.map(\.state), named)
            #expect(facts.model == want.model, named)
            #expect(facts.tier == want.tier, named)
            #expect(facts.reasoning == want.reasoningWords, named)
            #expect(facts.reason == want.reason, named)
            #expect((facts.delivery == nil) == (want.delivery == nil), named)
            #expect(facts.delivery?.change?.noun == want.delivery?.change?.noun, named)
            #expect(facts.delivery?.change?.label == want.delivery?.change?.label, named)
            #expect(facts.delivery?.change?.url == want.delivery?.change?.url, named)
            let checks = facts.delivery?.checks
            #expect(checks?.problem == want.delivery?.checks?.problem, named)
            #expect(checks?.dot == want.delivery?.checks?.dot, named)
            #expect(checks?.words == want.delivery?.checks?.words, named)
            #expect(checks?.state == want.delivery?.checks?.state, named)
            #expect(checks?.at == want.delivery?.checks?.at, named)
            #expect(checks?.span?.startedAt == want.delivery?.checks?.span?.startedAt, named)
            #expect(checks?.span?.finishedAt == want.delivery?.checks?.span?.finishedAt, named)
            #expect(checks?.span?.joint == want.delivery?.checks?.span?.joint, named)
            #expect(checks?.spanWords(now: sample.now) == want.checksWords, named)
            #expect(checks?.stateWords(now: sample.now) == want.checksStateWords, named)
            #expect(checks?.span?.finishedAt.map { PhoneTaskFacts.checksFinishedAgo($0, now: sample.now) } == want.checksAgo, named)
            #expect(facts.delivery?.review?.dot == want.delivery?.review?.dot, named)
            #expect(facts.delivery?.review?.words == want.delivery?.review?.words, named)
            guard let plan = facts.plan, !plan.items.isEmpty else {
                #expect(want.planWords == nil, named)
                continue
            }
            let counts = PhoneTaskFacts.planCounts(plan.items)
            #expect("\(counts.done) of \(counts.total)" == want.planWords?.count, named)
            #expect(counts.skipped == want.planWords?.skipped, named)
            #expect((counts.current ?? (counts.done == counts.total ? "All done" : "Between items")) == want.planWords?.current, named)
            #expect(plan.at.map { PhoneTaskFacts.relativeAge($0, now: sample.now) } == want.planAge, named)
            let dots = PhoneTaskFacts.planNodes(plan.items)
            #expect(dots.map(\.label) == want.planDots?.map(\.label), named)
            #expect(dots.map(\.short) == want.planDots?.map(\.short), named)
            #expect(dots.map(\.state) == want.planDots?.map(\.state), named)
            #expect(dots.map(\.group) == want.planDots?.map(\.group), named)
        }
    }
}
