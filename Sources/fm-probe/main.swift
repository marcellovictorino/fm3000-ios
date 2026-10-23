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
        await until("two open cards listed") { model.cards.count == 2 }
        guard let merge = model.cards.first(where: { $0.id == "card-merge-1" }), let question = model.cards.first(where: { $0.id == "card-question-1" }) else { fail("fixture cards missing") }
        guard HTMLText.plain(merge.body).contains("• Checks passed") else { fail("card body did not read as text: \(HTMLText.plain(merge.body))") }
        step("card body reads as text")

        guard await model.send("hello from the phone") else { fail("converse refused: \(model.notice ?? "")") }
        await until("first mate's reply in the main chat, after what you sent") {
            model.chat.map(\.who) == ["captain", "firstmate", "captain", "firstmate"] && model.chat.last?.text == "Got it: hello from the phone"
        }
        await until("pushed card from converse") { model.cards.contains { $0.title == "Firstmate answered" } }

        guard await model.reply("Call it Bridge", to: question) else { fail("reply refused: \(model.notice ?? "")") }
        await until("own reply in thread") { model.threads[question.id]?.contains { $0.who == "captain" && $0.text == "Call it Bridge" } == true }
        await until("pushed thread message") { model.threads[question.id]?.contains { $0.who == "firstmate" && $0.text == "Noted: Call it Bridge" } == true }

        guard let action = merge.actions.first(where: { $0.isDefault }) else { fail("no default action") }
        await model.choose(action, on: merge)
        await until("card gone after action") { !model.cards.contains { $0.id == "card-merge-1" } }

        await model.refreshBoard()
        guard model.board?.tasks.first?.key == "FM-1" else { fail("board missing FM-1") }
        step("task board read")
        await model.refreshFeed()
        guard model.feed.contains(where: { $0.text == "You chose Merge." }) else { fail("feed missing the choice") }
        step("feed read")

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
