// Mock data for the KrishiMitra hackathon demo
// This contains all hardcoded responses, disease results, and market prices

const Map<String, Map<String, String>> mockAIResponses = {
  'wheat': {
    'en': 'Wheat requires well-drained loamy soil with pH 6.0-7.0. '
        'Best sowing time in North India: October 15 - November 15. '
        'Apply DAP fertilizer at 50kg/acre before sowing.',
    'hi': 'गेहूं के लिए अच्छी जल निकासी वाली दोमट मिट्टी चाहिए, pH 6.0-7.0। '
        'उत्तर भारत में बुवाई का सबसे अच्छा समय: 15 अक्टूबर से 15 नवंबर। '
        'बुवाई से पहले 50 किग्रा/एकड़ DAP खाद डालें।',
  },
  'rice': {
    'en': 'Paddy cultivation needs waterlogged conditions. '
        'Transplant 25-day-old seedlings. Maintain 5cm standing water. '
        'Apply Urea in 3 splits: basal, tillering, and panicle initiation.',
    'hi': 'धान की खेती के लिए जलभराव वाली स्थिति चाहिए। '
        '25 दिन पुरानी पौध की रोपाई करें। 5 सेमी पानी बनाए रखें। '
        'यूरिया को 3 भागों में डालें।',
  },
  'disease': {
    'en': 'Common crop diseases: Leaf blight, Powdery mildew, Rust. '
        'Use Mancozeb 75 WP at 2.5g/litre water. Spray in the morning.',
    'hi': 'सामान्य फसल रोग: पत्ती झुलसा, पाउडरी फफूंदी, रतुआ। '
        'मैन्कोज़ेब 75 WP का 2.5 ग्राम/लीटर पानी में उपयोग करें।',
  },
  'fertilizer': {
    'en': 'For most Kharif crops: NPK ratio 4:2:1. Apply 40kg Urea, '
        '20kg DAP, 10kg MOP per acre. Split Urea application increases efficiency by 20%.',
    'hi': 'अधिकांश खरीफ फसलों के लिए: NPK अनुपात 4:2:1। '
        '40 किग्रा यूरिया, 20 किग्रा DAP, 10 किग्रा MOP प्रति एकड़।',
  },
  'default': {
    'en': 'I am Krishi Mitra, your farming assistant powered by Amazon Bedrock AI. '
        'You can ask me about crop diseases, fertilizers, sowing time, and market prices.',
    'hi': 'मैं कृषि मित्र हूं, Amazon Bedrock AI से संचालित आपका खेती सहायक। '
        'आप मुझसे फसल रोग, खाद, बुवाई का समय और बाजार भाव के बारे में पूछ सकते हैं।',
  },
};

