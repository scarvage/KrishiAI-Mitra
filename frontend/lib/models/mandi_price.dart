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

  // Helper to extract commodity name without language suffix
  String getCommodityName() {
    return commodity.split(' / ')[0];
  }

  // Helper to check if MSP applies
  bool hasMSP() => mspPrice > 0;

  // Helper to calculate price difference from MSP
  int getPriceDifference() {
    if (!hasMSP()) return 0;
    return currentPrice - mspPrice;
  }

  // Helper to calculate percentage difference from MSP
  double getPricePercentageDifference() {
    if (!hasMSP()) return 0;
    return ((currentPrice - mspPrice) / mspPrice * 100).toStringAsFixed(1) as double;
  }
}
