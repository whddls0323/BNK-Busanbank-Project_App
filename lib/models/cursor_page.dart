class CursorPage<T> {
  final List<T> items;
  final String? nextCursor;

  CursorPage({
    required this.items,
    required this.nextCursor,
  });
}
