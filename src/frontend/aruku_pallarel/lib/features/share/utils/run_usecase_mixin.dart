mixin RunUsecaseMixin {
  Future<T?> execute<T>({
    required Future<T> Function() action,
    void Function()? onStart,
    void Function()? onComplete,
    void Function(Object error)? onError,
  }) async {
    onStart?.call();
    try {
      return await action();
    } catch (error) {
      onError?.call(error);
      return null;
    } finally {
      onComplete?.call();
    }
  }
}
