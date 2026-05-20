import SwiftUI
import WidgetKit

private let appGroupIdentifier = "group.app.nomo.nomo"

struct NomoAvailableFriend: Equatable, Identifiable {
  let name: String
  let statusLabel: String

  var id: String { "\(name)-\(statusLabel)" }
}

struct NomoWidgetSnapshot: Equatable {
  let statusKey: String
  let statusLabel: String
  let statusDescription: String
  let availableFriendsCount: Int
  let availableFriendNames: [String]
  let availableFriends: [NomoAvailableFriend]
  let updatedAt: Date?

  static let placeholder = NomoWidgetSnapshot(
    statusKey: "unselected",
    statusLabel: "今日の気分は？",
    statusDescription: "Nomoを開いて飲みステータスをセットしよう",
    availableFriendsCount: 0,
    availableFriendNames: [],
    availableFriends: [],
    updatedAt: nil
  )

  static func load() -> NomoWidgetSnapshot {
    let defaults = UserDefaults(suiteName: appGroupIdentifier) ?? .standard
    let statusKey = defaults.string(forKey: "statusKey") ?? "unselected"
    let statusLabel = defaults.string(forKey: "statusLabel") ?? "今日の気分は？"
    let statusDescription = defaults.string(forKey: "statusDescription") ?? "Nomoを開いて飲みステータスをセットしよう"
    let friendNames = Array((defaults.stringArray(forKey: "availableFriendNames") ?? []).prefix(3))
    let friendStatusLabels = Array((defaults.stringArray(forKey: "availableFriendStatusLabels") ?? []).prefix(3))
    let friendCount = defaults.object(forKey: "availableFriendsCount") as? Int ?? friendNames.count
    let updatedAtMillis = defaults.object(forKey: "updatedAtMillis") as? Double
    let updatedAt = updatedAtMillis.map { Date(timeIntervalSince1970: $0 / 1000) }
    let friends = friendNames.enumerated().map { index, name in
      NomoAvailableFriend(
        name: name,
        statusLabel: friendStatusLabels.indices.contains(index) ? friendStatusLabels[index] : "今日飲める"
      )
    }

    return NomoWidgetSnapshot(
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

struct NomoWidgetEntry: TimelineEntry {
  let date: Date
  let snapshot: NomoWidgetSnapshot
}

struct NomoTimelineProvider: TimelineProvider {
  func placeholder(in context: Context) -> NomoWidgetEntry {
    NomoWidgetEntry(date: Date(), snapshot: .placeholder)
  }

  func getSnapshot(in context: Context, completion: @escaping (NomoWidgetEntry) -> Void) {
    completion(NomoWidgetEntry(date: Date(), snapshot: context.isPreview ? .placeholder : .load()))
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<NomoWidgetEntry>) -> Void) {
    let entry = NomoWidgetEntry(date: Date(), snapshot: .load())
    let nextRefresh = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date().addingTimeInterval(15 * 60)
    completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
  }
}

struct NomoTodayStatusWidget: Widget {
  let kind = "NomoTodayStatusWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: NomoTimelineProvider()) { entry in
      NomoTodayStatusWidgetView(entry: entry)
    }
    .configurationDisplayName("今日のノリ")
    .description("Nomoのキャラクターと一緒に、今日の飲みステータスをホーム画面で確認できます。")
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}

struct NomoFriendsAvailabilityWidget: Widget {
  let kind = "NomoFriendsAvailabilityWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: NomoTimelineProvider()) { entry in
      NomoFriendsAvailabilityWidgetView(entry: entry)
    }
    .configurationDisplayName("誘える飲み友リスト")
    .description("今日飲みに誘えそうな飲み友を、Nomoのキャラクターと一緒にすぐチェックできます。")
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}

@main
struct NomoWidgetsBundle: WidgetBundle {
  var body: some Widget {
    NomoTodayStatusWidget()
    NomoFriendsAvailabilityWidget()
  }
}

