import Foundation
import Testing
@testable import InfinitaryKit

struct CardValuesTests {
    /// INF-499 #4: a reply admitted on the phone must fit the computer's UTF-16 budget.
    @Test func replyBudgetMatchesThePublishedWire() {
        let emoji = "😀"
        let fitting = String(repeating: emoji, count: PhoneLimits.reply / emoji.utf16.count)
        #expect(PhoneCard.canSendReply("Keep the northern entrance clear."))
        #expect(PhoneCard.canSendReply(fitting))
        #expect(!PhoneCard.canSendReply(fitting + emoji))
        #expect(!PhoneCard.canSendReply(" \n "))
    }

    /// INF-1670: the stuck alert takes a reply on the phone as on the Mac, answered by the first mate;
    /// the host's other cards still take none.
    @Test func stuckAlertTakesAReply() throws {
        let alert = try PhoneCard(.object([
            "id": .string("card-stall-a99caa29"), "title": .string("Move integration secrets has been stuck for 1h 21m"),
            "author": .string("host"), "taskId": .string("a99caa29"), "answeredBy": .string("firstmate"),
            "body": .string("<p>It stopped with nothing running and no question for you.</p>"), "actions": .array([])
        ]))
        #expect(alert.takesReplies)
        let signIn = try PhoneCard(.object([
            "id": .string("card-auth-claude"), "title": .string("Sign in to Claude again"), "author": .string("host"),
            "taskId": .string("a99caa29"), "body": .string("<p>Your sign-in ended.</p>"), "actions": .array([])
        ]))
        #expect(!signIn.takesReplies)
    }

    /// INF-1610: the "You asked" line reads the message the Mac sent, folds a long one onto one run of words,
    /// keeps its paragraphs when opened, and names a message of pictures alone.
    @Test func askedLineReadsTheSavedMessage() throws {
        let message = "did something change about how we order the cards in the stack?\n\nkeep minimize as it is."
        let at = Date(timeIntervalSince1970: 1_793_200_200)
        let card = try PhoneCard(.object([
            "id": .string("card-1404-merge"), "title": .string("Keep a replied card in its place"),
            "author": .string("crewmate"), "body": .string("<p>Merged.</p>"), "actions": .array([]),
            "asked": .object(["at": .number(at.timeIntervalSince1970 * 1000), "text": .string(message)])
        ]))
        let asked = try #require(card.asked)
        #expect(asked.at == at)
        #expect(asked.words(open: false) == "\u{201C}did something change about how we order the cards in the stack? keep minimize as it is.\u{201D}")
        #expect(asked.words(open: true) == "\u{201C}\(message)\u{201D}")
        #expect(asked.label(now: at).hasPrefix("You asked · "))
        #expect(asked.label(now: at.addingTimeInterval(3 * 86_400)).contains(","))
        #expect(PhoneAsked(at: at, text: " ").words(open: false) == "A picture")
        let plain = try PhoneCard(.object([
            "id": .string("card-fm-1"), "title": .string("A note"), "author": .string("firstmate"),
            "body": .string("<p>Nothing asked.</p>"), "actions": .array([])
        ]))
        #expect(plain.asked == nil)
    }

    /// INF-499 #2: the actual body-choice receipt has a frame evidence actor, not a captain.
    @Test func frameChoiceNamesItsAuthorWithoutRewritingTheReceipt() throws {
        let card = try PhoneCard(.object([
            "id": .string("card-fm-phone-conversation"), "title": .string("Read the harbour chart"),
            "author": .string("firstmate"), "body": .string("<p>The survey is ready for your reply.</p>"),
            "actions": .array([]), "ending": .object([
                "how": .string("chose"), "actionId": .string("body"), "label": .string("Keep this chart"), "by": .string("frame")
            ])
        ]))
        #expect(card.endingForWords["by"] == .string("firstmate"))
        #expect(card.value["ending"]["by"] == .string("frame"))
    }

    /// INF-499 #6: a saved reading is not presented as fresh question evidence.
    @Test func savedDraftCarriesItsProvenance() throws {
        let card = try PhoneCard(.object([
            "id": .string("card-fm-phone-last-reading"), "title": .string("Keep the harbour note"),
            "author": .string("firstmate"), "body": .string("<p>Keep the harbour note.</p>"),
            "actions": .array([]), "offerId": .string("last-reading-offer")
        ]))
        let reading: PhoneJSON = .object([
            "answers": .array([]), "of": .number(0), "answered": .number(0), "questions": .array([])
        ])
        let fresh = card.submission(reading: reading)
        #expect(fresh["reading"] == .string("fresh"))
        #expect(fresh["questions"] == .array([]))
        let saved = card.submission(reading: reading, fresh: false)
        #expect(saved["reading"] == .string("fallback"))
        #expect(saved["questions"] == .null)
        #expect(saved["questionsGap"] == .string("no-fresh-reading"))
        #expect(saved["offerId"] == card.value["offerId"])
    }
}
