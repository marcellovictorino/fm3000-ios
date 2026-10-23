@testable import FM3000Core
import FM3000Model
import Foundation
import Security

// The test suite, as a plain executable: this Mac has no XCTest or Swift Testing runtime
// (command line tools only). Run it with scripts/test.sh. Each check names the intent it keeps.

var failures: [String] = []
var ran = 0
func check(_ name: String, _ body: () async throws -> Void) async {
    ran += 1
    do { try await body(); print("PASS \(name)") }
    catch { failures.append(name); print("FAIL \(name): \(error)") }
}
struct Failed: Error, CustomStringConvertible { let description: String }
func expect(_ condition: @autoclosure () -> Bool, _ message: String = "expectation failed") throws {
    if !condition() { throw Failed(description: message) }
}
func expectEqual<T: Equatable>(_ a: T, _ b: T, _ message: String = "") throws {
    if a != b { throw Failed(description: "\(a) != \(b) \(message)") }
}
func expectThrows<E: Error & Equatable>(_ error: E, _ body: () throws -> Void) throws {
    do { try body() } catch let thrown as E { try expectEqual(thrown, error); return }
    throw Failed(description: "expected \(error)")
}

func openssl(_ arguments: [String], input: Data? = nil) throws -> Data {
    let process = Process()
    // Prefer OpenSSL 3 (Homebrew): the system LibreSSL writes explicit EC parameters that Security cannot read.
    let binary = ["/opt/homebrew/bin/openssl", "/usr/local/bin/openssl", "/usr/bin/openssl"].first { FileManager.default.isExecutableFile(atPath: $0) } ?? "/usr/bin/openssl"
    process.executableURL = URL(fileURLWithPath: binary)
    process.arguments = arguments
    let out = Pipe(), inPipe = Pipe()
    process.standardOutput = out
    process.standardError = Pipe()
    process.standardInput = inPipe
    try process.run()
    if let input { inPipe.fileHandleForWriting.write(input) }
    try? inPipe.fileHandleForWriting.close()
    let data = out.fileHandleForReading.readDataToEndOfFile()
    process.waitUntilExit()
    guard process.terminationStatus == 0 else { throw Failed(description: "openssl \(arguments.joined(separator: " ")) exited \(process.terminationStatus): \(String(decoding: data, as: UTF8.self))") }
    return data
}

let realisticPin = "q85ENmHTLxPS0v-fxj14M5SKJ1DAwavNPmelU4Sga9U"
let realisticCode = "K7D2yHoOHoEsWc5b36vdfLdMhXNE-nKWzrVLQ1y34Cs"
// A link as the Mac builds it: URLSearchParams percent-encodes the colons and commas.
let macLink = "firstmate3000://join?as=mac&at=100.64.0.5%3A47623&also=192.168.1.20%3A47623%2Cmac.tailnet.ts.net%3A47623&key=\(realisticPin)&code=\(realisticCode)"

// MARK: Pairing link (spec: docs/devices.md "The link")

await check("link: reads a link as the Mac builds it, with also addresses") {
    let link = try PairingLink.parse(macLink)
    try expectEqual(link.kind, .mac)
    try expectEqual(link.at, DialAddress(host: "100.64.0.5", port: 47623))
    try expectEqual(link.also.map(\.description), ["192.168.1.20:47623", "mac.tailnet.ts.net:47623"])
    try expectEqual(link.key, realisticPin)
    try expectEqual(link.code, realisticCode)
}
await check("link: reads Infinitary's scheme and surrounding whitespace") {
    _ = try PairingLink.parse("  " + macLink.replacingOccurrences(of: "firstmate3000", with: "infinitary") + "\n")
}
await check("link: refuses damaged links without repeating the code") {
    let bad = [
        "https://example.com", macLink + "&as=mac", macLink + "&extra=1",
        macLink.replacingOccurrences(of: realisticPin, with: "short"),
        macLink.replacingOccurrences(of: "100.64.0.5%3A47623", with: "nohost"),
        macLink.replacingOccurrences(of: "as=mac", with: "as=robot"),
    ]
    for text in bad {
        do { _ = try PairingLink.parse(text); throw Failed(description: "accepted \(text)") }
        catch let error as PairingLinkError { try expect(!(error.errorDescription ?? "").contains(realisticCode), "error repeats the code") }
    }
}
await check("link: refuses a link for a computer that runs work, and one that needs SSH") {
    try expectThrows(PairingLinkError.wrongKind(.work)) { _ = try PairingLink.parse(macLink.replacingOccurrences(of: "as=mac", with: "as=work")) }
    try expectThrows(PairingLinkError.viaUnsupported) { _ = try PairingLink.parse(macLink + "&via=ssh") }
}
await check("link: reads an IPv6 address") {
    try expectEqual(DialAddress("[fd7a:115c::1]:47623"), DialAddress(host: "fd7a:115c::1", port: 47623))
}

