class ManualRefreshPageState {
  const ManualRefreshPageState({
    required this.currentUrl,
    required this.pageTitle,
    required this.isLoading,
    required this.isReady,
  });

  final String currentUrl;
  final String pageTitle;
  final bool isLoading;
  final bool isReady;

  bool get hasCurrentUrl {
    final value = currentUrl.trim();
    return value.isNotEmpty && value != 'none';
  }
}
