/// Shared helper for inserting inline native-ad entries into list UIs.
///
/// Keep this as the single source of truth for friend-style ad cadence so
/// screens that reuse friend cards do not drift apart.
const oheyFriendStyleFirstAdAfter = 2;
const oheyFriendStyleAdFrequency = 3;

List<TEntry> buildOheyAdEntries<TItem, TEntry>({
  required List<TItem> items,
  required TEntry Function(TItem item) itemEntryBuilder,
  required TEntry Function(int adIndex) adEntryBuilder,
  int firstAdAfter = oheyFriendStyleFirstAdAfter,
  int adFrequency = oheyFriendStyleAdFrequency,
}) {
  if (items.length < firstAdAfter) {
    return [for (final item in items) itemEntryBuilder(item)];
  }

  final entries = <TEntry>[];
  var adIndex = 0;
  for (var index = 0; index < items.length; index++) {
    entries.add(itemEntryBuilder(items[index]));
    final position = index + 1;
    final shouldInsertAd =
        position == firstAdAfter ||
        (position > firstAdAfter &&
            (position - firstAdAfter) % adFrequency == 0);
    if (shouldInsertAd) entries.add(adEntryBuilder(adIndex++));
  }
  return entries;
}
