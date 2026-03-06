const axios = require('axios');
const { BedrockRuntimeClient, InvokeModelCommand } = require('@aws-sdk/client-bedrock-runtime');
const logger = require('../utils/logger');

// HuggingFace inference endpoint (requires a free HF token set in HUGGINGFACE_API_KEY).
// Models are tried in order; if all fail we fall back to Bedrock.
const HF_MODELS = [
  'linkanjarad/mobilenet_v2_1.0_224-plant-disease-identification',
];

// Retry config
const MAX_RETRIES = 2;
const RETRY_DELAY_MS = 2000;

/**
 * Comprehensive treatment database keyed on lowercase label fragments.
 * Each entry: { en: [...], hi: [...], cropType, severity, nameHindi }
 */
const TREATMENT_DB = {
  'apple___apple_scab': {
    nameHindi: 'सेब की पपड़ी',
    cropType: 'Apple',
    severity: 'medium',
    en: [
      'Apply Captan or Mancozeb fungicide every 7-10 days',
      'Prune and remove infected leaves and twigs',
      'Rake and destroy fallen leaves to reduce spore load',
      'Plant scab-resistant apple varieties in future seasons',
    ],
    hi: [
      'हर 7-10 दिनों में कैप्टान या मैन्कोज़ेब कवकनाशी स्प्रे करें',
      'संक्रमित पत्तियों और टहनियों को काटकर हटाएं',
      'गिरी हुई पत्तियों को इकट्ठा करके नष्ट करें',
      'भविष्य में पपड़ी प्रतिरोधी सेब की किस्में लगाएं',
    ],
  },
  'apple___black_rot': {
    nameHindi: 'सेब का काला सड़न',
    cropType: 'Apple',
    severity: 'high',
    en: [
      'Remove mummified fruits and infected canes immediately',
      'Apply Captan 50 WP @ 2g/L at petal fall and repeat every 10-14 days',
      'Improve orchard sanitation by clearing debris',
      'Avoid wounding fruit during harvest',
    ],
    hi: [
      'सूखे फलों और संक्रमित शाखाओं को तुरंत हटाएं',
      'पंखुड़ी गिरने के बाद कैप्टान 50 WP @ 2 ग्राम/लीटर स्प्रे करें',
      'बाग की साफ-सफाई करें',
      'कटाई के दौरान फलों को चोट लगने से बचाएं',
    ],
  },
  'apple___cedar_apple_rust': {
    nameHindi: 'सेब का रतुआ',
    cropType: 'Apple',
    severity: 'medium',
    en: [
      'Apply Myclobutanil (Rally) @ 1.5ml/L from green tip through cover',
      'Remove nearby Eastern red cedar trees if possible',
      'Apply protective fungicides before and after rainy periods',
    ],
    hi: [
      'हरी कली से लेकर ढकने तक माइक्लोब्यूटानिल @ 1.5 मिली/लीटर स्प्रे करें',
      'संभव हो तो पास के देवदार के पेड़ हटाएं',
      'बारिश से पहले और बाद में कवकनाशी लगाएं',
    ],
  },
  'apple___healthy': {
    nameHindi: 'स्वस्थ सेब',
    cropType: 'Apple',
    severity: 'none',
    en: ['Crop appears healthy. Continue regular monitoring and balanced fertilization.'],
    hi: ['फसल स्वस्थ दिखती है। नियमित निगरानी और संतुलित खाद जारी रखें।'],
  },
  'blueberry___healthy': {
    nameHindi: 'स्वस्थ ब्लूबेरी',
    cropType: 'Blueberry',
    severity: 'none',
    en: ['Blueberry plant looks healthy. Continue regular care and monitoring.'],
    hi: ['ब्लूबेरी का पौधा स्वस्थ दिखता है। नियमित देखभाल और निगरानी जारी रखें।'],
  },
  'cherry___powdery_mildew': {
    nameHindi: 'चेरी का चूर्णिल आसिता',
    cropType: 'Cherry',
    severity: 'medium',
    en: [
      'Apply Sulfur-based fungicide @ 3g/L at first sign of white powdery growth',
      'Prune infected shoots and improve air circulation',
      'Avoid excessive nitrogen fertilization',
      'Apply Myclobutanil @ 1ml/L for severe infections',
    ],
    hi: [
      'सफेद चूर्णी वृद्धि के पहले लक्षण पर सल्फर आधारित कवकनाशी @ 3 ग्राम/लीटर स्प्रे करें',
      'संक्रमित शाखाओं को काटें और हवा का संचार सुधारें',
      'अत्यधिक नाइट्रोजन खाद से बचें',
      'गंभीर संक्रमण के लिए माइक्लोब्यूटानिल @ 1 मिली/लीटर स्प्रे करें',
    ],
  },
  'cherry___healthy': {
    nameHindi: 'स्वस्थ चेरी',
    cropType: 'Cherry',
    severity: 'none',
    en: ['Cherry plant looks healthy. Continue regular care and monitoring.'],
    hi: ['चेरी का पौधा स्वस्थ दिखता है। नियमित देखभाल और निगरानी जारी रखें।'],
  },
  'corn_(maize)___cercospora_leaf_spot gray_leaf_spot': {
    nameHindi: 'मक्का का भूरा धब्बा',
    cropType: 'Maize',
    severity: 'medium',
    en: [
      'Apply Azoxystrobin or Propiconazole @ 1ml/L at tasseling',
      'Use resistant hybrids in future plantings',
      'Ensure proper crop rotation (avoid corn-on-corn)',
      'Maintain adequate plant spacing for air circulation',
    ],
    hi: [
      'टैसलिंग पर अजोक्सीस्ट्रोबिन या प्रोपिकोनाज़ोल @ 1 मिली/लीटर स्प्रे करें',
      'भविष्य में प्रतिरोधी संकर किस्में लगाएं',
      'फसल चक्र अपनाएं',
      'हवा के संचार के लिए उचित दूरी रखें',
    ],
  },
  'corn_(maize)___common_rust': {
    nameHindi: 'मक्का का सामान्य रतुआ',
    cropType: 'Maize',
    severity: 'medium',
    en: [
      'Apply Mancozeb 75 WP @ 2.5g/L at first sign of rust pustules',
      'Use rust-resistant corn hybrids',
      'Apply fungicide during humid weather conditions',
    ],
    hi: [
      'रतुआ के पहले लक्षण पर मैन्कोज़ेब 75 WP @ 2.5 ग्राम/लीटर स्प्रे करें',
      'रतुआ प्रतिरोधी संकर किस्में उगाएं',
      'नम मौसम में कवकनाशी लगाएं',
    ],
  },
  'corn_(maize)___northern_leaf_blight': {
    nameHindi: 'मक्का का उत्तरी पत्ती झुलसा',
    cropType: 'Maize',
    severity: 'high',
    en: [
      'Apply Azoxystrobin + Propiconazole (Headline AMP) @ 1.5ml/L',
      'Plant blight-resistant hybrids next season',
      'Rotate crops and till infected residue',
    ],
    hi: [
      'अजोक्सीस्ट्रोबिन + प्रोपिकोनाज़ोल @ 1.5 मिली/लीटर स्प्रे करें',
      'अगले मौसम में झुलसा प्रतिरोधी संकर किस्में लगाएं',
      'फसल चक्र अपनाएं और संक्रमित अवशेष जोतें',
    ],
  },
  'corn_(maize)___healthy': {
    nameHindi: 'स्वस्थ मक्का',
    cropType: 'Maize',
    severity: 'none',
    en: ['Corn crop looks healthy. Continue current practices.'],
    hi: ['मक्का की फसल स्वस्थ दिखती है। वर्तमान प्रथाएं जारी रखें।'],
  },
  'grape___black_rot': {
    nameHindi: 'अंगूर का काला सड़न',
    cropType: 'Grape',
    severity: 'high',
    en: [
      'Apply Mancozeb or Myclobutanil from bud break every 10-14 days',
      'Remove mummified berries and infected canes',
      'Train vines for maximum air circulation',
    ],
    hi: [
      'कली फूटने से हर 10-14 दिन मैन्कोज़ेब या माइक्लोब्यूटानिल स्प्रे करें',
      'सूखे जामुन और संक्रमित शाखाएं हटाएं',
      'बेलों को हवा के लिए प्रशिक्षित करें',
    ],
  },
  'grape___esca': {
    nameHindi: 'अंगूर का एस्का (काला खसरा)',
    cropType: 'Grape',
    severity: 'high',
    en: [
      'Remove and destroy severely infected vines',
      'Prune during dry weather to prevent wound infections',
      'Apply wound sealant after pruning cuts',
      'Avoid excessive irrigation stress on vines',
    ],
    hi: [
      'गंभीर रूप से संक्रमित बेलें हटाकर नष्ट करें',
      'घाव संक्रमण रोकने के लिए सूखे मौसम में छंटाई करें',
      'छंटाई के बाद घाव सीलेंट लगाएं',
      'बेलों पर अत्यधिक सिंचाई तनाव से बचें',
    ],
  },
  'grape___isariopsis_leaf_spot': {
    nameHindi: 'अंगूर का इसारियोप्सिस पत्ती धब्बा',
    cropType: 'Grape',
    severity: 'medium',
    en: [
      'Apply Mancozeb 75 WP @ 2.5g/L at first sign of spots',
      'Remove and destroy infected leaves',
      'Improve air circulation by proper canopy management',
      'Avoid overhead irrigation',
    ],
    hi: [
      'धब्बों के पहले लक्षण पर मैन्कोज़ेब 75 WP @ 2.5 ग्राम/लीटर स्प्रे करें',
      'संक्रमित पत्तियां हटाकर नष्ट करें',
      'उचित कैनोपी प्रबंधन से हवा संचार सुधारें',
      'ऊपर से पानी देने से बचें',
    ],
  },
  'grape___healthy': {
    nameHindi: 'स्वस्थ अंगूर',
    cropType: 'Grape',
    severity: 'none',
    en: ['Grapevine is healthy. Maintain current spray schedule.'],
    hi: ['अंगूर की बेल स्वस्थ है। वर्तमान स्प्रे कार्यक्रम जारी रखें।'],
  },
  'orange___citrus_greening': {
    nameHindi: 'संतरे का साइट्रस ग्रीनिंग',
    cropType: 'Orange',
    severity: 'high',
    en: [
      'Remove and destroy infected trees to prevent spread',
      'Control Asian citrus psyllid vectors with Imidacloprid @ 0.5ml/L',
      'Use certified disease-free nursery stock for new plantings',
      'Apply balanced nutrition to maintain tree health',
    ],
    hi: [
      'फैलाव रोकने के लिए संक्रमित पेड़ हटाकर नष्ट करें',
      'एशियाई साइट्रस सिल्लिड नियंत्रण के लिए इमिडाक्लोप्रिड @ 0.5 मिली/लीटर स्प्रे करें',
      'नए रोपण के लिए प्रमाणित रोगमुक्त नर्सरी पौधे उपयोग करें',
      'पेड़ के स्वास्थ्य के लिए संतुलित पोषण दें',
    ],
  },
  'peach___bacterial_spot': {
    nameHindi: 'आड़ू का जीवाणु धब्बा',
    cropType: 'Peach',
    severity: 'medium',
    en: [
      'Apply Copper Oxychloride 50 WP @ 3g/L during dormant season',
      'Prune infected branches to improve air circulation',
      'Avoid overhead irrigation',
      'Use disease-resistant peach varieties',
    ],
    hi: [
      'सुप्त अवस्था में कॉपर ऑक्सीक्लोराइड 50 WP @ 3 ग्राम/लीटर स्प्रे करें',
      'हवा संचार सुधारने के लिए संक्रमित शाखाएं काटें',
      'ऊपर से पानी देने से बचें',
      'रोग प्रतिरोधी आड़ू किस्में उपयोग करें',
    ],
  },
  'peach___healthy': {
    nameHindi: 'स्वस्थ आड़ू',
    cropType: 'Peach',
    severity: 'none',
    en: ['Peach tree looks healthy. Continue regular care and monitoring.'],
    hi: ['आड़ू का पेड़ स्वस्थ दिखता है। नियमित देखभाल और निगरानी जारी रखें।'],
  },
  'bell_pepper___bacterial_spot': {
    nameHindi: 'शिमला मिर्च का जीवाणु धब्बा',
    cropType: 'Bell Pepper',
    severity: 'medium',
    en: [
      'Apply Copper Oxychloride 50 WP @ 3g/L every 7-10 days',
      'Remove infected plant debris from the field',
      'Use disease-free certified seeds',
      'Avoid working in fields when plants are wet',
    ],
    hi: [
      'हर 7-10 दिन कॉपर ऑक्सीक्लोराइड 50 WP @ 3 ग्राम/लीटर स्प्रे करें',
      'खेत से संक्रमित पौधे के अवशेष हटाएं',
      'प्रमाणित रोगमुक्त बीजों का उपयोग करें',
      'पौधे गीले हों तब खेत में काम करने से बचें',
    ],
  },
  'bell_pepper___healthy': {
    nameHindi: 'स्वस्थ शिमला मिर्च',
    cropType: 'Bell Pepper',
    severity: 'none',
    en: ['Bell pepper plant looks healthy. Continue regular care and monitoring.'],
    hi: ['शिमला मिर्च का पौधा स्वस्थ दिखता है। नियमित देखभाल और निगरानी जारी रखें।'],
  },
  'potato___early_blight': {
    nameHindi: 'आलू का अगेती झुलसा',
    cropType: 'Potato',
    severity: 'medium',
    en: [
      'Apply Mancozeb 75 WP @ 2.5g/L at first symptom appearance',
      'Remove and destroy infected plant parts',
      'Avoid overhead irrigation; water at the base',
      'Maintain proper spacing and crop rotation',
    ],
    hi: [
      'पहले लक्षण पर मैन्कोज़ेब 75 WP @ 2.5 ग्राम/लीटर स्प्रे करें',
      'संक्रमित पौधे के हिस्से हटाकर नष्ट करें',
      'ऊपर से पानी देने से बचें; जड़ में पानी दें',
      'उचित दूरी और फसल चक्र अपनाएं',
    ],
  },
  'potato___late_blight': {
    nameHindi: 'आलू का पछेती झुलसा',
    cropType: 'Potato',
    severity: 'high',
    en: [
      'Apply Metalaxyl + Mancozeb (Ridomil Gold) @ 2.5g/L immediately',
      'Destroy severely infected plants to prevent spread',
      'Avoid overhead irrigation and improve drainage',
      'Re-apply every 7 days during humid conditions',
    ],
    hi: [
      'तुरंत मेटालेक्सिल + मैन्कोज़ेब (रिडोमिल गोल्ड) @ 2.5 ग्राम/लीटर स्प्रे करें',
      'गंभीर रूप से संक्रमित पौधे नष्ट करें',
      'ऊपर से पानी देने से बचें और जल निकासी सुधारें',
      'नम परिस्थितियों में हर 7 दिन पर दोबारा स्प्रे करें',
    ],
  },
  'potato___healthy': {
    nameHindi: 'स्वस्थ आलू',
    cropType: 'Potato',
    severity: 'none',
    en: ['Potato crop is healthy. Maintain balanced fertilization and irrigation.'],
    hi: ['आलू की फसल स्वस्थ है। संतुलित खाद और सिंचाई जारी रखें।'],
  },
  'raspberry___healthy': {
    nameHindi: 'स्वस्थ रास्पबेरी',
    cropType: 'Raspberry',
    severity: 'none',
    en: ['Raspberry plant looks healthy. Continue regular care and monitoring.'],
    hi: ['रास्पबेरी का पौधा स्वस्थ दिखता है। नियमित देखभाल और निगरानी जारी रखें।'],
  },
  'soybean___healthy': {
    nameHindi: 'स्वस्थ सोयाबीन',
    cropType: 'Soybean',
    severity: 'none',
    en: ['Soybean crop looks healthy. Continue regular care and monitoring.'],
    hi: ['सोयाबीन की फसल स्वस्थ दिखती है। नियमित देखभाल और निगरानी जारी रखें।'],
  },
  'squash___powdery_mildew': {
    nameHindi: 'कद्दू का चूर्णिल आसिता',
    cropType: 'Squash',
    severity: 'medium',
    en: [
      'Apply Sulfur-based fungicide @ 3g/L at first sign of white powdery growth',
      'Remove heavily infected leaves',
      'Improve air circulation with proper plant spacing',
      'Avoid overhead irrigation',
    ],
    hi: [
      'सफेद चूर्णी वृद्धि के पहले लक्षण पर सल्फर आधारित कवकनाशी @ 3 ग्राम/लीटर स्प्रे करें',
      'बुरी तरह संक्रमित पत्तियां हटाएं',
      'उचित पौध दूरी से हवा संचार सुधारें',
      'ऊपर से पानी देने से बचें',
    ],
  },
  'strawberry___leaf_scorch': {
    nameHindi: 'स्ट्रॉबेरी का पत्ती झुलसा',
    cropType: 'Strawberry',
    severity: 'medium',
    en: [
      'Apply Copper-based fungicide @ 3g/L at first symptom',
      'Remove and destroy infected leaves',
      'Improve air circulation with proper plant spacing',
      'Avoid overhead irrigation; water at the base',
    ],
    hi: [
      'पहले लक्षण पर कॉपर आधारित कवकनाशी @ 3 ग्राम/लीटर स्प्रे करें',
      'संक्रमित पत्तियां हटाकर नष्ट करें',
      'उचित पौध दूरी से हवा संचार सुधारें',
      'ऊपर से पानी देने से बचें; जड़ में पानी दें',
    ],
  },
  'strawberry___healthy': {
    nameHindi: 'स्वस्थ स्ट्रॉबेरी',
    cropType: 'Strawberry',
    severity: 'none',
    en: ['Strawberry plant looks healthy. Continue regular care and monitoring.'],
    hi: ['स्ट्रॉबेरी का पौधा स्वस्थ दिखता है। नियमित देखभाल और निगरानी जारी रखें।'],
  },
  'tomato___bacterial_spot': {
    nameHindi: 'टमाटर का जीवाणु धब्बा',
    cropType: 'Tomato',
    severity: 'medium',
    en: [
      'Apply Copper Oxychloride 50 WP @ 3g/L every 7-10 days',
      'Remove infected plant debris from the field',
      'Use disease-free certified seeds',
      'Avoid working in fields when plants are wet',
    ],
    hi: [
      'हर 7-10 दिन कॉपर ऑक्सीक्लोराइड 50 WP @ 3 ग्राम/लीटर स्प्रे करें',
      'खेत से संक्रमित पौधे के अवशेष हटाएं',
      'प्रमाणित रोगमुक्त बीजों का उपयोग करें',
      'पौधे गीले हों तब खेत में काम करने से बचें',
    ],
  },
  'tomato___early_blight': {
    nameHindi: 'टमाटर का अगेती झुलसा',
    cropType: 'Tomato',
    severity: 'medium',
    en: [
      'Spray Mancozeb 75 WP @ 2.5g/L at first sign of brown spots',
      'Remove lower infected leaves',
      'Mulch soil to prevent spore splash',
      'Ensure adequate potassium nutrition',
    ],
    hi: [
      'भूरे धब्बों के पहले संकेत पर मैन्कोज़ेब 75 WP @ 2.5 ग्राम/लीटर स्प्रे करें',
      'निचली संक्रमित पत्तियां हटाएं',
      'बीजाणु के छींटे रोकने के लिए मल्च करें',
      'पर्याप्त पोटाश खाद सुनिश्चित करें',
    ],
  },
  'tomato___late_blight': {
    nameHindi: 'टमाटर का पछेती झुलसा',
    cropType: 'Tomato',
    severity: 'high',
    en: [
      'Apply Metalaxyl + Mancozeb (Ridomil Gold) @ 2.5g/L immediately',
      'Remove and destroy all infected plants',
      'Apply fungicide preventively during cool, wet weather',
      'Avoid overhead irrigation',
    ],
    hi: [
      'तुरंत मेटालेक्सिल + मैन्कोज़ेब @ 2.5 ग्राम/लीटर स्प्रे करें',
      'सभी संक्रमित पौधे हटाकर नष्ट करें',
      'ठंडे, गीले मौसम में कवकनाशी का निवारक उपयोग करें',
      'ऊपर से पानी देने से बचें',
    ],
  },
  'tomato___leaf_miner': {
    nameHindi: 'टमाटर की पत्ती खनिक',
    cropType: 'Tomato',
    severity: 'medium',
    en: [
      'Apply Spinosad @ 0.5ml/L or Abamectin @ 0.5ml/L',
      'Remove and destroy heavily mined leaves',
      'Use yellow sticky traps for monitoring',
      'Encourage natural parasitoid populations',
    ],
    hi: [
      'स्पिनोसैड @ 0.5 मिली/लीटर या एबामेक्टिन @ 0.5 मिली/लीटर स्प्रे करें',
      'बुरी तरह से संक्रमित पत्तियां हटाएं',
      'पीले चिपचिपे जाल लगाएं',
      'प्राकृतिक परजीवी कीटों को बढ़ावा दें',
    ],
  },
  'tomato___leaf_mold': {
    nameHindi: 'टमाटर का पत्ती फफूंद',
    cropType: 'Tomato',
    severity: 'medium',
    en: [
      'Apply Chlorothalonil @ 2g/L or Copper Oxychloride @ 3g/L',
      'Improve greenhouse ventilation to reduce humidity',
      'Avoid overhead watering',
      'Remove infected leaves promptly',
    ],
    hi: [
      'क्लोरोथेलोनिल @ 2 ग्राम/लीटर या कॉपर ऑक्सीक्लोराइड @ 3 ग्राम/लीटर स्प्रे करें',
      'नमी कम करने के लिए ग्रीनहाउस में वेंटिलेशन सुधारें',
      'ऊपर से पानी देने से बचें',
      'संक्रमित पत्तियां तुरंत हटाएं',
    ],
  },
  'tomato___septoria_leaf_spot': {
    nameHindi: 'टमाटर का सेप्टोरिया पत्ती धब्बा',
    cropType: 'Tomato',
    severity: 'medium',
    en: [
      'Apply Copper-based fungicide or Chlorothalonil @ 2g/L',
      'Remove and destroy infected plant material',
      'Mulch soil to prevent rain splash',
      'Rotate crops for at least 3 years',
    ],
    hi: [
      'कॉपर आधारित कवकनाशी या क्लोरोथेलोनिल @ 2 ग्राम/लीटर स्प्रे करें',
      'संक्रमित पौधे सामग्री हटाएं और नष्ट करें',
      'बारिश के छींटे रोकने के लिए मल्च करें',
      'कम से कम 3 साल के लिए फसल चक्र अपनाएं',
    ],
  },
  'tomato___spider_mites two-spotted_spider_mite': {
    nameHindi: 'टमाटर का मकड़ी घुन',
    cropType: 'Tomato',
    severity: 'medium',
    en: [
      'Apply Abamectin @ 0.5ml/L or Spiromesifen @ 1ml/L',
      'Spray water forcefully on undersides of leaves to dislodge mites',
      'Maintain adequate soil moisture to reduce plant stress',
      'Introduce predatory mites for biological control',
    ],
    hi: [
      'एबामेक्टिन @ 0.5 मिली/लीटर या स्पिरोमेसिफेन @ 1 मिली/लीटर स्प्रे करें',
      'घुन हटाने के लिए पत्तियों के नीचे जोर से पानी छिड़कें',
      'पौधे का तनाव कम करने के ल���ए पर्याप्त नमी बनाए रखें',
      'जैविक नियंत्रण के लिए शिकारी घुन छोड़ें',
    ],
  },
  'tomato___target_spot': {
    nameHindi: 'टमाटर का लक्ष्य धब्बा',
    cropType: 'Tomato',
    severity: 'medium',
    en: [
      'Apply Azoxystrobin @ 1ml/L at first symptom',
      'Improve plant spacing to increase air movement',
      'Remove lower infected leaves',
      'Irrigate at soil level, not overhead',
    ],
    hi: [
      'पहले लक्षण पर अजोक्सीस्ट्रोबिन @ 1 मिली/लीटर स्प्रे करें',
      'हवा के संचार के लिए पौधों की दूरी बढ़ाएं',
      'निचली संक्रमित पत्तियां हटाएं',
      'मिट्टी के स्तर पर सिंचाई करें, ऊपर से नहीं',
    ],
  },
  'tomato___tomato_mosaic_virus': {
    nameHindi: 'टमाटर का मोज़ेक वायरस',
    cropType: 'Tomato',
    severity: 'high',
    en: [
      'Remove and destroy all infected plants immediately',
      'Disinfect tools and hands frequently with soap',
      'Control aphids (virus vectors) with Imidacloprid @ 0.5ml/L',
      'Use virus-resistant tomato varieties',
    ],
    hi: [
      'सभी संक्रमित पौधे तुरंत हटाकर नष्ट करें',
      'साबुन से हाथ और औजार बार-बार साफ करें',
      'इमिडाक्लोप्रिड @ 0.5 मिली/लीटर से माहू नियंत्रित करें',
      'वायरस प्रतिरोधी टमाटर की किस्में उपयोग करें',
    ],
  },
  'tomato___tomato_yellow_leaf_curl_virus': {
    nameHindi: 'टमाटर का पीला पत्ती मुड़ना वायरस',
    cropType: 'Tomato',
    severity: 'high',
    en: [
      'Remove infected plants immediately to prevent spread',
      'Apply Imidacloprid 17.8 SL @ 0.5ml/L to control whitefly vectors',
      'Use reflective silver mulches to repel whiteflies',
      'Plant certified virus-free seedlings only',
    ],
    hi: [
      'फैलाव रोकने के लिए संक्रमित पौधे तुरंत हटाएं',
      'सफेद मक्खी नियंत्रण के लिए इमिडाक्लोप्रिड @ 0.5 मिली/लीटर स्प्रे करें',
      'सफेद मक्खी दूर भगाने के लिए चांदी का मल्च बिछाएं',
      'केवल प्रमाणित वायरस मुक्त पौध लगाएं',
    ],
  },
  'tomato___healthy': {
    nameHindi: 'स्वस्थ टमाटर',
    cropType: 'Tomato',
    severity: 'none',
    en: ['Tomato plant looks healthy. Continue regular care and monitoring.'],
    hi: ['टमाटर का पौधा स्वस्थ दिखता है। नियमित देखभाल और निगरानी जारी रखें।'],
  },
  'wheat___septoria': {
    nameHindi: 'गेहूं का सेप्टोरिया',
    cropType: 'Wheat',
    severity: 'medium',
    en: [
      'Apply Propiconazole 25 EC @ 1ml/L at flag leaf stage',
      'Use certified disease-free seeds',
      'Destroy crop residue after harvest',
      'Maintain optimal plant spacing',
    ],
    hi: [
      'ध्वज पत्ती अवस्था पर प्रोपिकोनाज़ोल 25 EC @ 1 मिली/लीटर स्प्रे करें',
      'प्रमाणित रोगमुक्त बीजों का उपयोग करें',
      'कटाई के बाद फसल अवशेष नष्ट करें',
      'उचित पौध दूरी बनाए रखें',
    ],
  },
  'wheat___yellow_rust': {
    nameHindi: 'गेहूं का पीला रतुआ',
    cropType: 'Wheat',
    severity: 'high',
    en: [
      'Apply Propiconazole 25 EC @ 1ml/L or Tebuconazole @ 1ml/L at first sign',
      'Repeat spray after 14 days if conditions remain humid',
      'Use resistant wheat varieties (HD-2967, WH-1105)',
      'Avoid excessive nitrogen application',
    ],
    hi: [
      'पहले लक्षण पर प्रोपिकोनाज़ोल 25 EC @ 1 मिली/लीटर स्प्रे करें',
      'नम परिस्थितियों में 14 दिन बाद दोबारा स्प्रे करें',
      'प्रतिरोधी गेहूं किस्में उगाएं (HD-2967, WH-1105)',
      'अत्यधिक नाइट्रोजन खाद से बचें',
    ],
  },
  'rice___leaf_blight': {
    nameHindi: 'धान का पत्ती झुलसा',
    cropType: 'Rice',
    severity: 'high',
    en: [
      'Apply Tricyclazole 75 WP @ 0.6g/L or Isoprothiolane @ 1.5ml/L',
      'Drain and dry fields to reduce humidity',
      'Avoid heavy nitrogen application',
      'Remove infected plants from seed bed',
    ],
    hi: [
      'ट्राइसाइक्लाज़ोल 75 WP @ 0.6 ग्राम/लीटर या आइसोप्रोथियोलेन @ 1.5 मिली/लीटर स्प्रे करें',
      'नमी कम करने के लिए खेत में पानी निकालें और सुखाएं',
      'भारी नाइट्रोजन खाद से बचें',
      'नर्सरी से संक्रमित पौधे हटाएं',
    ],
  },
  'default': {
    nameHindi: 'फसल रोग',
    cropType: 'Unknown',
    severity: 'medium',
    en: [
      'Consult your local Krishi Vigyan Kendra (KVK) for expert diagnosis',
      'Collect a sample in a sealed bag and bring to the nearest agricultural office',
      'Apply a broad-spectrum fungicide like Mancozeb 75 WP @ 2.5g/L as a precautionary measure',
      'Avoid irrigating during peak disease conditions',
    ],
    hi: [
      'सटीक निदान के लिए अपने स्थानीय कृषि विज्ञान केंद्र (KVK) से संपर्क करें',
      'एक सीलबंद थैले में नमूना लेकर नजदीकी कृषि कार्यालय जाएं',
      'एहतियात के तौर पर मैन्कोज़ेब 75 WP @ 2.5 ग्राम/लीटर छिड़काव करें',
      'रोग की चरम स्थिति में सिंचाई से बचें',
    ],
  },
};

