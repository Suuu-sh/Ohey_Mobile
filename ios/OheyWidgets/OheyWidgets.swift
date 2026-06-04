import SwiftUI
import WidgetKit

private let appGroupIdentifier = "group.app.ohey.com"

struct OheyAvailableFriend: Equatable, Identifiable {
  let name: String
  let statusLabel: String

  var id: String { "\(name)-\(statusLabel)" }
}

fileprivate enum OheyWidgetDailyStatus: String {
  case unselected = "unselected"
  case available = "available"
  case maybeAvailable = "maybe_available"
  case dependsOnTime = "depends_on_time"
  case hasPlans = "has_plans"

  init(key: String) {
    self = Self(rawValue: key) ?? .unselected
  }

  var hasEmbeddedWidgetTitle: Bool {
    switch self {
    case .available, .maybeAvailable, .dependsOnTime, .hasPlans, .unselected:
      return true
    }
  }

  var symbolName: String {
    switch self {
    case .available:
      return "checkmark.circle.fill"
    case .maybeAvailable:
      return "drop.fill"
    case .dependsOnTime:
      return "clock.fill"
    case .hasPlans:
      return "calendar"
    case .unselected:
      return "questionmark.bubble.fill"
    }
  }

  var accent: Color {
    switch self {
    case .available:
      return .oheyLime
    case .maybeAvailable:
      return .oheyCyan
    case .dependsOnTime:
      return .oheyPurple
    case .hasPlans:
      return .oheySoftBlue
    case .unselected:
      return .oheyPink
    }
  }

  var artworkSlug: String {
    switch self {
    case .available:
      return "Available"
    case .maybeAvailable:
      return "MaybeAvailable"
    case .dependsOnTime:
      return "DependsOnTime"
    case .hasPlans:
      return "HasPlans"
    case .unselected:
      return "Unselected"
    }
  }
}

struct OheyWidgetSnapshot: Equatable {
  let statusKey: String
  let statusLabel: String
  let statusDescription: String
  let availableFriendsCount: Int
  let availableFriendNames: [String]
  let availableFriends: [OheyAvailableFriend]
  let updatedAt: Date?

  fileprivate var dailyStatus: OheyWidgetDailyStatus {
    OheyWidgetDailyStatus(key: statusKey)
  }

  static let placeholder = OheyWidgetSnapshot(
    statusKey: "unselected",
    statusLabel: "今日の気分は？",
    statusDescription: "Oheyを開いて今日の予定感をセットしよう",
    availableFriendsCount: 0,
    availableFriendNames: [],
    availableFriends: [],
    updatedAt: nil
  )

  static func load() -> OheyWidgetSnapshot {
    let defaults = UserDefaults(suiteName: appGroupIdentifier) ?? .standard
    let statusKey = defaults.string(forKey: "statusKey") ?? "unselected"
    let statusLabel = defaults.string(forKey: "statusLabel") ?? "今日の気分は？"
    let statusDescription = defaults.string(forKey: "statusDescription") ?? "Oheyを開いて今日の予定感をセットしよう"
    let friendNames = Array((defaults.stringArray(forKey: "availableFriendNames") ?? []).prefix(3))
    let friendStatusLabels = Array((defaults.stringArray(forKey: "availableFriendStatusLabels") ?? []).prefix(3))
    let friendCount = defaults.object(forKey: "availableFriendsCount") as? Int ?? friendNames.count
    let updatedAtMillis = defaults.object(forKey: "updatedAtMillis") as? Double
    let updatedAt = updatedAtMillis.map { Date(timeIntervalSince1970: $0 / 1000) }
    let friends = friendNames.enumerated().map { index, name in
      OheyAvailableFriend(
        name: name,
        statusLabel: friendStatusLabels.indices.contains(index) ? friendStatusLabels[index] : "今日空いてる"
      )
    }

    return OheyWidgetSnapshot(
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

struct OheyWidgetEntry: TimelineEntry {
  let date: Date
  let snapshot: OheyWidgetSnapshot
}

struct OheyTimelineProvider: TimelineProvider {
  func placeholder(in context: Context) -> OheyWidgetEntry {
    OheyWidgetEntry(date: Date(), snapshot: .placeholder)
  }

  func getSnapshot(in context: Context, completion: @escaping (OheyWidgetEntry) -> Void) {
    completion(OheyWidgetEntry(date: Date(), snapshot: context.isPreview ? .placeholder : .load()))
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<OheyWidgetEntry>) -> Void) {
    let entry = OheyWidgetEntry(date: Date(), snapshot: .load())
    let nextRefresh = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date().addingTimeInterval(15 * 60)
    completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
  }
}

struct OheyTodayStatusWidget: Widget {
  let kind = "OheyTodayStatusWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: OheyTimelineProvider()) { entry in
      OheyTodayStatusWidgetView(entry: entry)
    }
    .configurationDisplayName("今日のノリ")
    .description("Oheyと一緒に、今日のノリをホーム画面で確認できます。")
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}

struct OheyFriendsAvailabilityWidget: Widget {
  let kind = "OheyFriendsAvailabilityWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: OheyTimelineProvider()) { entry in
      OheyFriendsAvailabilityWidgetView(entry: entry)
    }
    .configurationDisplayName("空いてるフレンズリスト")
    .description("今日誘えそうな友達を、Oheyと一緒にすぐチェックできます。")
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}

