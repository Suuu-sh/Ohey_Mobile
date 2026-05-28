import SwiftUI
import WidgetKit

private let appGroupIdentifier = "group.app.tomo.tomo"

struct TomoAvailableFriend: Equatable, Identifiable {
  let name: String
  let statusLabel: String

  var id: String { "\(name)-\(statusLabel)" }
}

struct TomoWidgetSnapshot: Equatable {
  let statusKey: String
  let statusLabel: String
  let statusDescription: String
  let availableFriendsCount: Int
  let availableFriendNames: [String]
  let availableFriends: [TomoAvailableFriend]
  let updatedAt: Date?

  static let placeholder = TomoWidgetSnapshot(
    statusKey: "unselected",
    statusLabel: "今日の気分は？",
    statusDescription: "Tomoを開いて今日の予定感をセットしよう",
    availableFriendsCount: 0,
    availableFriendNames: [],
    availableFriends: [],
    updatedAt: nil
  )

  static func load() -> TomoWidgetSnapshot {
    let defaults = UserDefaults(suiteName: appGroupIdentifier) ?? .standard
    let statusKey = defaults.string(forKey: "statusKey") ?? "unselected"
    let statusLabel = defaults.string(forKey: "statusLabel") ?? "今日の気分は？"
    let statusDescription = defaults.string(forKey: "statusDescription") ?? "Tomoを開いて今日の予定感をセットしよう"
    let friendNames = Array((defaults.stringArray(forKey: "availableFriendNames") ?? []).prefix(3))
    let friendStatusLabels = Array((defaults.stringArray(forKey: "availableFriendStatusLabels") ?? []).prefix(3))
    let friendCount = defaults.object(forKey: "availableFriendsCount") as? Int ?? friendNames.count
    let updatedAtMillis = defaults.object(forKey: "updatedAtMillis") as? Double
    let updatedAt = updatedAtMillis.map { Date(timeIntervalSince1970: $0 / 1000) }
    let friends = friendNames.enumerated().map { index, name in
      TomoAvailableFriend(
        name: name,
        statusLabel: friendStatusLabels.indices.contains(index) ? friendStatusLabels[index] : "今日空いてる"
      )
    }

    return TomoWidgetSnapshot(
      statusKey: statusKey,
      statusLabel: statusLabel,
      statusDescription: statusDescription,
      availableFriendsCount: friendCount,
      availableFriendNames: friendNames,
      availableFriends: friends,
      updatedAt: updatedAt
    )
  }
}

struct TomoWidgetEntry: TimelineEntry {
  let date: Date
  let snapshot: TomoWidgetSnapshot
}

struct TomoTimelineProvider: TimelineProvider {
  func placeholder(in context: Context) -> TomoWidgetEntry {
    TomoWidgetEntry(date: Date(), snapshot: .placeholder)
  }

  func getSnapshot(in context: Context, completion: @escaping (TomoWidgetEntry) -> Void) {
    completion(TomoWidgetEntry(date: Date(), snapshot: context.isPreview ? .placeholder : .load()))
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<TomoWidgetEntry>) -> Void) {
    let entry = TomoWidgetEntry(date: Date(), snapshot: .load())
    let nextRefresh = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date().addingTimeInterval(15 * 60)
    completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
  }
}

struct TomoTodayStatusWidget: Widget {
  let kind = "TomoTodayStatusWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: TomoTimelineProvider()) { entry in
      TomoTodayStatusWidgetView(entry: entry)
    }
    .configurationDisplayName("今日のノリ")
    .description("Tomoと一緒に、今日のノリをホーム画面で確認できます。")
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}

struct TomoFriendsAvailabilityWidget: Widget {
  let kind = "TomoFriendsAvailabilityWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: TomoTimelineProvider()) { entry in
      TomoFriendsAvailabilityWidgetView(entry: entry)
    }
    .configurationDisplayName("空いてるフレンズリスト")
    .description("今日誘えそうな友達を、Tomoと一緒にすぐチェックできます。")
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}

@main
struct TomoWidgetsBundle: WidgetBundle {
  var body: some Widget {
    TomoTodayStatusWidget()
    TomoFriendsAvailabilityWidget()
  }
}