/**
 * Direct mapping from HuggingFace model labels (id2label in config.json)
 * to TREATMENT_DB keys.  The HF model returns human-readable labels like
 * "Strawberry with Leaf Scorch", NOT PlantVillage "crop___disease" format.
 */
const HF_LABEL_TO_DB_KEY = {
  'apple scab': 'apple___apple_scab',
  'apple with black rot': 'apple___black_rot',
  'cedar apple rust': 'apple___cedar_apple_rust',
  'healthy apple': 'apple___healthy',
  'healthy blueberry plant': 'blueberry___healthy',
  'cherry with powdery mildew': 'cherry___powdery_mildew',
  'healthy cherry plant': 'cherry___healthy',
  'corn (maize) with cercospora and gray leaf spot': 'corn_(maize)___cercospora_leaf_spot gray_leaf_spot',
  'corn (maize) with common rust': 'corn_(maize)___common_rust',
  'corn (maize) with northern leaf blight': 'corn_(maize)___northern_leaf_blight',
  'healthy corn (maize) plant': 'corn_(maize)___healthy',
  'grape with black rot': 'grape___black_rot',
  'grape with esca (black measles)': 'grape___esca',
  'grape with isariopsis leaf spot': 'grape___isariopsis_leaf_spot',
  'healthy grape plant': 'grape___healthy',
  'orange with citrus greening': 'orange___citrus_greening',
  'peach with bacterial spot': 'peach___bacterial_spot',
  'healthy peach plant': 'peach___healthy',
  'bell pepper with bacterial spot': 'bell_pepper___bacterial_spot',
  'healthy bell pepper plant': 'bell_pepper___healthy',
  'potato with early blight': 'potato___early_blight',
  'potato with late blight': 'potato___late_blight',
  'healthy potato plant': 'potato___healthy',
  'healthy raspberry plant': 'raspberry___healthy',
  'healthy soybean plant': 'soybean___healthy',
  'squash with powdery mildew': 'squash___powdery_mildew',
  'strawberry with leaf scorch': 'strawberry___leaf_scorch',
  'healthy strawberry plant': 'strawberry___healthy',
  'tomato with bacterial spot': 'tomato___bacterial_spot',
  'tomato with early blight': 'tomato___early_blight',
  'tomato with late blight': 'tomato___late_blight',
  'tomato with leaf mold': 'tomato___leaf_mold',
  'tomato with septoria leaf spot': 'tomato___septoria_leaf_spot',
  'tomato with spider mites or two-spotted spider mite': 'tomato___spider_mites two-spotted_spider_mite',
  'tomato with target spot': 'tomato___target_spot',
  'tomato yellow leaf curl virus': 'tomato___tomato_yellow_leaf_curl_virus',
  'tomato mosaic virus': 'tomato___tomato_mosaic_virus',
  'healthy tomato plant': 'tomato___healthy',
};

