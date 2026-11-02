import XCTest
@testable import Infinitary

/// INF-1338: the card watchdog counts only once a card's body can answer, so a body still loading on a busy device stays.
/// The readings are the iPad cards journey's late picture card, which this watchdog closed as stopped responding before the fix.
final class CardWatchdogTests: XCTestCase {
    /// Its page took 19 seconds to commit, its web process then ran nothing for 3 seconds, and its body frame loaded
    /// 4 seconds after the page; the look at 22:55:09.33 closed the card because both pings had gone to a body not yet there.
    func testABodyStillLoadingOnABusyIPadIsNeverStalled() {
        var watch = CardWatchdog()
        // 22:54:43.6 to 22:55:04.5: WebKit starts the card's process and loads its page.
        for _ in 0..<10 { XCTAssertEqual(watch.look(shown: false), .wait) }
        XCTAssertEqual(watch.look(shown: true), .ping(1))  // 04.61, the first look after the page finished
        XCTAssertEqual(watch.look(shown: true), .ping(2))  // 06.66, the web process has run nothing since 04.5
        watch.pageAnswered(1); watch.pageAnswered(2)       // 07.55, the page runs both pings
        watch.bodyReady()                                  // 08.64 to 08.67, the body frame commits and loads
        XCTAssertEqual(watch.look(shown: true), .ping(3))  // 09.33, the look that closed the card before the fix
        watch.bodyAnswered(3)
        XCTAssertEqual(watch.look(shown: true), .ping(4))
    }

    /// A body whose script loops as it loads, as the cards fixture's "Stall the card" does on a press, stops its page answering
    /// too, so the card still offers Retry (docs/ios.md: the native watchdog removes a body that stops answering).
    func testAPageThatStopsAnsweringBeforeItsBodyIsReadyIsStalled() {
        var watch = CardWatchdog()
        XCTAssertEqual(watch.look(shown: true), .ping(1))
        watch.pageAnswered(1)
        // The body frame starts loading and its script never returns: neither the page nor the body answers again.
        XCTAssertEqual(watch.look(shown: true), .ping(2))
        XCTAssertEqual(watch.look(shown: true), .ping(3))
        XCTAssertEqual(watch.look(shown: true), .ping(4))
        XCTAssertEqual(watch.look(shown: true), .stalled)
    }

    /// INF-2076: phone run 41007625484's iPad join part, the card the app showed again after its long trip away. Its page
    /// finished loading at 06:33:34.30, then waited 7.9 seconds for WebKit's GPU process, which took 7.7 seconds to launch,
    /// before it ran the card's mount and the three pings at 06:33:42.17. The look at 06:33:41.20 had closed the card first.
    func testALoadedPageWebKitIsStillStartingIsNeverStalled() {
        var watch = CardWatchdog()
        // 06:33:09.7 to 06:33:34.3: WebKit starts the card's process while the app is away, then loads its page.
        for _ in 0..<10 { XCTAssertEqual(watch.look(shown: false), .wait) }
        XCTAssertEqual(watch.look(shown: true), .ping(1))  // 34.88, the first look after the page finished
        XCTAssertEqual(watch.look(shown: true), .ping(2))  // 36.98, the web process has run nothing since 34.30
        XCTAssertEqual(watch.look(shown: true), .ping(3))  // 39.13
        XCTAssertEqual(watch.look(shown: true), .ping(4))  // 41.20, the look that closed the card before the fix
        watch.pageMounted()                                // 42.17, the page runs the card's mount
        for seq in 1...4 { watch.pageAnswered(seq) }       // and then each ping
        watch.bodyReady()
        XCTAssertEqual(watch.look(shown: true), .ping(5))
        watch.bodyAnswered(5)
        XCTAssertEqual(watch.look(shown: true), .ping(6))
    }

    /// A body whose script loops as soon as its page mounts it leaves the page no turn to answer even its first ping, so
    /// once the page has run the card's mount the card still offers Retry.
    func testAPageThatStopsAnsweringOnceItMountsIsStalled() {
        var watch = CardWatchdog()
        XCTAssertEqual(watch.look(shown: true), .ping(1))
        watch.pageMounted()
        XCTAssertEqual(watch.look(shown: true), .ping(2))
        XCTAssertEqual(watch.look(shown: true), .ping(3))
        XCTAssertEqual(watch.look(shown: true), .stalled)
    }
}
