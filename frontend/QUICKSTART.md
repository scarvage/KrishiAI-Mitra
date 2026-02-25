# KrishiMitra - Quick Start Guide

## Setup & Run

### Prerequisites
- Flutter SDK (>=3.10.8)
- Android device or emulator (API 21+)
- Git

### Build & Run

```bash
# Navigate to project
cd /Users/nidhigond/AndroidStudioProjects/krishiMitra

# Get dependencies
flutter pub get

# Run on device/emulator
flutter run

# Or build for release
flutter build apk --release
```

## App Demo Flow

### 1. Home Screen (Dashboard)
- See 3 large feature cards: Voice AI, Disease Check, Market Prices
- Quick stats: 4 crops, wheat price, weather
- Tap any card to jump to that feature

### 2. Voice AI Demo (Tap "Voice AI" Card)
- **Step 1**: See welcome message from AI
- **Step 2**: Tap the big green mic button
- **Step 3**: Button turns red for 2 seconds (listening animation)
- **Step 4**: See user message appear: "गेहूं की बीमारी का इलाज?"
- **Step 5**: Three animated dots (AI thinking)
- **Step 6**: AI response appears: "Wheat requires well-drained loamy soil..."
- **Toggle**: Use हिंदी/English chip to switch language

### 3. Disease Detection Demo (Tap "Disease Check" Card)
- **Step 1**: See camera and gallery buttons
- **Step 2**: Tap "Camera से Photo लें" (demo auto-selects)
- **Step 3**: Image loads with spinner: "AI विश्लेषण कर रहा है..."
- **Step 4**: After 2 seconds, disease result appears:
  - 🍅 Late Blight (94% confidence)
  - Treatment steps in Hindi/English
- **Step 5**: Tap "फिर से स्कैन करें" to cycle to next disease:
  - 🌾 Powdery Mildew (88% confidence)
  - ✅ Healthy Crop (97% confidence)
- **Toggle**: Use हिंदी/English to switch treatment language

### 4. Market Prices Demo (Tap "Market Prices" Card)
- **Step 1**: See loading spinner while data loads
- **Step 2**: Price cards appear with:
  - **SELL** badge (green): Soybean at ₹4,650 (1% above MSP)
  - **HOLD** badge (blue): Wheat at ₹2,180 (4% below MSP)
  - **WAIT** badge (amber): Onion at ₹1,820 (volatile)
  - **HOLD** badge (blue): Cotton at ₹6,200 (6% below MSP)
- **Step 3**: Each card shows 7-day trend bar chart
- **Step 4**: AI recommendation text explains why SELL/HOLD/WAIT
- **Filter**: Use filter chips (गेहूं, सोयाबीन, आदि) to filter commodities
- **Toggle**: Use हिंदी/English to switch recommendation text

## Bottom Navigation
- **होम** (Home): Dashboard with 3 feature cards
- **आवाज़ AI** (Voice AI): Chat interface
- **रोग** (Disease): Disease detection
- **मंडी** (Market): Prices

All tabs are fully functional and preserve state when switching.

## Design Principles Demonstrated

✅ **Voice-First**: No typing required for primary interaction
✅ **Low-Literacy**: Large fonts (min 16px), icons + text always together
✅ **Color-Coded**: SELL (green), HOLD (blue), WAIT (amber) - no need to read
✅ **Bilingual**: Hindi/English stacked everywhere
✅ **Fast**: All responses within 2 seconds (even slower connections)
✅ **Responsive**: Works on 4" to 6.5" screens
✅ **Offline-Ready**: Uses SharedPreferences for caching (30min for prices)

## Key Features

### Mock Services (Production-Ready)
- **AIService**: Amazon Bedrock-style keyword matching + response
- **DiseaseService**: Google Cloud Vision-style image analysis
- **MandiService**: AGMARKNET API-style price data with caching

### State Management
- **Provider Pattern**: 3 ChangeNotifier providers
- **Consumer Widgets**: Reactive UI updates
- **Persistent State**: IndexedStack keeps pages alive during tab switches

### Responsive Layout
- **Flexible widgets**: Adapt to screen size
- **Readable text**: No text overflow
- **Touch targets**: 48px+ minimum for buttons
- **Scrollable content**: No clipping on small screens

## Troubleshooting

### App won't build?
```bash
flutter clean
flutter pub get
flutter run
```

### Mock disease doesn't change?
The disease detection cycles through 3 results: Late Blight → Powdery Mildew → Healthy. Tap "फिर से स्कैन करें" 3 times to see all results.

### Price data not loading?
Check SharedPreferences cache - if prices were cached < 30 minutes ago, they return instantly. For fresh data, uninstall and reinstall the app.

### Mic button not animating?
Tap the green mic button - it will turn red and show "सुन रहा हूँ..." for 2 seconds, then send the demo message.

## Code Structure

```
lib/
├── main.dart                    # App root with MultiProvider
├── models/                      # Data classes (ChatMessage, DiseaseResult, MandiPrice)
├── services/                    # Mock services (AIService, DiseaseService, MandiService)
├── providers/                   # State management (VoiceProvider, DiseaseProvider, MandiProvider)
├── screens/                     # 4 full screens (Dashboard, Voice, Disease, Mandi)
├── widgets/                     # Reusable components (FeatureCard, ChatBubble, etc)
└── utils/                       # Colors, mock data, helpers
```

## Production Deployment

To integrate with real AWS/Google APIs:

1. **Voice AI**: Replace `AIService.getResponse()` with AWS Bedrock SDK calls
2. **Disease**: Replace `DiseaseService.analyzeImage()` with Google Cloud Vision API
3. **Market Prices**: Replace `MandiService.getPrices()` with AGMARKNET API endpoint
4. **Voice I/O**: Add `speech_to_text` and `tts` packages for real voice input/output

All service methods are designed as async-ready drop-in replacements.

## Contact
**Team Lead**: Nidhi Gond
**GitHub**: https://github.com/Nidhi174/krishiMitra

Good luck with the hackathon! 🚀
