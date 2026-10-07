import 'dart:async';

import '../contracts/ohey_api_paths.dart';
import '../contracts/ohey_api_values.dart';
import '../data/backend_api_client.dart';

/// In-memory stand-in for the Ohey backend used by the UI preview mode.
///
/// It answers the same paths and row shapes the repositories parse, and keeps
/// writes in memory so taps (status changes, reactions, new yurubos) are
/// reflected for the rest of the session. Nothing leaves the device.
class OheyPreviewBackendApiClient extends BackendApiClient {
  OheyPreviewBackendApiClient()
    : super(
        baseUrl: 'https://preview.ohey.invalid',
        accessTokenProvider: () => 'ohey-ui-preview',
        userIdProvider: () => OheyPreviewFixtures.meId,
        tokenValidator: (_) => true,
      );

  final _store = OheyPreviewFixtures();

  static const _latency = Duration(milliseconds: 220);

  @override
  Future<dynamic> get(String path, {Map<String, String>? query}) =>
      _respond(() => _store.read(path, query ?? const {}));

  @override
  Future<dynamic> post(
    String path,
    Map<String, dynamic> body, {
    Map<String, String>? query,
  }) => _respond(() => _store.write('POST', path, body));

  @override
  Future<dynamic> postNoBody(String path, {Map<String, String>? query}) =>
      _respond(() => _store.write('POST', path, const {}));

  @override
  Future<dynamic> patch(String path, Map<String, dynamic> body) =>
      _respond(() => _store.write('PATCH', path, body));

  @override
  Future<dynamic> put(String path, Map<String, dynamic> body) =>
      _respond(() => _store.write('PUT', path, body));

  @override
  Future<dynamic> delete(
    String path, {
    Map<String, String>? query,
    Map<String, dynamic>? body,
  }) => _respond(() => _store.write('DELETE', path, body ?? const {}));

  Future<dynamic> _respond(dynamic Function() handler) async {
    await Future<void>.delayed(_latency);
    return handler();
  }
}

/// Fixture data plus the tiny amount of write handling the preview needs.
class OheyPreviewFixtures {
  static const meId = 'preview-me';

  final _profile = <String, dynamic>{
    'id': meId,
    'user_id': 'ohey_preview',
    'display_name': 'みーむ',
    'avatar_url': 'ohey_avatar:v2:2:1:0:0:0:0:0',
    'is_plus': false,
  };

  final _dailyStatuses = <String, String>{};

  late final List<Map<String, dynamic>> _friends = [
    _person(
      'f-haru',
      'haru_0412',
      'はる',
      'ohey_avatar:v2:1:3:2:1:1:0:1',
      OheyStatusKeys.available,
      palette: 'mint',
      favorite: true,
    ),
    _person(
      'f-sora',
      'sora_sky',
      'そら',
      'ohey_avatar:v2:3:2:4:0:2:1:2',
      OheyStatusKeys.maybeAvailable,
      palette: 'sky',
    ),
    _person(
      'f-mio',
      'mio_cafe',
      'みお',
      'ohey_avatar:v2:0:5:1:2:0:2:3',
      OheyStatusKeys.dependsOnTime,
      palette: 'peach',
    ),
    _person(
      'f-ren',
      'ren_run',
      'れん',
      'ohey_avatar:v2:4:0:3:1:1:0:4',
      OheyStatusKeys.hasPlans,
      palette: 'lavender',
    ),
    _person(
      'f-yui',
      'yui_yui',
      'ゆい',
      'ohey_avatar:v2:2:4:5:0:2:3:5',
      OheyStatusKeys.unselected,
      palette: 'blush',
    ),
  ];

  late final List<Map<String, dynamic>> _yurubos = [
    _yurubo(
      id: 'y-1',
      owner: _friends[0],
      title: '駅前の新しいカフェ行きたい',
      body: '今週どこかで30分だけでも！',
      placeText: '渋谷',
      timeLabel: '今週の夕方',
      reactions: 2,
      hoursAgo: 1,
    ),
    _yurubo(
      id: 'y-2',
      owner: _friends[1],
      title: '土曜に公園でピクニック',
      body: 'おにぎり持っていきます。ゆるく集合。',
      placeText: '代々木公園',
      timeLabel: '土曜 12:00〜',
      reactions: 4,
      hoursAgo: 5,
      reactedByMe: true,
    ),
    _yurubo(
      id: 'y-3',
      owner: _friends[2],
      title: 'カラオケで歌いたい気分',
      body: '',
      placeText: '新宿',
      timeLabel: '金曜の夜',
      reactions: 1,
      hoursAgo: 20,
    ),
  ];