@main
struct OheyWidgetsBundle: WidgetBundle {
  var body: some Widget {
    OheyTodayStatusWidget()
    OheyFriendsAvailabilityWidget()
  }
}

struct OheyTodayStatusWidgetView: View {
  @Environment(\.widgetFamily) private var family
  let entry: OheyWidgetEntry

  var body: some View {
    switch family {
    case .systemMedium:
      MediumStatusContent(snapshot: entry.snapshot)
        .widgetURL(URL(string: "app.ohey.com://widget/status"))
    default:
      SmallStatusContent(snapshot: entry.snapshot)
        .widgetURL(URL(string: "app.ohey.com://widget/status"))
    }
  }
}

struct OheyFriendsAvailabilityWidgetView: View {
  @Environment(\.widgetFamily) private var family
  let entry: OheyWidgetEntry

  var body: some View {
    switch family {
    case .systemMedium:
      MediumFriendsContent(snapshot: entry.snapshot)
        .widgetURL(URL(string: "app.ohey.com://widget/friends"))
    default:
      SmallFriendsContent(snapshot: entry.snapshot)
        .widgetURL(URL(string: "app.ohey.com://widget/friends"))
    }
  }
}

private struct SmallStatusContent: View {
  let snapshot: OheyWidgetSnapshot

  var body: some View {
    Color.clear
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .oheyWidgetBackground(artwork: .statusSmall(snapshot.dailyStatus))
  }
}

private struct MediumStatusContent: View {
  let snapshot: OheyWidgetSnapshot

  var body: some View {
    ZStack(alignment: .trailing) {
      if !snapshot.dailyStatus.hasEmbeddedWidgetTitle {
        Text(snapshot.statusLabel)
          .font(.system(size: 32, weight: .black, design: .rounded))
          .foregroundStyle(.white)
          .lineLimit(2)
          .minimumScaleFactor(0.72)
          .multilineTextAlignment(.leading)
          .oheyTextGlow()
          .frame(maxWidth: 210, alignment: .leading)
          .padding(.trailing, 22)
      }
    }
    .padding(.leading, 146)
    .padding(.vertical, 12)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
    .oheyWidgetBackground(artwork: .statusMedium(snapshot.dailyStatus))
  }
}

private struct SmallFriendsContent: View {
  let snapshot: OheyWidgetSnapshot

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack(alignment: .top) {
        WidgetEyebrow(icon: "person.2.fill", title: "誘える", accent: .oheyLime)
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
        .oheyTextGlow()

      Text(snapshot.availableFriendsCount <= 0 ? "みんなの状態を更新" : "タップでフレンズへ")
        .font(.system(size: 10.5, weight: .heavy, design: .rounded))
        .foregroundStyle(Color.white.opacity(0.70))
        .lineLimit(1)
    }
    .padding(15)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    .oheyWidgetBackground(artwork: .mascotSmall)
  }

  private var friendHeadline: String {
    if snapshot.availableFriendsCount <= 0 { return "今は様子見" }
    if let name = snapshot.availableFriends.first?.name { return "\(name)を誘えそう" }
    return "\(snapshot.availableFriendsCount)人を誘えそう"
  }
}

private struct MediumFriendsContent: View {
  let snapshot: OheyWidgetSnapshot