struct NomoTodayStatusWidgetView: View {
  @Environment(\.widgetFamily) private var family
  let entry: NomoWidgetEntry

  var body: some View {
    switch family {
    case .systemMedium:
      MediumStatusContent(snapshot: entry.snapshot)
        .widgetURL(URL(string: "app.nomo.nomo://widget/status"))
    default:
      SmallStatusContent(snapshot: entry.snapshot)
        .widgetURL(URL(string: "app.nomo.nomo://widget/status"))
    }
  }
}

struct NomoFriendsAvailabilityWidgetView: View {
  @Environment(\.widgetFamily) private var family
  let entry: NomoWidgetEntry

  var body: some View {
    switch family {
    case .systemMedium:
      MediumFriendsContent(snapshot: entry.snapshot)
        .widgetURL(URL(string: "app.nomo.nomo://widget/friends"))
    default:
      SmallFriendsContent(snapshot: entry.snapshot)
        .widgetURL(URL(string: "app.nomo.nomo://widget/friends"))
    }
  }
}

private struct SmallStatusContent: View {
  let snapshot: NomoWidgetSnapshot

  var body: some View {
    let style = NomoStatusWidgetStyle(statusKey: snapshot.statusKey)

    VStack(alignment: .leading, spacing: 8) {
      HStack(alignment: .top) {
        WidgetEyebrow(icon: style.symbolName, title: "今日のノリ", accent: style.accent)
        Spacer(minLength: 0)
        StatusOrb(symbolName: style.symbolName, accent: style.accent)
      }

      Spacer(minLength: 0)

      Text(snapshot.statusLabel)
        .font(.system(size: 22, weight: .black, design: .rounded))
        .foregroundStyle(.white)
        .lineLimit(2)
        .minimumScaleFactor(0.68)
        .nomoTextGlow()

      Text("タップして飲みステータス更新")
        .font(.system(size: 10.5, weight: .heavy, design: .rounded))
        .foregroundStyle(Color.white.opacity(0.72))
        .lineLimit(1)
        .minimumScaleFactor(0.72)
    }
    .padding(15)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    .nomoWidgetBackground(artwork: .statusSmall(snapshot.statusKey))
  }
}

private struct MediumStatusContent: View {
  let snapshot: NomoWidgetSnapshot

  var body: some View {
    let style = NomoStatusWidgetStyle(statusKey: snapshot.statusKey)

    HStack(spacing: 0) {
      Spacer(minLength: 122)

      VStack(alignment: .leading, spacing: 8) {
        WidgetEyebrow(icon: style.symbolName, title: "今日のノリ", accent: style.accent)

        Text(snapshot.statusLabel)
          .font(.system(size: 26, weight: .black, design: .rounded))
          .foregroundStyle(.white)
          .lineLimit(1)
          .minimumScaleFactor(0.65)
          .nomoTextGlow()

        Text(snapshot.statusDescription)
          .font(.system(size: 12, weight: .bold, design: .rounded))
          .foregroundStyle(Color.white.opacity(0.75))
          .lineLimit(2)
          .minimumScaleFactor(0.75)

        HStack(spacing: 6) {
          Image(systemName: "arrow.up.forward.app.fill")
            .font(.system(size: 10, weight: .black))
          Text(updatedText)
            .lineLimit(1)
            .minimumScaleFactor(0.72)
        }
        .font(.system(size: 10.5, weight: .heavy, design: .rounded))
        .foregroundStyle(Color.white.opacity(0.58))
      }
      .padding(13)
      .frame(maxWidth: 215, alignment: .leading)
    }
    .padding(14)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
    .nomoWidgetBackground(artwork: .statusMedium(snapshot.statusKey))
  }

  private var updatedText: String {
    guard let updatedAt = snapshot.updatedAt else { return "アプリを開くと更新" }
    return "更新 \(Self.timeFormatter.string(from: updatedAt))"
  }

  private static let timeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "ja_JP")
    formatter.dateFormat = "H:mm"
    return formatter
  }()
}