// MARK: Pin and certificate (spec: SHA-256 over SPKI, base64url; self-signed ECDSA P-256)

let scratch = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("fm3000-checks-\(UUID().uuidString)")
try FileManager.default.createDirectory(at: scratch, withIntermediateDirectories: true)
defer { try? FileManager.default.removeItem(at: scratch) }

await check("pin: matches openssl's SHA-256 over the SPKI of an ECDSA P-256 certificate") {
    let key = scratch.appendingPathComponent("k.pem").path, cert = scratch.appendingPathComponent("c.pem").path
    _ = try openssl(["req", "-x509", "-newkey", "ec", "-pkeyopt", "ec_paramgen_curve:prime256v1", "-pkeyopt", "ec_param_enc:named_curve", "-nodes", "-keyout", key, "-out", cert, "-days", "2", "-subj", "/CN=pin-check"])
    let spki = try openssl(["x509", "-in", cert, "-noout", "-pubkey"])
    let der = try openssl(["pkey", "-pubin", "-outform", "der"], input: spki)
    let digest = try openssl(["dgst", "-sha256", "-binary"], input: der)
    let certDER = try openssl(["x509", "-in", cert, "-outform", "der"])
    try expectEqual(Pin.ofCertificateDER(certDER), base64url(digest))
}

await check("certificate: the device's self-signed certificate verifies in openssl and carries its key") {
    let store = try KeychainIdentityStore(scratchKeychainPath: scratch.appendingPathComponent("a.keychain").path)
    let identity = try store.loadOrCreate()
    let der = scratch.appendingPathComponent("device.der"); try identity.certificateDER.write(to: der)
    let pem = scratch.appendingPathComponent("device.pem").path
    _ = try openssl(["x509", "-inform", "der", "-in", der.path, "-out", pem])
    // A self-signed certificate verifies against itself only when its signature is right.
    let verdict = String(decoding: try openssl(["verify", "-CAfile", pem, pem]), as: UTF8.self)
    try expect(verdict.contains("OK"), "openssl verify said: \(verdict)")
    let text = String(decoding: try openssl(["x509", "-in", pem, "-noout", "-text"]), as: UTF8.self)
    try expect(text.contains("ecdsa-with-SHA256") && text.contains("prime256v1"), "not ECDSA P-256")
    let spki = try openssl(["x509", "-in", pem, "-noout", "-pubkey"])
    let digest = try openssl(["dgst", "-sha256", "-binary"], input: try openssl(["pkey", "-pubin", "-outform", "der"], input: spki))
    try expectEqual(identity.pin, base64url(digest))
}

await check("identity: the key and certificate are kept, so every connection shows the same pin") {
    let path = scratch.appendingPathComponent("b.keychain").path
    let first = try KeychainIdentityStore(scratchKeychainPath: path).loadOrCreate()
    let again = try KeychainIdentityStore(scratchKeychainPath: path).loadOrCreate()
    try expectEqual(first.pin, again.pin)
}
await check("identity: after delete a new pin is made, so a removed phone pairs again with a new key") {
    let store = try KeychainIdentityStore(scratchKeychainPath: scratch.appendingPathComponent("c.keychain").path)
    let first = try store.loadOrCreate()
    store.delete()
    let second = try store.loadOrCreate()
    try expect(second.pin != first.pin)
}

// MARK: HTTP answer of /pair

