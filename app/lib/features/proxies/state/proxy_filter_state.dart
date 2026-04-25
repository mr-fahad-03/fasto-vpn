enum ProxyPremiumFilter { all, freeOnly, premiumOnly }

class ProxyFilterState {
  final String searchQuery;
  final ProxyPremiumFilter premiumFilter;
  final String? countryCode;

  const ProxyFilterState({
    required this.searchQuery,
    required this.premiumFilter,
    this.countryCode,
  });

  factory ProxyFilterState.initial() {
    return const ProxyFilterState(
      searchQuery: '',
      premiumFilter: ProxyPremiumFilter.all,
      countryCode: null,
    );
  }

  ProxyFilterState copyWith({
    String? searchQuery,
    ProxyPremiumFilter? premiumFilter,
    String? countryCode,
    bool clearCountryCode = false,
  }) {
    return ProxyFilterState(
      searchQuery: searchQuery ?? this.searchQuery,
      premiumFilter: premiumFilter ?? this.premiumFilter,
      countryCode: clearCountryCode ? null : (countryCode ?? this.countryCode),
    );
  }
}