private struct SmallFriendsContent: View {
  let snapshot: NomoWidgetSnapshot

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack(alignment: .top) {
        WidgetEyebrow(icon: "person.2.fill", title: "誘える", accent: .nomoLime)
        Spacer(minLength: 0)
        FriendCountBadge(count: snapshot.availableFriendsCount, compact: true)
      }

      Spacer(minLength: 0)

      Text("飲み友リスト")
        .font(.system(size: 13, weight: .black, design: .rounded))
        .foregroundStyle(Color.white.opacity(0.78))
        .lineLimit(1)

      Text(friendHeadline)
        .font(.system(size: 21, weight: .black, design: .rounded))
        .foregroundStyle(.white)
        .lineLimit(2)
        .minimumScaleFactor(0.68)
        .nomoTextGlow()

      Text(snapshot.availableFriendsCount <= 0 ? "みんなの状態を更新" : "タップでフレンズへ")
        .font(.system(size: 10.5, weight: .heavy, design: .rounded))
        .foregroundStyle(Color.white.opacity(0.70))
        .lineLimit(1)
    }
    .padding(15)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    .nomoWidgetBackground(artwork: .mascotSmall)
  }

  private var friendHeadline: String {
    if snapshot.availableFriendsCount <= 0 { return "今は様子見" }
    if let name = snapshot.availableFriends.first?.name { return "\(name)を誘えそう" }
    return "\(snapshot.availableFriendsCount)人を誘えそう"
  }
}

private struct MediumFriendsContent: View {
  let snapshot: NomoWidgetSnapshot

