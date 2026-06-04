import '../contracts/ohey_api_values.dart';

const oheyPrivateVisibilityKey = OheyVisibilityKeys.private;
const oheyFriendsVisibilityKey = OheyVisibilityKeys.friends;
const oheyGroupVisibilityKey = OheyVisibilityKeys.group;

enum OheyVisibility {
  private(oheyPrivateVisibilityKey),
  friends(oheyFriendsVisibilityKey),
  group(oheyGroupVisibilityKey);

  const OheyVisibility(this.key);

  final String key;

  static const wishItemSelectable = <OheyVisibility>[
    OheyVisibility.private,
    OheyVisibility.friends,
  ];

  static const yuruboSelectable = <OheyVisibility>[
    OheyVisibility.friends,
    OheyVisibility.group,
  ];
}

extension OheyVisibilityX on OheyVisibility {
  String get label => switch (this) {
    OheyVisibility.private => '自分だけ',
    OheyVisibility.friends => '全フレンズ',
    OheyVisibility.group => 'グループ',
  };

  bool get requiresGroup => this == OheyVisibility.group;
}

OheyVisibility oheyVisibilityFromKey(String? key) {
  return switch (key?.trim()) {
    oheyFriendsVisibilityKey => OheyVisibility.friends,
    oheyGroupVisibilityKey => OheyVisibility.group,
    _ => OheyVisibility.private,
  };
}

extension OheyVisibilityKeyX on String? {
  OheyVisibility get oheyVisibility => oheyVisibilityFromKey(this);

  bool get requiresVisibilityGroup => oheyVisibility.requiresGroup;
}
