import SwiftUI
import WidgetKit

private let appGroupIdentifier = "group.app.nomo.nomo"

struct NomoWidgetSnapshot: Equatable {
  let statusKey: String
  let statusLabel: String
  let statusDescription: String
  let availableFriendsCount: Int
  let availableFriendNames: [String]
  let updatedAt: Date?

  static let placeholder = NomoWidgetSnapshot(
    statusKey: "unselected",
    statusLabel: "今日の気分は？",
    statusDescription: "Nomoを開いて飲みステータスをセットしよう",
    availableFriendsCount: 0,
    availableFriendNames: [],
    updatedAt: nil
  )

  static func load() -> NomoWidgetSnapshot {
    let defaults = UserDefaults(suiteName: appGroupIdentifier) ?? .standard
    let statusKey = defaults.string(forKey: "statusKey") ?? "unselected"
    let statusLabel = defaults.string(forKey: "statusLabel") ?? "今日の気分は？"
    let statusDescription = defaults.string(forKey: "statusDescription") ?? "Nomoを開いて飲みステータスをセットしよう"
    let friendNames = Array((defaults.stringArray(forKey: "availableFriendNames") ?? []).prefix(3))
    let friendCount = defaults.object(forKey: "availableFriendsCount") as? Int ?? friendNames.count
    let updatedAtMillis = defaults.object(forKey: "updatedAtMillis") as? Double
    let updatedAt = updatedAtMillis.map { Date(timeIntervalSince1970: $0 / 1000) }

    return NomoWidgetSnapshot(
      statusKey: statusKey,
      statusLabel: statusLabel,
      statusDescription: statusDescription,
      availableFriendsCount: friendCount,
      availableFriendNames: friendNames,
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
    .configurationDisplayName("今日の飲みステータス")
    .description("Nomoのメインキャラクターと一緒に今日の飲み気分をホーム画面で確認できます。")
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}

struct NomoFriendsAvailabilityWidget: Widget {
  let kind = "NomoFriendsAvailabilityWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: NomoTimelineProvider()) { entry in
      NomoFriendsAvailabilityWidgetView(entry: entry)
    }
    .configurationDisplayName("今夜空いてるフレンズ")
    .description("飲みに行けそうなフレンズをかわいくチェックできます。")
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
        .nomoWidgetBackground()
        .widgetURL(URL(string: "app.nomo.nomo://widget/status"))
    default:
      SmallStatusContent(snapshot: entry.snapshot)
        .nomoWidgetBackground()
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
        .nomoWidgetBackground()
        .widgetURL(URL(string: "app.nomo.nomo://widget/friends"))
    default:
      SmallFriendsContent(snapshot: entry.snapshot)
        .nomoWidgetBackground()
        .widgetURL(URL(string: "app.nomo.nomo://widget/friends"))
    }
  }
}

private struct SmallStatusContent: View {
  let snapshot: NomoWidgetSnapshot

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack(alignment: .top) {
        NomoMascotView(size: 48)
        Spacer(minLength: 0)
        Image(systemName: statusSymbolName)
          .font(.system(size: 18, weight: .black))
          .foregroundStyle(Color.nomoLime)
          .padding(8)
          .background(Circle().fill(Color.white.opacity(0.18)))
      }

      Spacer(minLength: 0)

      Text("今日の飲み")
        .font(.system(size: 13, weight: .black, design: .rounded))
        .foregroundStyle(Color.white.opacity(0.78))

      Text(snapshot.statusLabel)
        .font(.system(size: 20, weight: .black, design: .rounded))
        .foregroundStyle(.white)
        .lineLimit(2)
        .minimumScaleFactor(0.72)

      Text("タップして変更")
        .font(.system(size: 11, weight: .heavy, design: .rounded))
        .foregroundStyle(Color.white.opacity(0.62))
    }
    .padding(16)
  }

  private var statusSymbolName: String {
    switch snapshot.statusKey {
    case "can_drink_today", "want_drink", "light_drink", "want_drink_hard", "non_alcohol", "waiting_invite":
      return "sparkles"
    case "liver_rest", "busy", "has_plans":
      return "moon.zzz.fill"
    default:
      return "plus.bubble.fill"
    }
  }
}