const List<Map<String, dynamic>> mockDiseases = [
  {
    'name': 'Late Blight',
    'nameHindi': 'पछेती झुलसा',
    'crop': 'Tomato / Potato',
    'confidence': 94,
    'severity': 'High',
    'color': 0xFFF44336,
    'icon': '🍅',
    'treatment': [
      'Apply Metalaxyl + Mancozeb (Ridomil Gold) @ 2.5g/L',
      'Remove and destroy infected plant material immediately',
      'Avoid overhead irrigation; use drip if possible',
      'Re-spray every 7-10 days during humid conditions',
    ],
    'treatmentHindi': [
      'मेटालेक्सिल + मैन्कोज़ेब (रिडोमिल गोल्ड) @ 2.5 ग्राम/लीटर डालें',
      'संक्रमित पौधे तुरंत हटाएं और नष्ट करें',
      'छिड़काव सिंचाई से बचें; संभव हो तो ड्रिप का उपयोग करें',
      'नम परिस्थितियों में हर 7-10 दिन पर दोबारा छिड़काव करें',
    ],
  },
  {
    'name': 'Powdery Mildew',
    'nameHindi': 'पाउडरी फफूंदी',
    'crop': 'Wheat / Cucumber',
    'confidence': 88,
    'severity': 'Medium',
    'color': 0xFFFF9800,
    'icon': '🌾',
    'treatment': [
      'Spray Sulphur 80 WP @ 3g/L or Hexaconazole @ 1ml/L',
      'Ensure proper plant spacing for air circulation',
      'Apply potassium bicarbonate as organic option',
      'Avoid excess nitrogen fertilization',
    ],
    'treatmentHindi': [
      'सल्फर 80 WP @ 3 ग्राम/लीटर या हेक्साकोनाज़ोल @ 1 मिली/लीटर छिड़काव करें',
      'हवा के संचार के लिए उचित पौध दूरी सुनिश्चित करें',
      'जैविक विकल्प के रूप में पोटेशियम बाइकार्बोनेट डालें',
      'अत्यधिक नाइट्रोजन खाद से बचें',
    ],
  },
  {
    'name': 'Healthy Crop',
    'nameHindi': 'स्वस्थ फसल',
    'crop': 'No disease detected',
    'confidence': 97,
    'severity': 'None',
    'color': 0xFF4CAF50,
    'icon': '✅',
    'treatment': [
      'Your crop looks healthy! Continue current practices.',
      'Monitor regularly for early signs of pest or disease.',
      'Maintain soil moisture and balanced fertilization.',
      'Keep fields clean of crop residue.',
    ],
    'treatmentHindi': [
      'आपकी फसल स्वस्थ दिखती है! वर्तमान प्रथाएं जारी रखें।',
      'कीट या रोग के शुरुआती संकेतों के लिए नियमित निगरानी करें।',
      'मिट्टी की नमी और संतुलित खाद बनाए रखें।',
      'खेतों को फसल के अवशेष से साफ रखें।',
    ],
  },
];

const List<Map<String, dynamic>> mockMandiPrices = [
  {
    'commodity': 'Wheat / गेहूं',
    'market': 'Indore Mandi',
    'state': 'Madhya Pradesh',
    'currentPrice': 2180,
    'unit': 'per quintal',
    'mspPrice': 2275,
    'recommendation': 'HOLD',
    'reasonEn':
        'Price is 4% below MSP. Market trend shows upward movement. Hold for 2 weeks.',
    'reasonHi': 'भाव MSP से 4% नीचे है। बाजार का रुझान ऊपर की ओर है। 2 सप्ताह रोकें।',
    'weeklyPrices': [2050, 2090, 2120, 2100, 2145, 2160, 2180],
  },
  {
    'commodity': 'Soybean / सोयाबीन',
    'market': 'Ujjain Mandi',
    'state': 'Madhya Pradesh',
    'currentPrice': 4650,
    'unit': 'per quintal',
    'mspPrice': 4600,
    'recommendation': 'SELL',
    'reasonEn': 'Price is 1% above MSP and at a 30-day high. Good time to sell.',
    'reasonHi': 'भाव MSP से 1% ऊपर है और 30 दिनों के उच्चतम स्तर पर है। बेचने का अच्छा समय।',
    'weeklyPrices': [4200, 4310, 4400, 4480, 4520, 4590, 4650],
  },
  {
    'commodity': 'Onion / प्याज',
    'market': 'Lasalgaon Mandi',
    'state': 'Maharashtra',
    'currentPrice': 1820,
    'unit': 'per quintal',
    'mspPrice': 0,
    'recommendation': 'WAIT',
    'reasonEn':
        'Prices volatile. Festival season demand expected in 3 weeks. Wait for better price.',
    'reasonHi': 'भाव अस्थिर है। 3 सप्ताह में त्योहारी मांग बढ़ने की उम्मीद। बेहतर भाव का इंतजार करें।',
    'weeklyPrices': [2100, 1950, 1800, 1750, 1790, 1810, 1820],
  },
  {
    'commodity': 'Cotton / कपास',
    'market': 'Akola Mandi',
    'state': 'Maharashtra',
    'currentPrice': 6200,
    'unit': 'per quintal',
    'mspPrice': 6620,
    'recommendation': 'HOLD',
    'reasonEn': 'Price 6% below MSP. Government procurement likely to open. Do not sell yet.',
    'reasonHi': 'भाव MSP से 6% नीचे है। सरकारी खरीद जल्द खुलने की संभावना। अभी न बेचें।',
    'weeklyPrices': [6500, 6400, 6350, 6280, 6250, 6220, 6200],
  },
];
