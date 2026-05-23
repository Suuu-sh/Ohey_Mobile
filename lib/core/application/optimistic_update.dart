typedef OptimisticAction<T> = void Function(T value);

Future<T> runOptimistic<T>({
  required void Function() apply,
  required void Function() rollback,
  required Future<T> Function() commit,
  void Function(T value)? confirm,
}) async {
  apply();
  try {
    final value = await commit();
    confirm?.call(value);
    return value;
  } catch (_) {
    rollback();
    rethrow;
  }
}