/**
 * Map a HuggingFace label string to the nearest key in TREATMENT_DB.
 */
const mapLabelToKey = (label) => {
  if (!label) return 'default';
  const lower = label.toLowerCase().trim();

  // Exact match against TREATMENT_DB
  if (TREATMENT_DB[lower]) return lower;

  // Direct HF label lookup
  if (HF_LABEL_TO_DB_KEY[lower]) {
    const dbKey = HF_LABEL_TO_DB_KEY[lower];
    if (TREATMENT_DB[dbKey]) return dbKey;
  }

  const fragments = Object.keys(TREATMENT_DB).filter((k) => k !== 'default');

  // Pass 1: crop + disease both present (highest confidence)
  for (const key of fragments) {
    const keyParts = key.split('___');
    if (keyParts.length === 2) {
      const crop = keyParts[0].replace(/_/g, ' ').replace(/[()]/g, '');
      const disease = keyParts[1].replace(/_/g, ' ');
      if (lower.includes(crop) && lower.includes(disease)) return key;
    }
  }

  // Pass 2: disease keyword match only (no crop — lower confidence)
  for (const key of fragments) {
    const keyParts = key.split('___');
    if (keyParts.length === 2) {
      const disease = keyParts[1].replace(/_/g, ' ');
      if (disease !== 'healthy' && lower.includes(disease.split(' ')[0])) return key;
    }
  }

  // Healthy fallback — try to find crop-specific healthy entry
  if (lower.includes('healthy') || lower.includes('normal')) {
    for (const key of fragments) {
      if (!key.includes('healthy')) continue;
      const crop = key.split('___')[0].replace(/_/g, ' ').replace(/[()]/g, '');
      if (lower.includes(crop)) return key;
    }
    return 'apple___healthy';
  }

  return 'default';
};

