import InfinitaryKit
import SwiftUI

/// The Tasks board: the desktop's columns, read only. Upright, each column is about 80% of the width so the next
/// one shows at the edge; in landscape the board takes the full width with about three columns side by side.
struct PhoneTaskBoard: View {
    static let columns: [PhoneTaskGroup] = [.waiting, .backlog, .queued, .working, .landed]

    let board: PhoneBoard?
    let tasks: [PhoneTask]
    let aside: [PhoneCard]
    let landscape: Bool
    let width: CGFloat
    @Binding var column: PhoneTaskGroup?
    let open: (PhoneTask) -> Void
    let restore: (PhoneCard) -> Void
    let canRestore: Bool

    private var columnWidth: CGFloat {
        landscape ? (width - PhoneTheme.space4 * 2 - PhoneTheme.space3 * 2) / 3.15 : width * 0.8
    }

    var body: some View {
        let groups = board?.groups ?? [:]
        ScrollView(.horizontal) {
            LazyHStack(alignment: .top, spacing: PhoneTheme.space3) {
                ForEach(Self.columns, id: \.rawValue) { group in
                    let members = tasks.filter { groups[$0.id] == group }
                    let cards = group == .waiting ? aside : []
                    BoardColumn(group: group, count: members.count + cards.count) {
                        ForEach(members) { task in card(task, groups: groups) }
                        ForEach(cards) { card in asideCard(card) }
                    }.frame(width: columnWidth).id(group)
                }
            }.scrollTargetLayout().padding(.horizontal, PhoneTheme.space4)
        }
        .scrollTargetBehavior(.viewAligned)
        .scrollPosition(id: $column, anchor: .leading)
        .scrollIndicators(.hidden)
        .accessibilityIdentifier("tasks-board")
    }

    private func card(_ task: PhoneTask, groups: [String: PhoneTaskGroup]) -> some View {
        let project = board?.projects.first(where: { $0.id == task.projectId })?.name
        return Button { open(task) } label: {
            VStack(alignment: .leading, spacing: PhoneTheme.space2) {
                HStack(spacing: PhoneTheme.space2) {
                    Text(task.key).font(PhoneFont.mono).foregroundStyle(PhoneTheme.muted).fixedSize()
                    Spacer(minLength: 0)
                    if let project { Text(project).font(PhoneFont.mono).foregroundStyle(PhoneTheme.muted).lineLimit(1) }
                }
                Text(task.title).font(PhoneFont.body).foregroundStyle(PhoneTheme.text)
                    .lineLimit(3).multilineTextAlignment(.leading)
                if let wait = task.queueWait {
                    Text(wait.line).font(PhoneFont.mono).foregroundStyle(PhoneTheme.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }.padding(PhoneTheme.space3).frame(maxWidth: .infinity, alignment: .leading)
                .background(PhoneTheme.surface, in: RoundedRectangle(cornerRadius: PhoneTheme.controlRadius))
                .overlay { RoundedRectangle(cornerRadius: PhoneTheme.controlRadius).strokeBorder(PhoneTheme.line) }
                .contentShape(Rectangle())
        }.buttonStyle(.plain).accessibilityIdentifier("task-\(task.id)")
            .accessibilityLabel([task.key, task.title, project, task.state].compactMap(\.self).joined(separator: ", "))
    }

    private func asideCard(_ card: PhoneCard) -> some View {
        Button { restore(card) } label: {
            Text(card.title).font(PhoneFont.body).foregroundStyle(PhoneTheme.text)
                .lineLimit(3).multilineTextAlignment(.leading)
                .padding(PhoneTheme.space3).frame(maxWidth: .infinity, alignment: .leading)
                .background(PhoneTheme.surface, in: RoundedRectangle(cornerRadius: PhoneTheme.controlRadius))
                .overlay { RoundedRectangle(cornerRadius: PhoneTheme.controlRadius).strokeBorder(PhoneTheme.accent) }
        }.buttonStyle(.plain).disabled(!canRestore).accessibilityIdentifier("minimized-card")
            .accessibilityHint("Brings the card back")
    }
}

private struct BoardColumn<Content: View>: View {
    let group: PhoneTaskGroup
    let count: Int
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: PhoneTheme.space2) {
            HStack(spacing: PhoneTheme.space2) {
                Text(group.title).font(Font.custom("SpaceGrotesk-Light", size: 11, relativeTo: .caption2).weight(.medium))
                    .textCase(.uppercase).tracking(1)
                Text("\(count)").font(PhoneFont.micro)
                Spacer()
            }.foregroundStyle(PhoneTheme.muted).frame(minHeight: 32)
                .accessibilityElement(children: .combine).accessibilityIdentifier("column-\(group.rawValue)")
            ScrollView {
                LazyVStack(spacing: PhoneTheme.space2) {
                    content
                    if count == 0 { Text("Nothing here.").font(PhoneFont.caption).foregroundStyle(PhoneTheme.secondary).frame(maxWidth: .infinity, alignment: .leading) }
                }.padding(.bottom, PhoneTheme.space4)
            }.scrollIndicators(.hidden)
        }
    }
}

/// The Board/List switch and the project pills; they share one row when the width allows (landscape).
struct PhoneTaskControls: View {
    @Binding var showBoard: Bool
    @Binding var project: String?
    let projects: [PhoneBoard.Project]
    let wide: Bool

    var body: some View {
        let picker = Picker("View", selection: $showBoard) {
            Text("Board").tag(true)
            Text("List").tag(false)
        }.pickerStyle(.segmented).frame(width: 180).accessibilityIdentifier("tasks-view")
        Group {
            if wide { HStack(spacing: PhoneTheme.space3) { picker; pills } }
            else { VStack(alignment: .leading, spacing: PhoneTheme.space2) { picker; pills } }
        }.padding(.horizontal, PhoneTheme.space4).padding(.vertical, PhoneTheme.space2)
    }

    private var pills: some View {
        ScrollView(.horizontal) {
            HStack(spacing: PhoneTheme.space2) {
                pill("All", id: nil)
                ForEach(projects, id: \.id) { pill($0.name, id: $0.id) }
            }
        }.scrollIndicators(.hidden)
    }

    private func pill(_ title: String, id: String?) -> some View {
        let on = project == id
        return Button { project = id } label: {
            Text(title).font(PhoneFont.callout).lineLimit(1)
                .foregroundStyle(on ? PhoneTheme.onAccent : PhoneTheme.text)
                .padding(.horizontal, PhoneTheme.space3).frame(minHeight: 36)
                .background(on ? PhoneTheme.accent : PhoneTheme.surface, in: Capsule())
                .overlay { Capsule().strokeBorder(PhoneTheme.line) }
        }.buttonStyle(.plain).accessibilityAddTraits(on ? .isSelected : [])
            .accessibilityIdentifier("pill-\(id ?? "all")")
    }
}
