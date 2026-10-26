import Combine
import FM3000Core
import FM3000Model
import Foundation

// fm-probe: the app's own model, driven from the command line.
//   fm-probe --state <dir> pair '<firstmate3000://join?...>'
//   fm-probe --state <dir> scenario [--fake-pid <pid>]
//   fm-probe --state <dir> status
// Its keychain is a scratch file under <dir>, never the person's keychains.

func fail(_ message: String, code: Int32 = 1) -> Never {
    FileHandle.standardError.write(Data("FAIL \(message)\n".utf8))
    exit(code)
}
func step(_ text: String) { print("STEP \(text)"); fflush(stdout) }

var args = Array(CommandLine.arguments.dropFirst())
func take(_ flag: String) -> String? {
    guard let index = args.firstIndex(of: flag), index + 1 < args.count else { return nil }
    let value = args[index + 1]
    args.removeSubrange(index...(index + 1))
    return value
}
guard let stateDir = take("--state") else { fail("usage: fm-probe --state <dir> pair|scenario|status", code: 2) }
let fakePid = take("--fake-pid").flatMap { Int32($0) }
guard let command = args.first else { fail("missing command", code: 2) }

try FileManager.default.createDirectory(atPath: stateDir, withIntermediateDirectories: true)

@MainActor func makeModel() throws -> AppModel {
    let identities = try KeychainIdentityStore(scratchKeychainPath: stateDir + "/probe.keychain")
    let grants = FileGrantStore(url: URL(fileURLWithPath: stateDir + "/grant.json"))
    return AppModel(grants: grants, identities: identities, deviceName: "fm3000 probe", retryDelays: [0.2, 0.5, 1])
}

@MainActor var model: AppModel!
@MainActor func until(_ what: String, seconds: Double = 8, _ condition: () -> Bool) async {
    let deadline = Date().addingTimeInterval(seconds)
    while !condition() {
        if Date() > deadline { fail("timed out waiting for \(what); phase=\(model.phase) notice=\(model.notice ?? "-") cards=\(model.cards.count)") }
        try? await Task.sleep(nanoseconds: 50_000_000)
    }
    step(what)
}