private struct MediumStatusContent: View {
  let snapshot: NomoWidgetSnapshot

  var body: some View {
    HStack(spacing: 16) {
      NomoMascotView(size: 82)
        .overlay(alignment: .bottomTrailing) {
          Text("Nomo")
            .font(.system(size: 11, weight: .black, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Capsule().fill(Color.black.opacity(0.24)))
            .offset(x: 4, y: 3)
        }

      VStack(alignment: .leading, spacing: 9) {
        HStack(spacing: 7) {
          Image(systemName: "heart.text.square.fill")
            .font(.system(size: 15, weight: .black))
            .foregroundStyle(Color.nomoLime)
          Text("今日の飲みステータス")
            .font(.system(size: 13, weight: .black, design: .rounded))
            .foregroundStyle(Color.white.opacity(0.76))
        }

        Text(snapshot.statusLabel)
          .font(.system(size: 27, weight: .black, design: .rounded))
          .foregroundStyle(.white)
          .lineLimit(1)
          .minimumScaleFactor(0.7)

        Text(snapshot.statusDescription)
          .font(.system(size: 12, weight: .bold, design: .rounded))
          .foregroundStyle(Color.white.opacity(0.68))
          .lineLimit(2)
          .minimumScaleFactor(0.8)

        Text(updatedText)
          .font(.system(size: 11, weight: .heavy, design: .rounded))
          .foregroundStyle(Color.white.opacity(0.52))
      }

      Spacer(minLength: 0)
    }
    .padding(18)
  }

  private var updatedText: String {
    guard let updatedAt = snapshot.updatedAt else { return "アプリを開くと更新されます" }
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
        NomoMascotView(size: 46)
        Spacer(minLength: 0)
        Text("\(snapshot.availableFriendsCount)")
          .font(.system(size: 26, weight: .black, design: .rounded))
          .foregroundStyle(Color.nomoLime)
          .monospacedDigit()
      }

      Spacer(minLength: 0)

      Text("今夜いける？")
        .font(.system(size: 13, weight: .black, design: .rounded))
        .foregroundStyle(Color.white.opacity(0.78))

      Text(friendHeadline)
        .font(.system(size: 19, weight: .black, design: .rounded))
        .foregroundStyle(.white)
        .lineLimit(2)
        .minimumScaleFactor(0.72)

      Text("フレンズを見る")
        .font(.system(size: 11, weight: .heavy, design: .rounded))
        .foregroundStyle(Color.white.opacity(0.62))
    }
    .padding(16)
  }

  private var friendHeadline: String {
    if snapshot.availableFriendsCount <= 0 { return "まだ静か" }
    if let name = snapshot.availableFriendNames.first { return "\(name)が空いてる" }
    return "\(snapshot.availableFriendsCount)人が空いてる"
  }
}

private struct MediumFriendsContent: View {
  let snapshot: NomoWidgetSnapshot

  var body: some View {
    HStack(spacing: 16) {
      ZStack(alignment: .topTrailing) {
        NomoMascotView(size: 82)
        Text("\(snapshot.availableFriendsCount)")
          .font(.system(size: 18, weight: .black, design: .rounded))
          .foregroundStyle(Color.nomoPink)
          .monospacedDigit()
          .padding(9)
          .background(Circle().fill(.white))
          .shadow(color: .black.opacity(0.12), radius: 10, y: 4)
          .offset(x: 8, y: -5)
      }

      VStack(alignment: .leading, spacing: 9) {
        HStack(spacing: 7) {
          Image(systemName: "person.2.wave.2.fill")
            .font(.system(size: 15, weight: .black))
            .foregroundStyle(Color.nomoLime)
          Text("今夜空いてるフレンズ")
            .font(.system(size: 13, weight: .black, design: .rounded))
            .foregroundStyle(Color.white.opacity(0.76))
        }

        Text(snapshot.availableFriendsCount <= 0 ? "誘える人をチェック" : "\(snapshot.availableFriendsCount)人がいけそう")
          .font(.system(size: 25, weight: .black, design: .rounded))
          .foregroundStyle(.white)
          .lineLimit(1)
          .minimumScaleFactor(0.68)

        friendNamesView

        Text("タップでフレンズへ")
          .font(.system(size: 11, weight: .heavy, design: .rounded))
          .foregroundStyle(Color.white.opacity(0.52))
      }

      Spacer(minLength: 0)
    }
    .padding(18)
  }

