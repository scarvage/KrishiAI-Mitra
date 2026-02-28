// Model for a single mandi price entry from the real backend API
class ApiMandiPrice {
  final String mandi;
  final String district;
  final String state;
  final String commodity;
  final String variety;
  final double modalPrice;
  final double minPrice;
  final double maxPrice;
  final String? arrivalDate;

  const ApiMandiPrice({
    required this.mandi,
    required this.district,
    required this.state,
    required this.commodity,
    required this.variety,
    required this.modalPrice,
    required this.minPrice,
    required this.maxPrice,
    this.arrivalDate,
  });

  factory ApiMandiPrice.fromJson(Map<String, dynamic> json) {
    return ApiMandiPrice(
      mandi: json['mandi'] as String? ?? 'Unknown',
      district: json['district'] as String? ?? '',
      state: json['state'] as String? ?? '',
      commodity: json['commodity'] as String? ?? '',
      variety: json['variety'] as String? ?? '',
      modalPrice: (json['modal_price'] as num?)?.toDouble() ?? 0.0,
      minPrice: (json['min_price'] as num?)?.toDouble() ?? 0.0,
      maxPrice: (json['max_price'] as num?)?.toDouble() ?? 0.0,
      arrivalDate: json['arrival_date'] as String?,
    );
  }
}

// Response wrapper for the full API response
class MandiApiResponse {
  final String crop;
  final String? state;
  final List<ApiMandiPrice> prices;
  final String recommendation;
  final String language;
  final String? lastUpdated;
  final int totalMandis;

  const MandiApiResponse({
    required this.crop,
    this.state,
    required this.prices,
    required this.recommendation,
    required this.language,
    this.lastUpdated,
    required this.totalMandis,
  });

  factory MandiApiResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    final pricesList = (data['prices'] as List<dynamic>? ?? [])
        .map((e) => ApiMandiPrice.fromJson(e as Map<String, dynamic>))
        .toList();

    return MandiApiResponse(
      crop: data['crop'] as String? ?? '',
      state: data['state'] as String?,
      prices: pricesList,
      recommendation: data['recommendation'] as String? ?? '',
      language: data['language'] as String? ?? 'hi',
      lastUpdated: data['lastUpdated'] as String?,
      totalMandis: data['totalMandis'] as int? ?? 0,
    );
  }
}

// Legacy model kept for mock data compatibility
class MandiPrice {
  final String commodity;
  final String market;
  final String state;
  final int currentPrice;
  final int mspPrice;
  final String recommendation;
  final String reasonEn;
  final String reasonHi;
  final List<int> weeklyPrices;

  MandiPrice({
    required this.commodity,
    required this.market,
    required this.state,
    required this.currentPrice,
    required this.mspPrice,
    required this.recommendation,
    required this.reasonEn,
    required this.reasonHi,
    required this.weeklyPrices,
  });

  factory MandiPrice.fromMap(Map<String, dynamic> data) {
    return MandiPrice(
      commodity: data['commodity'] as String,
      market: data['market'] as String,
      state: data['state'] as String,
      currentPrice: data['currentPrice'] as int,
      mspPrice: data['mspPrice'] as int,
      recommendation: data['recommendation'] as String,
      reasonEn: data['reasonEn'] as String,
      reasonHi: data['reasonHi'] as String,
      weeklyPrices: List<int>.from(data['weeklyPrices'] as List),
    );
  }

  String getCommodityName() => commodity.split(' / ')[0];
  bool hasMSP() => mspPrice > 0;
  int getPriceDifference() => hasMSP() ? currentPrice - mspPrice : 0;
}