await check("pair: reads the chunked answer Node gives, whole and in pieces") {
    let body = #"{"deviceId":"device-abc","kind":"mac"}"#
    let chunked = "HTTP/1.1 201 Created\r\nContent-Type: application/json\r\nTransfer-Encoding: chunked\r\nConnection: close\r\n\r\n\(String(body.utf8.count, radix: 16))\r\n\(body)\r\n0\r\n\r\n"
    let whole = PairClient.parse(Data(chunked.utf8), complete: false)
    try expectEqual(whole?.status, 201)
    try expectEqual(whole.map { String(decoding: $0.body, as: UTF8.self) }, body)
    try expect(PairClient.parse(Data(chunked.utf8.prefix(chunked.utf8.count - 8)), complete: false) == nil, "an unfinished chunk read as complete")
}
await check("pair: reads a Content-Length answer, and a refusal as the Mac's own words") {
    let body = #"{"refused":"used","reason":"That link was used already."}"#
    let raw = "HTTP/1.1 410 Gone\r\nContent-Length: \(body.utf8.count)\r\n\r\n\(body)"
    let response = try require(PairClient.parse(Data(raw.utf8), complete: false))
    let link = try PairingLink.parse(macLink)
    do { _ = try PairClient.grant(from: response, link: link, address: link.at, name: "iPhone"); throw Failed(description: "no refusal") }
    catch let error as PairError { try expectEqual(error, .refused("used", "That link was used already.")) }
}
func require<T>(_ value: T?) throws -> T { guard let value else { throw Failed(description: "nil") }; return value }
await check("pair: the grant keeps the address that answered first and the others after it") {
    let link = try PairingLink.parse(macLink)
    let response = PairClient.Response(status: 201, body: Data(#"{"deviceId":"device-1","kind":"mac"}"#.utf8))
    let grant = try PairClient.grant(from: response, link: link, address: link.also[0], name: "iPhone")
    try expectEqual(grant.at, link.also[0])
    try expectEqual(grant.addresses.count, 3)
    try expectEqual(grant.homeKey, realisticPin)
}

// MARK: Wire frames (spec: docs/connection.md, docs/contract.json connection)

await check("thread: the row on a card says how many replies it has") {
    try expectEqual(repliesLabel(0), "No replies yet"); try expectEqual(repliesLabel(1), "1 reply"); try expectEqual(repliesLabel(4), "4 replies")
}
await check("tasks: the board groups by status, and layout follows the toggle, else the phone's orientation") {
    func task(_ id: String, _ status: String, _ at: Double) -> BoardTask {
        BoardTask(id: id, key: id, projectId: "p", title: id, kind: "work", status: status, activity: nil, assignee: nil, model: nil, waitingCardId: nil, updatedAt: at)
    }
    let columns = boardColumns([task("a", "open", 1), task("b", "active", 2), task("c", "open", 5), task("d", "done", 3)])
    try expectEqual(columns.map(\.title), ["Open", "Active", "Done"])
    try expectEqual(columns[0].tasks.map(\.id), ["c", "a"])
    try expectEqual(boardColumns([task("x", "dropped", 1)]).map(\.title), ["Open", "Active", "Done", "Dropped"])
    try expect(tasksLayout(picked: nil, landscape: true) == .board && tasksLayout(picked: nil, landscape: false) == .list)
    try expect(tasksLayout(picked: .board, landscape: false) == .board && tasksLayout(picked: .list, landscape: true) == .list)
}
await check("task detail: a detail and the crewmate's record decode, and only readable lines show") {
    let detail = try JSONDecoder().decode(TaskDetail.self, from: Data(#"{"id":"t","key":"FM-1","title":"T","goal":null,"status":"active","activity":"running","workPosture":{"state":"active","reason":"turn"},"assignee":null,"model":null,"modelLabel":"Sonnet","waitingCardId":"c1","outcome":null,"problem":null,"delivery":{"mode":"direct-pr","prNumber":42,"prUrl":"https://x/42","ci":"green","runChecks":{"runId":7,"name":"CI","state":"passed","at":1}},"updatedAt":5,"unknown":{"a":1}}"#.utf8))
    try expectEqual(detail.delivery?.prNumber, 42); try expectEqual(detail.workPosture?.reason, "turn")
    let log = try JSONDecoder().decode(CrewLog.self, from: Data(#"{"taskId":"t","earlier":0,"revision":"r","lines":[{"kind":"said","id":"1","at":1,"text":"hi"},{"kind":"tool","id":"2","at":2,"name":"Read","target":"f","reading":"r","result":null},{"kind":"sent","id":"3","at":3,"from":"captain","text":"go","queued":false},{"kind":"report","id":"4","at":4,"summary":"S","text":"T"}]}"#.utf8))
    try expectEqual(log.lines.compactMap { $0.readable?.who }, ["Crewmate", "You", "Report"])
}
await check("attachments: text only stays a string; images and text files take the Mac's object form; binary files are refused") {
    try expectEqual(Attachments.payload(text: "hi", attachments: []), .string("hi"))
    let png = try Attachments.image(name: "a.png", mimeType: "image/png", data: Data([1, 2, 3]))
    let note = try Attachments.textFile(name: "n.md", data: Data("# note".utf8))
    guard case .object(let o) = Attachments.payload(text: "see", attachments: [png, note]) else { throw Failed(description: "not an object") }
    try expectEqual(o["text"], .string("see"))
    guard case .array(let images)? = o["images"], case .array(let files)? = o["files"] else { throw Failed(description: "missing images or files") }
    try expectEqual(images.count, 1); try expectEqual(files, [.object(["name": .string("n.md"), "text": .string("# note")])])
    do { _ = try Attachments.textFile(name: "x.bin", data: Data([0xff, 0xfe, 0x00])); throw Failed(description: "a binary file was taken") } catch AttachmentError.notText {}
    do { _ = try Attachments.image(name: "a.heic", mimeType: "image/heic", data: Data([1])); throw Failed(description: "heic was taken") } catch AttachmentError.notImage {}
}
await check("chat: oldest first whatever order they arrive in, captain on the right, replies on the left with a label") {
    let items = [
        ChatItem(id: "3", who: "crewmate", text: "done", at: 300), ChatItem(id: "1", who: "captain", text: "go", at: 100),
        ChatItem(id: "2", who: "firstmate", text: "ok", at: 200), ChatItem(id: "2b", who: "host", text: "saved", at: 200),
    ]
    let ordered = ChatItem.chronological(items)
    try expectEqual(ordered.map(\.id), ["1", "2", "2b", "3"])
    try expectEqual(ordered.map(\.isMine), [true, false, false, false])
    try expectEqual(ordered.map(\.label), ["You", "Firstmate", "Infinitary", "Crewmate"])
    let message = try JSONDecoder().decode(ThreadMessage.self, from: Data(#"{"id":5,"cardId":"c","who":"firstmate","text":"hi","at":9,"answers":[]}"#.utf8))
    try expectEqual(message.chatItem.who, "firstmate")
}
await check("tasks: a project pill counts its tasks, and picking one filters the board, an unknown or no pick shows all") {
    func task(_ id: String, _ project: String) -> BoardTask {
        BoardTask(id: id, key: id, projectId: project, title: id, kind: "work", status: "open", activity: nil, assignee: nil, model: nil, waitingCardId: nil, updatedAt: 1)
    }
    func project(_ id: String, archived: Bool = false) throws -> BoardProject {
        try JSONDecoder().decode(BoardProject.self, from: Data(#"{"id":"\#(id)","key":"K","name":"P\#(id)","archived":\#(archived),"counts":{"needsYou":0,"open":0,"active":0}}"#.utf8))
    }
    let board = Board(projects: [try project("a"), try project("b"), try project("old", archived: true)], tasks: [task("1", "a"), task("2", "a"), task("3", "b")])
    try expectEqual(board.projectPills.map { "\($0.project.id):\($0.count)" }, ["a:2", "b:1"])
    try expectEqual(board.filtered(by: "a").tasks.map(\.id), ["1", "2"])
    try expectEqual(board.filtered(by: nil).tasks.count, 3); try expectEqual(board.filtered(by: "gone").tasks.count, 3)
}
await check("wire: hello says protocol 11.0.0, view, ios, arm64, and carries a cursor when it has one") {
    let hello = try JSONDecoder().decode(JSONValue.self, from: Data(HomeFrame.hello(cursor: Cursor(epoch: "e1", seq: 7)).utf8))
    guard case .object(let o) = hello else { throw Failed(description: "not an object") }
    try expectEqual(o["t"], .string("hello")); try expectEqual(o["protocolVersion"], .string("11.0.0"))
    try expectEqual(o["as"], .string("view")); try expectEqual(o["system"], .string("ios")); try expectEqual(o["chip"], .string("arm64"))
    try expectEqual(o["cursor"], .object(["epoch": .string("e1"), "seq": .number(7)]))
    try expect(!HomeFrame.hello(cursor: nil).contains("cursor"))
}
await check("wire: reads welcome, push and results, ignoring fields it does not know") {
    let welcome = try HomeFrame.parse(#"{"t":"welcome","protocolVersion":"11.0.0","epoch":"abc","seq":4,"catchUp":"reload","access":"read","name":"MacBook","spellings":["fm"],"future":1}"#)
    try expectEqual(welcome, .welcome(Welcome(protocolVersion: "11.0.0", epoch: "abc", seq: 4, catchUp: "reload", access: .read, name: "MacBook")))
    try expectEqual(try HomeFrame.parse(#"{"t":"push","seq":5,"channel":"inf:cards","payload":[]}"#), .push(Push(seq: 5, channel: "inf:cards", payload: .array([]))))
    try expectEqual(try HomeFrame.parse(#"{"t":"result","id":3,"ok":true,"value":{"ok":true}}"#), .result(id: 3, value: .object(["ok": .bool(true)]), error: nil))
    try expectEqual(try HomeFrame.parse(#"{"t":"result","id":4,"ok":false,"error":"There is no such card."}"#), .result(id: 4, value: nil, error: "There is no such card."))
    try expectEqual(try HomeFrame.parse(#"{"t":"something-later"}"#), .ignored)
}
await check("wire: a card as the Mac lists it decodes, and unknown fields are ignored") {
    let json = #"[{"id":"c1","taskId":"t1","author":"crewmate","priority":2,"title":"Merge?","meta":"m","body":"<p>x</p>","actions":[{"id":"merge","label":"Merge","variant":"primary","default":true,"effect":{"kind":"settle","mode":"merge"}}],"status":"ready","createdAt":1792614758929,"risk":{"declared":{}},"pictures":[]}]"#
    let cards = try JSONDecoder().decode(JSONValue.self, from: Data(json.utf8)).decoded([Card].self)
    try expectEqual(cards.first?.actions.first?.isDefault, true)
    try expectEqual(cards.first?.createdAt, 1792614758929)
}

// MARK: Card text

await check("text: a card's HTML reads as plain text, without scripts, figures or markup") {
    let html = "<p>The <strong>settings</strong> change &amp; tests are green.</p><ul><li>One</li><li>Two &lt;3</li></ul><figure><svg><text>chart</text></svg></figure><script>alert(1)</script>"
    try expectEqual(HTMLText.plain(html), "The settings change & tests are green.\n\n• One\n• Two <3")
}

// MARK: Client against a scripted transport (the real sockets are covered by scripts/e2e.sh)

final class ScriptedTransport: FrameTransport, @unchecked Sendable {
    var openError: Error?
    private(set) var sent: [String] = []
    private var queue: [TransportMessage] = []
    private var waiter: CheckedContinuation<TransportMessage, Error>?
    private let lock = NSLock()
    var onSend: ((String) -> Void)?
    func open() async throws { if let openError { throw openError } }
    func send(_ text: String) async throws { lock.lock(); sent.append(text); lock.unlock(); onSend?(text) }
    func receive() async throws -> TransportMessage {
        try await withCheckedThrowingContinuation { continuation in
            lock.lock()
            if !queue.isEmpty { let next = queue.removeFirst(); lock.unlock(); continuation.resume(returning: next) }
            else { waiter = continuation; lock.unlock() }
        }
    }
    func feed(_ message: TransportMessage) {
        lock.lock()
        if let waiter { self.waiter = nil; lock.unlock(); waiter.resume(returning: message) } else { queue.append(message); lock.unlock() }
    }
    func close() {}
}
let welcomeText = #"{"t":"welcome","protocolVersion":"11.0.0","epoch":"E","seq":10,"catchUp":"reload","access":"full","name":"Mac"}"#
let addr = DialAddress(host: "127.0.0.1", port: 1)

func nextEvent(_ client: HomeClient) async -> ClientEvent? {
    var iterator = client.events.makeAsyncIterator()
    return await iterator.next()
}

await check("client: answers match their request by id, whatever order the Mac finishes them") {
    let transport = ScriptedTransport()
    transport.feed(.text(welcomeText))
    let client = HomeClient(addresses: [addr]) { _ in transport }
    _ = try await client.connect()
    async let first = client.invoke("inf:a"), second = client.invoke("inf:b")
    while transport.sent.count < 3 { try await Task.sleep(nanoseconds: 10_000_000) }
    transport.feed(.text(#"{"t":"result","id":2,"ok":true,"value":"B"}"#))
    transport.feed(.text(#"{"t":"result","id":1,"ok":true,"value":"A"}"#))
    let (a, b) = try await (first, second)
    try expectEqual(a, .string("A")); try expectEqual(b, .string("B"))
}
await check("client: the Mac's refusal comes back as its own words") {
    let transport = ScriptedTransport()
    transport.feed(.text(welcomeText))
    let client = HomeClient(addresses: [addr]) { _ in transport }
    _ = try await client.connect()
    transport.onSend = { text in if text.contains("\"id\":1") { transport.feed(.text(#"{"t":"result","id":1,"ok":false,"error":"There is no such card."}"#)) } }
    do { _ = try await client.invoke("inf:cards:act"); throw Failed(description: "no failure") }
    catch let failure as InvokeFailure { try expectEqual(failure.reason, "There is no such card.") }
}
await check("client: a push already seen after a replay is dropped, and the cursor follows the newest") {
    let transport = ScriptedTransport()
    transport.feed(.text(#"{"t":"welcome","protocolVersion":"11.0.0","epoch":"E","seq":10,"catchUp":"replay","access":"full"}"#))
    transport.feed(.text(#"{"t":"push","seq":9,"channel":"inf:cards","payload":1}"#))
    transport.feed(.text(#"{"t":"push","seq":11,"channel":"inf:cards","payload":2}"#))
    let client = HomeClient(addresses: [addr], cursor: Cursor(epoch: "E", seq: 10)) { _ in transport }
    _ = try await client.connect()
    guard case .push(let push)? = await nextEvent(client) else { throw Failed(description: "no push") }
    try expectEqual(push.seq, 11)
    try expectEqual(await client.cursor, Cursor(epoch: "E", seq: 11))
    try expect(transport.sent.first?.contains(#""cursor":{"epoch":"E","seq":10}"#) == true, "hello lacked the cursor")
}
await check("client: a new epoch is a reload, so the cursor restarts at the welcome's number") {
    let transport = ScriptedTransport()
    transport.feed(.text(#"{"t":"welcome","protocolVersion":"11.0.0","epoch":"NEW","seq":3,"catchUp":"reload","access":"full"}"#))
    let client = HomeClient(addresses: [addr], cursor: Cursor(epoch: "OLD", seq: 99)) { _ in transport }
    _ = try await client.connect()
    try expectEqual(await client.cursor, Cursor(epoch: "NEW", seq: 3))
}
await check("client: close code 4401 is reported as unpaired, and pending requests fail") {
    let transport = ScriptedTransport()
    transport.feed(.text(welcomeText))
    let client = HomeClient(addresses: [addr]) { _ in transport }
    _ = try await client.connect()
    async let pending = client.invoke("inf:slow")
    while transport.sent.count < 2 { try await Task.sleep(nanoseconds: 10_000_000) }
    transport.feed(.closed(code: 4401))
    do { _ = try await pending; throw Failed(description: "answered") } catch let error as WireError { try expectEqual(error, .unpaired) }
    try expectEqual(await nextEvent(client), .closed(.unpaired))
}
await check("client: tries the next address when one does not answer, but never after a key mismatch") {
    let dead = ScriptedTransport(); dead.openError = DialError.unreachable("down")
    let live = ScriptedTransport(); live.feed(.text(welcomeText))
    let client = HomeClient(addresses: [addr, DialAddress(host: "127.0.0.2", port: 1)]) { $0.host == "127.0.0.1" ? dead : live }
    _ = try await client.connect()
    let wrong = ScriptedTransport(); wrong.openError = DialError.homeKeyMismatch
    let never = ScriptedTransport(); never.feed(.text(welcomeText))
    let guarded = HomeClient(addresses: [addr, DialAddress(host: "127.0.0.2", port: 1)]) { $0.host == "127.0.0.1" ? wrong : never }
    do { _ = try await guarded.connect(); throw Failed(description: "connected") } catch let error as DialError { try expectEqual(error, .homeKeyMismatch) }
    try expect(never.sent.isEmpty, "a second address was tried after a key mismatch")
}

// MARK: The model: a phone removed on the Mac forgets the Mac (spec: lost-phone note)

await check("model: when the Mac removes this phone (4401) the app forgets the Mac and asks to pair again") {
    let grant = Grant(at: addr, also: [], homeKey: realisticPin, deviceId: "device-1", kind: .mac, name: "iPhone")
    let grants = MemoryGrantStore(grant)
    let identities = try KeychainIdentityStore(scratchKeychainPath: scratch.appendingPathComponent("m.keychain").path)
    let transport = ScriptedTransport()
    transport.feed(.text(welcomeText))
    transport.onSend = { text in
        if text.contains("inf:cards:list") { transport.feed(.text(#"{"t":"result","id":1,"ok":true,"value":[]}"#)); transport.feed(.closed(code: 4401)) }
    }
    let model = await AppModel(grants: grants, identities: identities, deviceName: "iPhone", retryDelays: [0.05]) { _, _, _ in transport }
    await model.start()
    for _ in 0..<100 { if await model.phase == .unpaired { break }; try await Task.sleep(nanoseconds: 50_000_000) }
    try expectEqual(await model.phase, .unpaired)
    try expect(grants.load() == nil, "the grant was kept")
    let notice = await model.notice
    try expect(notice?.contains("removed") == true, "no explanation shown")
}


// The captain asked for the desktop's Open pull requests panel on the phone: same groups and age buckets as its panel.tsx.
await check("open pull requests: grouped and aged like the desktop panel") {
    let stored = """
    {"status":"ok","changes":[
     {"host":"github.com","project":"owner/app","number":7,"label":"#7","title":"Ready","url":"https://x/7","draft":false,"checks":"passed","updatedAt":null,"createdAt":"2026-10-23T09:00:00Z"},
     {"host":"github.com","project":"owner/app","number":6,"title":"Draft passes","url":"https://x/6","draft":true,"checks":"passed","updatedAt":null,"createdAt":"2026-10-20T09:00:00Z"},
     {"host":"github.com","project":"owner/app","number":5,"title":"Broken","url":"https://x/5","draft":false,"checks":"failed","updatedAt":null,"createdAt":"2026-09-01T09:00:00.123Z"},
     {"host":"github.com","project":"owner/app","number":4,"title":"No date","url":"https://x/4","draft":false,"checks":"pending","updatedAt":null}]}
    """
    let prs = try JSONDecoder().decode(OpenPRs.self, from: Data(stored.utf8))
    try expectEqual(prs.changes.map { OpenPRs.group(of: $0).rawValue }, ["ready", "waiting", "attention", "waiting"])
    var calendar = Calendar(identifier: .gregorian); calendar.timeZone = TimeZone(identifier: "UTC")!
    let now = ISO8601DateFormatter().date(from: "2026-10-23T15:00:00Z")!
    try expectEqual(prs.changes.map { OpenPRs.age(of: $0, now: now, calendar: calendar)?.rawValue ?? "none" }, ["today", "week", "older", "none"])
    try expectEqual(prs.changes[0].projectName, "app")
    try expectEqual(prs.changes[2].shownLabel, "#5")
    try expectEqual(prs.failedCount, 1)
    try expectEqual(OpenPRs(status: "signed-out", changes: []).blocked, "Sign in to GitHub's command line on this Mac")
}

print(failures.isEmpty ? "ALL \(ran) CHECKS PASSED" : "\(failures.count) of \(ran) FAILED: \(failures.joined(separator: "; "))")
exit(failures.isEmpty ? 0 : 1)