  @ViewBuilder
  private var friendNamesView: some View {
    if snapshot.availableFriendNames.isEmpty {
      Text("Nomoを開いてみんなのステータスを更新しよう")
        .font(.system(size: 12, weight: .bold, design: .rounded))
        .foregroundStyle(Color.white.opacity(0.68))
        .lineLimit(2)
    } else {
      HStack(spacing: 6) {
        ForEach(snapshot.availableFriendNames.prefix(3), id: \.self) { name in
          Text(name)
            .font(.system(size: 11, weight: .black, design: .rounded))
            .foregroundStyle(Color.nomoInk)
            .lineLimit(1)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(Capsule().fill(Color.white.opacity(0.92)))
        }
      }
    }
  }
}

private struct NomoMascotView: View {
  let size: CGFloat

  var body: some View {
    ZStack {
      Circle()
        .fill(
          LinearGradient(
            colors: [Color.nomoPink, Color(red: 1.0, green: 0.15, blue: 0.55)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )
        )
        .overlay(
          Circle()
            .strokeBorder(Color.white.opacity(0.26), lineWidth: max(1, size * 0.035))
        )
        .shadow(color: Color.nomoPink.opacity(0.34), radius: size * 0.18, y: size * 0.08)

      HStack(spacing: size * 0.09) {
        mascotEye
        mascotEye
      }
      .offset(y: size * 0.06)

      Capsule()
        .fill(Color.nomoLime)
        .frame(width: size * 0.28, height: size * 0.17)
        .rotationEffect(.degrees(-26))
        .offset(x: size * 0.16, y: -size * 0.26)

      Capsule()
        .fill(Color.nomoLime)
        .frame(width: size * 0.07, height: size * 0.16)
        .rotationEffect(.degrees(28))
        .offset(x: size * 0.03, y: -size * 0.13)
    }
    .frame(width: size, height: size)
  }

  private var mascotEye: some View {
    Ellipse()
      .fill(
        LinearGradient(
          colors: [Color.black, Color(red: 0.03, green: 0.03, blue: 0.05)],
          startPoint: .top,
          endPoint: .bottom
        )
      )
      .frame(width: size * 0.19, height: size * 0.29)
      .overlay(alignment: .topLeading) {
        Circle()
          .fill(.white.opacity(0.95))
          .frame(width: size * 0.065, height: size * 0.065)
          .offset(x: size * 0.035, y: size * 0.035)
      }
  }
}

private struct NomoWidgetBackground: View {
  var body: some View {
    ZStack {
      LinearGradient(
        colors: [Color.nomoInk, Color(red: 0.08, green: 0.07, blue: 0.18), Color.nomoPink.opacity(0.86)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )

      Circle()
        .fill(Color.nomoPink.opacity(0.36))
        .frame(width: 170, height: 170)
        .blur(radius: 26)
        .offset(x: 90, y: -70)

      Circle()
        .fill(Color.nomoLime.opacity(0.18))
        .frame(width: 130, height: 130)
        .blur(radius: 24)
        .offset(x: -95, y: 80)
    }
  }
}

private extension View {
  @ViewBuilder
  func nomoWidgetBackground() -> some View {
    if #available(iOSApplicationExtension 17.0, *) {
      self.containerBackground(for: .widget) {
        NomoWidgetBackground()
      }
    } else {
      self.background(NomoWidgetBackground())
    }
  }
}

private extension Color {
  static let nomoPink = Color(red: 1.0, green: 0.04, blue: 0.52)
  static let nomoLime = Color(red: 0.78, green: 0.96, blue: 0.0)
  static let nomoInk = Color(red: 0.03, green: 0.07, blue: 0.12)
}