  late final List<Map<String, dynamic>> _wishItems = [
    _wish('w-1', 'あの水族館に行く', '夏のうちに', '品川'),
    _wish('w-2', '焼き肉食べ放題', '', '上野'),
    _wish('w-3', '朝活でパンケーキ', '早起きできたら', '表参道'),
  ];

  late final List<Map<String, dynamic>> _friendRequests = [
    {
      'id': 'fr-1',
      'from_user_id': 'u-kai',
      'to_user_id': meId,
      'status': OheyStatusKeys.pending,
      'created_at': _isoAgo(const Duration(hours: 3)),
      'inviter': {
        'id': 'u-kai',
        'user_id': 'kai_kai',
        'display_name': 'かい',
        'avatar_url': 'ohey_avatar:v2:1:2:3:0:1:0:6',
      },
    },
  ];

  late final List<Map<String, dynamic>> _notifications = [
    {
      'id': 'n-1',
      'kind': OheyNotificationKindKeys.friendRequestReceived,
      'title': 'フレンズ申請',
      'message': 'かいさんからフレンズ申請が届きました',
      'actor_user_id': 'u-kai',
      'friend_request_id': 'fr-1',
      'friend_request': {'status': OheyStatusKeys.pending},
      'created_at': _isoAgo(const Duration(hours: 3)),
    },
  ];

  dynamic read(String path, Map<String, String> query) {
    switch (path) {
      case OheyApiPaths.meProfile:
        return _profile;
      case OheyApiPaths.dailyStatus:
        final date = query['date'] ?? _isoDate(DateTime.now());
        final status = _dailyStatuses[date];
        return [
          if (status != null) {'status_date': date, 'status': status},
        ];
      case OheyApiPaths.monthlyDailyStatuses:
        return [
          for (final entry in _dailyStatuses.entries)
            if (entry.key.startsWith(query['month'] ?? ''))
              {'status_date': entry.key, 'status': entry.value},
        ];
      case OheyApiPaths.friends:
        return [
          for (final friend in _friends)
            {
              'user_a_id': meId,
              'user_b': friend,
              'is_favorite': friend['is_favorite'],
            },
        ];
      case OheyApiPaths.friendGroups:
      case OheyApiPaths.userBlocks:
      case OheyApiPaths.userMutes:
      case OheyApiPaths.incomingPendingInvites:
      case OheyApiPaths.outgoingActiveInvites:
      case OheyApiPaths.todayReservations:
        return const <Object>[];
      case OheyApiPaths.friendRequests:
        return _friendRequests
            .where((row) => row['status'] == OheyStatusKeys.pending)
            .toList();
      case OheyApiPaths.friendRequestStatus:
        return const {
          'already_friend': false,
          'request_state': OheyRelationshipStateKeys.none,
        };
      case OheyApiPaths.yurubos:
        return _yurubos;
      case OheyApiPaths.wishItems:
        return _wishItems;
      case OheyApiPaths.notifications:
        return _notifications;
      case OheyApiPaths.adminMe:
        throw const BackendApiException('Forbidden', statusCode: 403);
    }
    if (path.startsWith('${OheyApiPaths.friends}/') &&
        path.endsWith('/daily-statuses/month')) {
      return _friendMonth(path, query['month']);
    }
    if (path.startsWith(OheyApiPaths.wishItemsProfileBase)) {
      return _wishItems.take(2).toList();
    }
    if (path.startsWith(OheyApiPaths.profilesByUserIdBase)) {
      throw const BackendApiException('Not found', statusCode: 404);
    }
    return const <Object>[];
  }