@MainActor func main() async {
    do { model = try makeModel() } catch { fail("keychain: \(error.localizedDescription)") }
    switch command {
    case "pair":
        guard args.count >= 2 else { fail("missing link", code: 2) }
        if await model.pair(withLink: args[1]) { print("PAIRED"); model.stop() }
        else { print("REFUSED \(model.notice ?? "")"); exit(3) }
    case "status":
        print(model.isPaired ? "paired" : "unpaired")
    case "scenario":
        guard model.isPaired else { fail("not paired") }
        model.start()
        await until("connected with full access") { model.phase == .connected(mac: "fake home", access: .full) }
        guard let learned = FileGrantStore(url: URL(fileURLWithPath: stateDir + "/grant.json")).load(), learned.also.contains(where: { $0.host == "100.64.0.9" }), !learned.addresses.contains(where: { $0.host == "127.0.0.1" && $0 != learned.at }) else { fail("the Mac's updated private-network address was not learned") }
        step("learned the Mac's updated private-network address, not its loopback")
        await until("two open cards listed") { model.cards.count == 2 }
        guard let merge = model.cards.first(where: { $0.id == "card-merge-1" }), let question = model.cards.first(where: { $0.id == "card-question-1" }) else { fail("fixture cards missing") }
        guard HTMLText.plain(merge.body).contains("• Checks passed") else { fail("card body did not read as text: \(HTMLText.plain(merge.body))") }
        step("card body reads as text")
        guard model.modelName(for: merge) == "Claude Sonnet 5.5" else { fail("card model pill is \(String(describing: model.modelName(for: merge)))") }

        guard await model.send("hello from the phone") else { fail("converse refused: \(model.notice ?? "")") }
        await until("first mate's reply in the main chat, after what you sent") {
            model.chat.map(\.who) == ["captain", "firstmate"] && model.chat.last?.text == "Got it: hello from the phone"
        }
        guard await model.send("quiet: ping") else { fail("converse refused: \(model.notice ?? "")") }
        await until("reply found in the saved last turn when no push announced it", seconds: 8) { model.chat.last?.text == "Got it: quiet: ping" && !model.awaitingReply }
        await until("pushed card from converse") { model.cards.contains { $0.title == "Firstmate answered" } }

        let waitingBefore = CardsTally(cards: model.cards, board: model.board).waiting
        guard await model.putAside(question), model.cards.first(where: { $0.id == question.id })?.isPutAside == true else { fail("put aside did not take: \(model.notice ?? "")") }
        await until("the Mac keeps the card put aside, counted apart from Waiting on you") {
            let tally = CardsTally(cards: model.cards, board: model.board)
            return tally.aside == 1 && tally.waiting == waitingBefore - 1 && filterCards(model.cards, by: .aside, board: model.board).map(\.id) == [question.id]
        }
        guard await model.putAside(question) else { fail("put aside again: \(model.notice ?? "")") }
        await until("put aside again") { model.cards.first { $0.id == question.id }?.isPutAside == true }
        guard await model.putAside(question, false) else { fail("bring back: \(model.notice ?? "")") }
        await until("brought back by hand") { model.cards.first { $0.id == question.id }?.isPutAside == false }
        guard await model.putAside(question) else { fail("put aside before the reply: \(model.notice ?? "")") }
        await until("put aside before the reply") { model.cards.first { $0.id == question.id }?.isPutAside == true }
        guard await model.reply("Call it Bridge", to: question) else { fail("reply refused: \(model.notice ?? "")") }
        guard model.cards.first(where: { $0.id == question.id })?.authorIsAnswering == true else { fail("the Mac did not say the card awaits its author after the reply") }
        step("typing indicator on while the thread waits")
        await until("own reply in thread") { model.threads[question.id]?.contains { $0.who == "captain" && $0.text == "Call it Bridge" } == true }
        await until("pushed thread message") { model.threads[question.id]?.contains { $0.who == "firstmate" && $0.text == "Noted: Call it Bridge" } == true }
        await until("the Mac stops saying the card awaits its author") { model.cards.first(where: { $0.id == question.id })?.authorIsAnswering != true }
        step("typing indicator off once answered")
        await until("the put-aside card comes back by itself when its crewmate answers") {
            model.cards.first { $0.id == question.id }?.isPutAside == false && CardsTally(cards: model.cards, board: model.board).aside == 0
        }

        guard let action = merge.actions.first(where: { $0.isDefault }) else { fail("no default action") }
        await model.choose(action, on: merge, words: "Ship it after lunch")
        guard model.answered[merge.id]?.label == action.label, model.isClosed(merge), model.choosing[merge.id] == nil else { fail("the choice was not kept as answered and closed") }
        step("choice kept: the card shows what was chosen and counts as closed")
        await until("card gone after action") { !model.cards.contains { $0.id == "card-merge-1" } }

        if let other = model.cards.first(where: { $0.id == question.id }) {
            guard await model.close(other), !model.cards.contains(where: { $0.id == question.id }) else { fail("closing a card did not take: \(model.notice ?? "")") }
            step("card closed without a choice")
        }
        await model.refreshBoard()
        guard model.board?.tasks.first?.key == "FM-1" else { fail("board missing FM-1") }
        step("task board read")
        guard let program = model.board?.tasks.first(where: { $0.program == true }), let all = model.board?.tasks, foldPrograms(all).count == all.count - 2, program.partsLine == "1 of 2 parts done" else { fail("the program's parts were not folded into its tile") }
        step("a program's two parts fold into its one tile")
        guard model.board?.tasks.first?.model == "sonnet" else { fail("board task lost its model") }
        step("model pill for a card and a task")
        guard let first = model.board?.tasks.first, model.modelName(for: first) == "Claude Sonnet 5.5 (Medium)" else { fail("task pill is \(String(describing: model.board?.tasks.first.flatMap { model.modelName(for: $0) }))") }
        step("task pill carries the reasoning effort")
        guard let quota = await model.quota(), let claude = quota.shown.first, claude.fiveHour?.percentRemaining == 78, claude.weekly?.percentRemaining == 44 else { fail("quota snapshot not read") }
        step("quota read: Claude 78% / 44% left")
        await model.refreshFeed()
        guard model.feed.contains(where: { $0.text == "You chose Merge." }) else { fail("feed missing the choice") }
        step("feed read")
        guard model.board?.tasks.first(where: { $0.id == "task-2" })?.notStarted == true else { fail("queued task not seen as not started") }
        guard await model.steer("task-2", "hello") == false, model.steerProblem?.contains("has not started") == true else { fail("steer to a queued task: \(String(describing: model.steerProblem))") }
        step("steering a queued task is refused with the Mac's reason")
        guard await model.startTask("task-2"), model.board?.tasks.first(where: { $0.id == "task-2" })?.notStarted == false else { fail("start did not take") }
        guard await model.steer("task-2", "hello") else { fail("steer refused after start: \(String(describing: model.steerProblem))") }
        step("started the queued task, then the message went through")

        // The fake Mac pings every 0.4 s here (30 s on a real one): a live connection answers and is never dropped.
        var phases: [ConnectionPhase] = []
        let watch = model.$phase.dropFirst().sink { phases.append($0) }
        try? await Task.sleep(nanoseconds: 2_500_000_000)
        watch.cancel()
        guard phases.isEmpty else { fail("the connection flapped while the Mac pinged: \(phases)") }
        step("stayed connected across the Mac's pings")

        if let fakePid {
            kill(fakePid, SIGUSR1)
            await until("noticed the drop") { if case .offline = model.phase { return true } else if case .connecting = model.phase { return true } else { return false } }
            await until("reconnected", seconds: 15) { model.phase == .connected(mac: "fake home", access: .full) }
            await until("card raised while away arrived", seconds: 10) { model.cards.contains { $0.id == "card-missed" } }
        }
        await model.unpair()
        guard !model.isPaired else { fail("still paired after unpair") }
        step("left and forgot the Mac")
        print("SCENARIO OK")
    default:
        fail("unknown command \(command)", code: 2)
    }
    exit(0)
}

Task { await main() }
RunLoop.main.run()