struct TomoTodayStatusWidgetView: View {
  @Environment(\.widgetFamily) private var family
  let entry: TomoWidgetEntry

  var body: some View {
    switch family {
    case .systemMedium:
      MediumStatusContent(snapshot: entry.snapshot)
        .widgetURL(URL(string: "app.tomo.tomo://widget/status"))
    default:
      SmallStatusContent(snapshot: entry.snapshot)
        .widgetURL(URL(string: "app.tomo.tomo://widget/status"))
    }
  }
}

struct TomoFriendsAvailabilityWidgetView: View {
  @Environment(\.widgetFamily) private var family
  let entry: TomoWidgetEntry

  var body: some View {
    switch family {
    case .systemMedium:
      MediumFriendsContent(snapshot: entry.snapshot)
        .widgetURL(URL(string: "app.tomo.tomo://widget/friends"))
    default:
      SmallFriendsContent(snapshot: entry.snapshot)
        .widgetURL(URL(string: "app.tomo.tomo://widget/friends"))
    }
  }
}

private struct SmallStatusContent: View {
  let snapshot: TomoWidgetSnapshot

  var body: some View {
    Color.clear
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .tomoWidgetBackground(artwork: .statusSmall(snapshot.statusKey))
  }
}

private struct MediumStatusContent: View {
  let snapshot: TomoWidgetSnapshot

  var body: some View {
    ZStack(alignment: .trailing) {
      if !hasEmbeddedStatusTitle {
        Text(snapshot.statusLabel)
          .font(.system(size: 32, weight: .black, design: .rounded))
          .foregroundStyle(.white)
          .lineLimit(2)
          .minimumScaleFactor(0.72)
          .multilineTextAlignment(.leading)
          .tomoTextGlow()
          .frame(maxWidth: 210, alignment: .leading)
          .padding(.trailing, 22)
      }
    }
    .padding(.leading, 146)
    .padding(.vertical, 12)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
    .tomoWidgetBackground(artwork: .statusMedium(snapshot.statusKey))
  }

  private var hasEmbeddedStatusTitle: Bool {
    switch snapshot.statusKey {
    case "available", "maybe_available", "depends_on_time", "has_plans", "unselected":
      return true
    default:
      return false
    }
  }
}

private struct SmallFriendsContent: View {
  let snapshot: TomoWidgetSnapshot

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack(alignment: .top) {
        WidgetEyebrow(icon: "person.2.fill", title: "誘える", accent: .tomoLime)
        Spacer(minLength: 0)
        FriendCountBadge(count: snapshot.availableFriendsCount, compact: true)
      }

      Spacer(minLength: 0)

      Text("フレンズリスト")
        .font(.system(size: 13, weight: .black, design: .rounded))
        .foregroundStyle(Color.white.opacity(0.78))
        .lineLimit(1)

      Text(friendHeadline)
        .font(.system(size: 21, weight: .black, design: .rounded))
        .foregroundStyle(.white)
        .lineLimit(2)
        .minimumScaleFactor(0.68)
        .tomoTextGlow()

      Text(snapshot.availableFriendsCount <= 0 ? "みんなの状態を更新" : "タップでフレンズへ")
        .font(.system(size: 10.5, weight: .heavy, design: .rounded))
        .foregroundStyle(Color.white.opacity(0.70))
        .lineLimit(1)
    }
    .padding(15)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    .tomoWidgetBackground(artwork: .mascotSmall)
  }

  private var friendHeadline: String {
    if snapshot.availableFriendsCount <= 0 { return "今は様子見" }
    if let name = snapshot.availableFriends.first?.name { return "\(name)を誘えそう" }
    return "\(snapshot.availableFriendsCount)人を誘えそう"
  }
}

private struct MediumFriendsContent: View {
  let snapshot: TomoWidgetSnapshot