  var body: some View {
    HStack(spacing: 0) {
      Spacer(minLength: 118)

      VStack(alignment: .leading, spacing: 8) {
        HStack(spacing: 8) {
          WidgetEyebrow(icon: "person.2.wave.2.fill", title: "誘える飲み友", accent: .nomoLime)
          Spacer(minLength: 0)
          FriendCountBadge(count: snapshot.availableFriendsCount, compact: false)
        }

        Text(friendHeadline)
          .font(.system(size: 22, weight: .black, design: .rounded))
          .foregroundStyle(.white)
          .lineLimit(1)
          .minimumScaleFactor(0.66)
          .nomoTextGlow()

        friendRows

        Text(snapshot.availableFriendsCount <= 0 ? "飲み友のステータス待ち" : "タップして声をかけにいく")
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
    .nomoWidgetBackground(artwork: .mascotMedium)
  }

  private var friendHeadline: String {
    if snapshot.availableFriendsCount <= 0 { return "今日はまだ静か" }
    if snapshot.availableFriendsCount == 1 { return "1人に声かけよ" }
    return "\(snapshot.availableFriendsCount)人に声かけよ"
  }

  @ViewBuilder
  private var friendRows: some View {
    if snapshot.availableFriends.isEmpty {
      Text("Nomoを開いて、みんなの今日のノリを更新しよう。")
        .font(.system(size: 12, weight: .bold, design: .rounded))
        .foregroundStyle(Color.white.opacity(0.72))
        .lineLimit(2)
        .minimumScaleFactor(0.78)
    } else {
      VStack(spacing: 5) {
        ForEach(snapshot.availableFriends.prefix(3)) { friend in
          HStack(spacing: 7) {
            Circle()
              .fill(Color.nomoLime)
              .frame(width: 7, height: 7)
              .shadow(color: Color.nomoLime.opacity(0.6), radius: 5)

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
              .nomoTextGlow()
          }
        }
      }
    }
  }
}

private struct NomoStatusWidgetStyle {
  let symbolName: String
  let accent: Color

  init(statusKey: String) {
    switch statusKey {
    case "can_drink_today", "want_drink":
      symbolName = "checkmark.circle.fill"
      accent = .nomoLime
    case "light_drink":
      symbolName = "clock.fill"
      accent = .nomoCyan
    case "want_drink_hard":
      symbolName = "flame.fill"
      accent = .nomoAmber
    case "non_alcohol":
      symbolName = "drop.fill"
      accent = .nomoMint
    case "liver_rest", "busy":
      symbolName = "moon.zzz.fill"
      accent = .nomoPink
    case "waiting_invite":
      symbolName = "bell.fill"
      accent = .nomoPurple
    case "has_plans":
      symbolName = "calendar"
      accent = .nomoSoftBlue
    default:
      symbolName = "questionmark.bubble.fill"
      accent = .nomoPink
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
    .nomoTextGlow()
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
      .shadow(color: Color.nomoInk.opacity(0.70), radius: 5, y: 2)
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
    .nomoTextGlow()
  }
}

private enum NomoWidgetArtwork {
  case mascotSmall
  case mascotMedium
  case statusSmall(String)
  case statusMedium(String)

  var imageName: String {
    switch self {
    case .mascotSmall:
      return "NomoWidgetMascotSmall"
    case .mascotMedium:
      return "NomoWidgetMascotMedium"
    case .statusSmall(let statusKey):
      return "NomoWidgetStatus\(Self.statusSlug(for: statusKey))Small"
    case .statusMedium(let statusKey):
      return "NomoWidgetStatus\(Self.statusSlug(for: statusKey))Medium"
    }
  }

  private static func statusSlug(for statusKey: String) -> String {
    switch statusKey {
    case "can_drink_today", "want_drink":
      return "CanDrinkToday"
    case "light_drink":
      return "LightDrink"
    case "want_drink_hard":
      return "WantDrinkHard"
    case "non_alcohol":
      return "NonAlcohol"
    case "liver_rest", "busy":
      return "LiverRest"
    case "waiting_invite":
      return "WaitingInvite"
    case "has_plans":
      return "HasPlans"
    default:
      return "Unselected"
    }
  }
}

private struct NomoWidgetBackground: View {
  let artwork: NomoWidgetArtwork

  var body: some View {
    GeometryReader { proxy in
      ZStack {
        LinearGradient(
          colors: [
            Color.nomoInk,
            Color(red: 0.08, green: 0.07, blue: 0.18),
            Color.nomoPink.opacity(0.86),
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
    case .mascotSmall, .statusSmall(_):
      ZStack {
        LinearGradient(
          colors: [
            Color.clear,
            Color.nomoInk.opacity(0.10),
            Color.nomoInk.opacity(0.82),
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
    case .mascotMedium, .statusMedium(_):
      ZStack {
        LinearGradient(
          colors: [
            Color.clear,
            Color.nomoInk.opacity(0.10),
            Color.nomoInk.opacity(0.82),
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
  func nomoWidgetBackground(artwork: NomoWidgetArtwork) -> some View {
    if #available(iOSApplicationExtension 17.0, *) {
      self.containerBackground(for: .widget) {
        NomoWidgetBackground(artwork: artwork)
      }
    } else {
      self.background(NomoWidgetBackground(artwork: artwork))
    }
  }

  func nomoTextGlow() -> some View {
    self
      .shadow(color: Color.nomoInk.opacity(0.62), radius: 6, x: 0, y: 2)
      .shadow(color: Color.nomoPink.opacity(0.22), radius: 10, x: 0, y: 3)
  }
}

private extension Color {
  static let nomoPink = Color(red: 1.0, green: 0.04, blue: 0.52)
  static let nomoLime = Color(red: 0.78, green: 0.96, blue: 0.0)
  static let nomoInk = Color(red: 0.03, green: 0.07, blue: 0.12)
  static let nomoCyan = Color(red: 0.34, green: 0.84, blue: 1.0)
  static let nomoAmber = Color(red: 1.0, green: 0.72, blue: 0.16)
  static let nomoMint = Color(red: 0.35, green: 0.93, blue: 0.82)
  static let nomoPurple = Color(red: 0.78, green: 0.55, blue: 1.0)
  static let nomoSoftBlue = Color(red: 0.74, green: 0.82, blue: 1.0)
}