  var body: some View {
    HStack(spacing: 0) {
      Spacer(minLength: 118)

      VStack(alignment: .leading, spacing: 8) {
        HStack(spacing: 8) {
          WidgetEyebrow(icon: "person.2.wave.2.fill", title: "空いてるフレンズ", accent: .oheyLime)
          Spacer(minLength: 0)
          FriendCountBadge(count: snapshot.availableFriendsCount, compact: false)
        }

        Text(friendHeadline)
          .font(.system(size: 22, weight: .black, design: .rounded))
          .foregroundStyle(.white)
          .lineLimit(1)
          .minimumScaleFactor(0.66)
          .oheyTextGlow()

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
    .oheyWidgetBackground(artwork: .mascotMedium)
  }

  private var friendHeadline: String {
    if snapshot.availableFriendsCount <= 0 { return "今日はまだ静か" }
    if snapshot.availableFriendsCount == 1 { return "1人に声かけよ" }
    return "\(snapshot.availableFriendsCount)人に声かけよ"
  }

  @ViewBuilder
  private var friendRows: some View {
    if snapshot.availableFriends.isEmpty {
      Text("Oheyを開いて、みんなの今日の予定感を更新しよう。")
        .font(.system(size: 12, weight: .bold, design: .rounded))
        .foregroundStyle(Color.white.opacity(0.72))
        .lineLimit(2)
        .minimumScaleFactor(0.78)
    } else {
      VStack(spacing: 5) {
        ForEach(snapshot.availableFriends.prefix(3)) { friend in
          HStack(spacing: 7) {
            Circle()
              .fill(Color.oheyLime)
              .frame(width: 7, height: 7)
              .shadow(color: Color.oheyLime.opacity(0.6), radius: 5)

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
              .oheyTextGlow()
          }
        }
      }
    }
  }
}

private struct OheyStatusWidgetStyle {
  let symbolName: String
  let accent: Color

  init(status: OheyWidgetDailyStatus) {
    symbolName = status.symbolName
    accent = status.accent
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
    .oheyTextGlow()
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
      .shadow(color: Color.oheyInk.opacity(0.70), radius: 5, y: 2)
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
    .oheyTextGlow()
  }
}

private enum OheyWidgetArtwork {
  case mascotSmall
  case mascotMedium
  case statusSmall(OheyWidgetDailyStatus)
  case statusMedium(OheyWidgetDailyStatus)

  var imageName: String {
    switch self {
    case .mascotSmall:
      return "OheyWidgetMascotSmall"
    case .mascotMedium:
      return "OheyWidgetMascotMedium"
    case .statusSmall(let status):
      return "OheyWidgetStatus\(status.artworkSlug)Small"
    case .statusMedium(let status):
      return "OheyWidgetStatus\(status.artworkSlug)Medium"
    }
  }
}

private struct OheyWidgetBackground: View {
  let artwork: OheyWidgetArtwork

  var body: some View {
    GeometryReader { proxy in
      ZStack {
        LinearGradient(
          colors: [
            Color.oheyInk,
            Color(red: 0.08, green: 0.07, blue: 0.18),
            Color.oheyPink.opacity(0.86),
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
            Color.oheyInk.opacity(0.10),
            Color.oheyInk.opacity(0.82),
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
            Color.oheyInk.opacity(0.10),
            Color.oheyInk.opacity(0.82),
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
  func oheyWidgetBackground(artwork: OheyWidgetArtwork) -> some View {
    if #available(iOSApplicationExtension 17.0, *) {
      self.containerBackground(for: .widget) {
        OheyWidgetBackground(artwork: artwork)
      }
    } else {
      self.background(OheyWidgetBackground(artwork: artwork))
    }
  }

  func oheyTextGlow() -> some View {
    self
      .shadow(color: Color.oheyInk.opacity(0.62), radius: 6, x: 0, y: 2)
      .shadow(color: Color.oheyPink.opacity(0.22), radius: 10, x: 0, y: 3)
  }
}

private extension Color {
  static let oheyPink = Color(red: 1.0, green: 0.04, blue: 0.52)
  static let oheyLime = Color(red: 0.78, green: 0.96, blue: 0.0)
  static let oheyInk = Color(red: 0.03, green: 0.07, blue: 0.12)
  static let oheyCyan = Color(red: 0.34, green: 0.84, blue: 1.0)
  static let oheyAmber = Color(red: 1.0, green: 0.72, blue: 0.16)
  static let oheyMint = Color(red: 0.35, green: 0.93, blue: 0.82)
  static let oheyPurple = Color(red: 0.78, green: 0.55, blue: 1.0)
  static let oheySoftBlue = Color(red: 0.74, green: 0.82, blue: 1.0)
}