  var body: some View {
    HStack(spacing: 0) {
      Spacer(minLength: 118)

      VStack(alignment: .leading, spacing: 8) {
        HStack(spacing: 8) {
          WidgetEyebrow(icon: "person.2.wave.2.fill", title: "空いてるフレンズ", accent: .tomoLime)
          Spacer(minLength: 0)
          FriendCountBadge(count: snapshot.availableFriendsCount, compact: false)
        }

        Text(friendHeadline)
          .font(.system(size: 22, weight: .black, design: .rounded))
          .foregroundStyle(.white)
          .lineLimit(1)
          .minimumScaleFactor(0.66)
          .tomoTextGlow()

        friendRows

        Text(snapshot.availableFriendsCount <= 0 ? "フレンズの予定待ち" : "タップして予定を作る")
          .font(.system(size: 10.5, weight: .heavy, design: .rounded))
          .foregroundStyle(Color.white.opacity(0.58))
          .lineLimit(1)
          .minimumScaleFactor(0.75)
      }
      .padding(12)
      .frame(maxWidth: 225, alignment: .leading)
    }
    .padding(14)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
    .tomoWidgetBackground(artwork: .mascotMedium)
  }

  private var friendHeadline: String {
    if snapshot.availableFriendsCount <= 0 { return "今日はまだ静か" }
    if snapshot.availableFriendsCount == 1 { return "1人に声かけよ" }
    return "\(snapshot.availableFriendsCount)人に声かけよ"
  }

  @ViewBuilder
  private var friendRows: some View {
    if snapshot.availableFriends.isEmpty {
      Text("Tomoを開いて、みんなの今日の予定感を更新しよう。")
        .font(.system(size: 12, weight: .bold, design: .rounded))
        .foregroundStyle(Color.white.opacity(0.72))
        .lineLimit(2)
        .minimumScaleFactor(0.78)
    } else {
      VStack(spacing: 5) {
        ForEach(snapshot.availableFriends.prefix(3)) { friend in
          HStack(spacing: 7) {
            Circle()
              .fill(Color.tomoLime)
              .frame(width: 7, height: 7)
              .shadow(color: Color.tomoLime.opacity(0.6), radius: 5)

            Text(friend.name)
              .font(.system(size: 12, weight: .black, design: .rounded))
              .foregroundStyle(.white)
              .lineLimit(1)
              .minimumScaleFactor(0.72)

            Spacer(minLength: 4)

            Text(friend.statusLabel)
              .font(.system(size: 9.5, weight: .black, design: .rounded))
              .foregroundStyle(Color.white.opacity(0.78))
              .lineLimit(1)
              .minimumScaleFactor(0.68)
              .tomoTextGlow()
          }
        }
      }
    }
  }
}

private struct TomoStatusWidgetStyle {
  let symbolName: String
  let accent: Color

  init(statusKey: String) {
    switch statusKey {
    case "available":
      symbolName = "checkmark.circle.fill"
      accent = .tomoLime
    case "maybe_available":
      symbolName = "drop.fill"
      accent = .tomoCyan
    case "depends_on_time":
      symbolName = "clock.fill"
      accent = .tomoPurple
    case "has_plans":
      symbolName = "calendar"
      accent = .tomoSoftBlue
    default:
      symbolName = "questionmark.bubble.fill"
      accent = .tomoPink
    }
  }
}

private struct WidgetEyebrow: View {
  let icon: String
  let title: String
  let accent: Color

  var body: some View {
    HStack(spacing: 5) {
      Image(systemName: icon)
        .font(.system(size: 11, weight: .black))
        .foregroundStyle(accent)
      Text(title)
        .font(.system(size: 11.5, weight: .black, design: .rounded))
        .foregroundStyle(Color.white.opacity(0.82))
        .lineLimit(1)
    }
    .tomoTextGlow()
  }
}

private struct StatusOrb: View {
  let symbolName: String
  let accent: Color

  var body: some View {
    Image(systemName: symbolName)
      .font(.system(size: 15, weight: .black))
      .foregroundStyle(accent)
      .frame(width: 33, height: 33)
      .shadow(color: Color.tomoInk.opacity(0.70), radius: 5, y: 2)
      .shadow(color: accent.opacity(0.35), radius: 10, y: 3)
  }
}

private struct FriendCountBadge: View {
  let count: Int
  let compact: Bool

  var body: some View {
    HStack(alignment: .firstTextBaseline, spacing: 2) {
      Text("\(count)")
        .font(.system(size: compact ? 24 : 18, weight: .black, design: .rounded))
        .monospacedDigit()
      if !compact {
        Text("人")
          .font(.system(size: 10, weight: .black, design: .rounded))
      }
    }
    .foregroundStyle(Color.white)
    .tomoTextGlow()
  }
}