const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

/**
 * Try each HF model in HF_MODELS until one succeeds.
 * Returns [{label, score}] or throws if all fail.
 */
const queryHuggingFace = async (imageBuffer) => {
  const apiKey = process.env.HUGGINGFACE_API_KEY;
  if (!apiKey || apiKey.trim() === '') {
    throw new Error('No HF key configured');
  }

  let lastError;
  for (const model of HF_MODELS) {
    const url = `https://router.huggingface.co/hf-inference/models/${model}`;
    for (let attempt = 1; attempt <= MAX_RETRIES; attempt++) {
      try {
        logger.info('Trying HuggingFace model', { model, attempt });
        const response = await axios.post(url, imageBuffer, {
          headers: {
            'Content-Type': 'application/octet-stream',
            'Authorization': `Bearer ${apiKey}`,
          },
          timeout: 30000,
          responseType: 'json',
        });

        const data = response.data;
        if (Array.isArray(data) && data.length > 0) {
          logger.info('HuggingFace model succeeded', { model });
          return data;
        }

        // Model still loading
        if (data.error && data.estimated_time) {
          logger.warn('HuggingFace model loading', { model, attempt, estimatedTime: data.estimated_time });
          await sleep(RETRY_DELAY_MS * attempt);
          continue;
        }

        throw new Error(data.error || 'Unexpected HuggingFace response');
      } catch (error) {
        lastError = error;
        const status = error.response?.status;
        if (status === 503 && attempt < MAX_RETRIES) {
          await sleep(RETRY_DELAY_MS * attempt);
          continue;
        }
        // 404/410 = model gone, skip to next model immediately
        if (status === 404 || status === 410) {
          logger.warn('HuggingFace model unavailable, skipping', { model, status });
          break;
        }
        // Other error — try next attempt, then next model
        if (attempt === MAX_RETRIES) break;
        await sleep(RETRY_DELAY_MS * attempt);
      }
    }
  }

  throw lastError || new Error('All HuggingFace models failed');
};