  dynamic write(String method, String path, Map<String, dynamic> body) {
    if (path == OheyApiPaths.dailyStatus && method == 'PUT') {
      _dailyStatuses[body['status_date'] as String] = body['status'] as String;
      return body;
    }
    if (path == OheyApiPaths.meProfile) {
      _profile.addAll(body);
      return _profile;
    }
    if (path == OheyApiPaths.yurubos && method == 'POST') {
      final row = _yurubo(
        id: 'y-${_yurubos.length + 1}',
        owner: _profile,
        title: (body['title'] as String?) ?? '',
        body: (body['body'] as String?) ?? '',
        placeText: (body['place_text'] as String?) ?? '',
        timeLabel: (body['time_label'] as String?) ?? '',
        reactions: 0,
        hoursAgo: 0,
      );
      _yurubos.insert(0, row);
      return row;
    }
    if (path.endsWith('/reaction')) {
      final id = path.split('/')[3];
      final row = _yurubos.firstWhere(
        (yurubo) => yurubo['id'] == id,
        orElse: () => const {},
      );
      if (row.isNotEmpty) {
        final reacted = method == 'PUT';
        if (row['reacted_by_me'] != reacted) {
          row['reaction_count'] =
              (row['reaction_count'] as int) + (reacted ? 1 : -1);
        }
        row['reacted_by_me'] = reacted;
      }
      return row;
    }
    if (path.startsWith('${OheyApiPaths.friendRequests}/')) {
      final id = path.split('/').last;
      for (final row in _friendRequests) {
        if (row['id'] == id) row['status'] = body['status'];
      }
      return const <String, dynamic>{};
    }
    if (path == OheyApiPaths.notificationsReadAll) {
      for (final row in _notifications) {
        row['read_at'] ??= DateTime.now().toUtc().toIso8601String();
      }
    }
    return const <String, dynamic>{};
  }

  List<Map<String, dynamic>> _friendMonth(String path, String? month) {
    final friendId = Uri.decodeComponent(path.split('/')[3]);
    final friend = _friends.firstWhere(
      (row) => row['id'] == friendId,
      orElse: () => const {},
    );
    final status = friend['status_key'] as String?;
    if (month == null || status == null) return const [];
    final today = DateTime.now();
    return [
      for (var offset = 0; offset < 5; offset++)
        if (_isoDate(today.add(Duration(days: offset))).startsWith(month))
          {
            'status_date': _isoDate(today.add(Duration(days: offset))),
            'status': offset.isEven ? status : OheyStatusKeys.maybeAvailable,
          },
    ];
  }

  static Map<String, dynamic> _person(
    String id,
    String userId,
    String name,
    String avatar,
    String status, {
    required String palette,
    bool favorite = false,
  }) => {
    'id': id,
    'user_id': userId,
    'display_name': name,
    'avatar_url': avatar,
    'palette': palette,
    'status_key': status,
    'is_favorite': favorite,
  };

  static Map<String, dynamic> _yurubo({
    required String id,
    required Map<String, dynamic> owner,
    required String title,
    required String body,
    required String placeText,
    required String timeLabel,
    required int reactions,
    required int hoursAgo,
    bool reactedByMe = false,
  }) => {
    'id': id,
    'owner_user_id': owner['id'],
    'owner': owner,
    'title': title,
    'body': body,
    'category': OheyCategoryKeys.other,
    'place_text': placeText,
    'time_label': timeLabel,
    'status': OheyStatusKeys.open,
    'visibility': OheyVisibilityKeys.friends,
    'visibility_label': '全フレンズ',
    'reaction_count': reactions,
    'reacted_by_me': reactedByMe,
    'created_at': _isoAgo(Duration(hours: hoursAgo)),
    'participants': const <Object>[],
  };

  static Map<String, dynamic> _wish(
    String id,
    String title,
    String note,
    String place,
  ) => {
    'id': id,
    'owner_user_id': meId,
    'title': title,
    'note': note,
    'category': OheyCategoryKeys.other,
    'place_text': place,
    'place_url': '',
    'visibility': OheyVisibilityKeys.friends,
    'created_at': _isoAgo(const Duration(days: 2)),
  };

  static String _isoAgo(Duration ago) =>
      DateTime.now().subtract(ago).toUtc().toIso8601String();

  static String _isoDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