private enum TomoWidgetArtwork {
  case mascotSmall
  case mascotMedium
  case statusSmall(String)
  case statusMedium(String)

  var imageName: String {
    switch self {
    case .mascotSmall:
      return "TomoWidgetMascotSmall"
    case .mascotMedium:
      return "TomoWidgetMascotMedium"
    case .statusSmall(let statusKey):
      return "TomoWidgetStatus\(Self.statusSlug(for: statusKey))Small"
    case .statusMedium(let statusKey):
      return "TomoWidgetStatus\(Self.statusSlug(for: statusKey))Medium"
    }
  }

  private static func statusSlug(for statusKey: String) -> String {
    switch statusKey {
    case "available":
      return "Available"
    case "maybe_available":
      return "MaybeAvailable"
    case "depends_on_time":
      return "DependsOnTime"
    case "has_plans":
      return "HasPlans"
    default:
      return "Unselected"
    }
  }
}

private struct TomoWidgetBackground: View {
  let artwork: TomoWidgetArtwork

  var body: some View {
    GeometryReader { proxy in
      ZStack {
        LinearGradient(
          colors: [
            Color.tomoInk,
            Color(red: 0.08, green: 0.07, blue: 0.18),
            Color.tomoPink.opacity(0.86),
          ],
          startPoint: .topLeading,
          endPoint: .bottomTrailing
        )

        Image(artwork.imageName)
          .resizable()
          .scaledToFill()
          .frame(width: proxy.size.width, height: proxy.size.height)
          .clipped()
          .accessibilityHidden(true)

        overlay
      }
    }
  }

  @ViewBuilder
  private var overlay: some View {
    switch artwork {
    case .statusSmall(_), .statusMedium(_):
      EmptyView()
    case .mascotSmall:
      ZStack {
        LinearGradient(
          colors: [
            Color.clear,
            Color.tomoInk.opacity(0.10),
            Color.tomoInk.opacity(0.82),
          ],
          startPoint: .top,
          endPoint: .bottom
        )
        RadialGradient(
          colors: [Color.clear, Color.black.opacity(0.36)],
          center: .center,
          startRadius: 48,
          endRadius: 120
        )
      }
    case .mascotMedium:
      ZStack {
        LinearGradient(
          colors: [
            Color.clear,
            Color.tomoInk.opacity(0.10),
            Color.tomoInk.opacity(0.82),
          ],
          startPoint: .leading,
          endPoint: .trailing
        )
        LinearGradient(
          colors: [Color.clear, Color.black.opacity(0.28)],
          startPoint: .top,
          endPoint: .bottom
        )
      }
    }
  }
}

private extension View {
  @ViewBuilder
  func tomoWidgetBackground(artwork: TomoWidgetArtwork) -> some View {
    if #available(iOSApplicationExtension 17.0, *) {
      self.containerBackground(for: .widget) {
        TomoWidgetBackground(artwork: artwork)
      }
    } else {
      self.background(TomoWidgetBackground(artwork: artwork))
    }
  }

  func tomoTextGlow() -> some View {
    self
      .shadow(color: Color.tomoInk.opacity(0.62), radius: 6, x: 0, y: 2)
      .shadow(color: Color.tomoPink.opacity(0.22), radius: 10, x: 0, y: 3)
  }
}

private extension Color {
  static let tomoPink = Color(red: 1.0, green: 0.04, blue: 0.52)
  static let tomoLime = Color(red: 0.78, green: 0.96, blue: 0.0)
  static let tomoInk = Color(red: 0.03, green: 0.07, blue: 0.12)
  static let tomoCyan = Color(red: 0.34, green: 0.84, blue: 1.0)
  static let tomoAmber = Color(red: 1.0, green: 0.72, blue: 0.16)
  static let tomoMint = Color(red: 0.35, green: 0.93, blue: 0.82)
  static let tomoPurple = Color(red: 0.78, green: 0.55, blue: 1.0)
  static let tomoSoftBlue = Color(red: 0.74, green: 0.82, blue: 1.0)
}