/**
 * Use Bedrock (Claude/Gemma) to analyse the image and identify the plant disease.
 * Sends the image as base64 to Claude 3 Haiku (multimodal) if available,
 * otherwise uses a text-only prompt with image size/hash metadata as a fallback.
 * Returns a normalised {label, score} array compatible with the HF path.
 */
const classifyViaBedrockVision = async (imageBuffer) => {
  const accessKey = process.env.AWS_ACCESS_KEY_ID;
  const secretKey = process.env.AWS_SECRET_ACCESS_KEY;
  if (!accessKey || !secretKey) throw new Error('AWS credentials not set');

  const modelId = process.env.BEDROCK_MODEL_ID || 'amazon.titan-text-express-v1';

  const client = new BedrockRuntimeClient({
    region: process.env.AWS_REGION || 'us-east-1',
    credentials: { accessKeyId: accessKey, secretAccessKey: secretKey },
  });

  let body;
  const isMultimodal = modelId.includes('anthropic') || modelId.includes('claude');

  // Non-multimodal models CANNOT see the image — reject early rather than guess
  if (!isMultimodal) {
    throw new Error('Bedrock model is text-only and cannot analyze images. Configure a Claude model via BEDROCK_MODEL_ID or set HUGGINGFACE_API_KEY.');
  }

  if (isMultimodal) {
    // Claude supports multimodal — send image + text
    const base64Image = imageBuffer.toString('base64');
    body = JSON.stringify({
      anthropic_version: 'bedrock-2023-05-31',
      max_tokens: 300,
      messages: [{
        role: 'user',
        content: [
          {
            type: 'image',
            source: { type: 'base64', media_type: 'image/jpeg', data: base64Image },
          },
          {
            type: 'text',
            text: `You are a plant disease expert. Examine this crop image carefully and identify the most likely disease or condition.

Respond with ONLY a JSON object in this exact format (no other text):
{"disease": "<disease_name_matching_PlantVillage_dataset>", "crop": "<crop_type>", "confidence": <0.0-1.0>, "healthy": <true|false>}

Use PlantVillage dataset label format for disease names, e.g.:
- Tomato___Early_blight
- Tomato___Late_blight
- Potato___Early_blight
- Corn_(maize)___Common_rust
- Tomato___healthy
- Apple___Apple_scab

If you cannot determine the disease clearly, set confidence below 0.6.`,
          },
        ],
      }],
    });
  }

  logger.info('Classifying disease via Bedrock', { modelId });

  const response = await client.send(new InvokeModelCommand({
    modelId,
    contentType: 'application/json',
    accept: 'application/json',
    body,
  }));

  const respBody = JSON.parse(new TextDecoder().decode(response.body));
  const text =
    respBody?.outputs?.[0]?.text?.trim() ||
    respBody?.content?.[0]?.text?.trim() ||
    respBody?.choices?.[0]?.message?.content?.trim() ||
    respBody?.results?.[0]?.outputText?.trim() ||
    respBody?.generation?.trim() || '';

  logger.info('Bedrock disease response', { text: text.slice(0, 200) });

  const jsonMatch = text.match(/\{[\s\S]*?\}/);
  if (jsonMatch) {
    const parsed = JSON.parse(jsonMatch[0]);
    const label = parsed.disease || (parsed.healthy ? 'Tomato___healthy' : 'Unknown');
    const score = Math.min(1, Math.max(0, parseFloat(parsed.confidence) || 0.65));
    return [{ label, score }];
  }

  throw new Error('Could not parse disease classification from Bedrock');
};

/**
 * Classify disease from an image buffer.
 * Strategy: HuggingFace router (if HUGGINGFACE_API_KEY set) → Bedrock vision → error.
 *
 * @param {Buffer} imageBuffer
 * @returns {Promise<{diseaseName, diseaseNameHindi, confidence, severity, cropType, treatments, treatmentsHindi, rawLabel, lowConfidence}>}
 */
const classifyDisease = async (imageBuffer) => {
  let predictions;

  let source = 'none';

  // Path 1: HuggingFace (needs HUGGINGFACE_API_KEY — tries models in order)
  const hfKey = process.env.HUGGINGFACE_API_KEY;
  if (hfKey && hfKey.trim() !== '') {
    try {
      predictions = await queryHuggingFace(imageBuffer);
      source = 'huggingface';
      logger.info('HuggingFace classification success');
    } catch (hfErr) {
      logger.warn('HuggingFace failed, falling back to Bedrock', { error: hfErr.message });
    }
  } else {
    logger.warn('HUGGINGFACE_API_KEY not set, skipping HuggingFace');
  }

  // Path 2: Bedrock vision (Claude multimodal only — text models cannot analyze images)
  if (!predictions) {
    try {
      logger.info('Classifying via Bedrock vision');
      predictions = await classifyViaBedrockVision(imageBuffer);
      source = 'bedrock';
      logger.info('Bedrock vision classification success');
    } catch (bedrockErr) {
      logger.error('Bedrock vision failed', { error: bedrockErr.message });
      throw new Error('Disease classification unavailable. Please ensure HUGGINGFACE_API_KEY is set or BEDROCK_MODEL_ID points to a Claude model.');
    }
  }

  if (!predictions || predictions.length === 0) {
    throw new Error('No predictions returned from disease model');
  }

  const top = predictions[0];
  const rawLabel = top.label || '';
  const confidence = top.score || 0;

  logger.info('Disease classification result', { source, label: rawLabel, confidence: confidence.toFixed(2) });

  const dbKey = mapLabelToKey(rawLabel);
  logger.info('Label mapped to DB key', { rawLabel, dbKey });
  const entry = TREATMENT_DB[dbKey] || TREATMENT_DB['default'];
  const lowConfidence = confidence < 0.6;

  // Use the matched DB key for the display name so it stays consistent
  // with the Hindi name and treatments (the raw HF label may be a different crop).
  const diseaseName = dbKey !== 'default'
    ? dbKey.replace(/___/g, ' - ').replace(/_/g, ' ')
    : rawLabel.replace(/___/g, ' - ').replace(/_/g, ' ');

  return {
    diseaseName,
    diseaseNameHindi: entry.nameHindi,
    confidence,
    severity: entry.severity,
    cropType: entry.cropType,
    treatments: entry.en,
    treatmentsHindi: entry.hi,
    rawLabel,
    lowConfidence,
  };
};

module.exports = { classifyDisease };
