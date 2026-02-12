# Design Document: KrishiAI Mitra

## Overview

KrishiAI Mitra is a serverless, AI-powered mobile agriculture assistant built using Flutter for cross-platform mobile development and Node.js on AWS Lambda for backend processing. The system integrates multiple AI services (Amazon Bedrock, Google Cloud Vision, Hugging Face) to provide three core capabilities: multilingual voice assistance, crop disease detection, and real-time market price intelligence.

The architecture is designed to maximize free tier usage across all cloud services while maintaining performance and reliability. The system employs aggressive caching strategies, request throttling, and graceful degradation to ensure zero-cost operation during the hackathon demonstration period.

### Design Principles

1. **Serverless-First**: Leverage AWS Lambda for automatic scaling and pay-per-use pricing
2. **Free Tier Optimization**: Implement caching and throttling to stay within all service limits
3. **Offline-Capable**: Cache critical data locally for rural connectivity scenarios
4. **Voice-First UX**: Prioritize voice interactions for low-literacy users
5. **Fail-Safe**: Graceful degradation when services are unavailable or rate-limited
6. **Modular Architecture**: Clear separation between frontend, API layer, business logic, and AI services

## System Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        Flutter Mobile App                        │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │   Voice      │  │   Disease    │  │    Price     │          │
│  │  Assistant   │  │   Detector   │  │   Checker    │          │
│  │   Screen     │  │    Screen    │  │    Screen    │          │
│  └──────────────┘  └──────────────┘  └──────────────┘          │
│         │                  │                  │                  │
│  ┌──────────────────────────────────────────────────┐          │
│  │         State Management (Provider)               │          │
│  └──────────────────────────────────────────────────┘          │
│         │                  │                  │                  │
│  ┌──────────────────────────────────────────────────┐          │
│  │         API Service Layer (HTTP Client)           │          │
│  └──────────────────────────────────────────────────┘          │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ HTTPS/REST
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                      AWS API Gateway                             │
│                   (REST API Endpoints)                           │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                      AWS Lambda Functions                        │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │   Voice      │  │   Disease    │  │    Price     │          │
│  │   Handler    │  │   Handler    │  │   Handler    │          │
│  └──────────────┘  └──────────────┘  └──────────────┘          │
└─────────────────────────────────────────────────────────────────┘
         │                  │                  │
         ▼                  ▼                  ▼
┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│   Amazon     │  │   Google     │  │ Data.gov.in  │
│   Bedrock    │  │ Cloud Vision │  │     API      │
│  (Claude 3)  │  │     API      │  │              │
└──────────────┘  └──────────────┘  └──────────────┘
                         │
                         ▼
                  ┌──────────────┐
                  │  Hugging     │
                  │   Face API   │
                  └──────────────┘
         │                  │                  │
         ▼                  ▼                  ▼
┌─────────────────────────────────────────────────────────────────┐
│                      MongoDB Atlas                               │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │Conversations │  │  Diagnoses   │  │Price Queries │          │
│  │  Collection  │  │  Collection  │  │  Collection  │          │
│  └──────────────┘  └──────────────┘  └──────────────┘          │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                      Cloudinary Storage                          │
│                    (Crop Disease Images)                         │
└─────────────────────────────────────────────────────────────────┘
```

### Component Breakdown

#### 1. Frontend Layer (Flutter App)
- **Screens**: Voice Assistant, Disease Detector, Price Checker, Profile
- **State Management**: Provider pattern for reactive state updates
- **Local Storage**: SharedPreferences for caching and offline data
- **Media Handling**: Camera/gallery access, audio recording/playback
- **API Client**: HTTP service with retry logic and error handling

#### 2. API Layer (AWS API Gateway + Lambda)
- **API Gateway**: REST endpoints with CORS, authentication, throttling
- **Lambda Functions**: Serverless compute for each feature
- **Request Validation**: Input sanitization and schema validation
- **Response Formatting**: Consistent JSON response structure

#### 3. Business Logic Layer (Lambda Functions)
- **Voice Processing**: Speech-to-text, Bedrock integration, text-to-speech
- **Image Analysis**: Image validation, Vision API, HuggingFace classification
- **Price Intelligence**: Data.gov.in API integration, caching, recommendations
- **Caching Logic**: Redis-like in-memory caching within Lambda execution context

#### 4. AI/ML Layer (External Services)
- **Amazon Bedrock**: Claude 3 Haiku for conversational AI
- **Google Cloud Vision**: Image feature extraction and analysis
- **Hugging Face**: Pre-trained disease classification models
- **Data.gov.in**: Government mandi price data API

#### 5. Data Layer
- **MongoDB Atlas**: User profiles, conversation history, diagnoses, price queries
- **Cloudinary**: Image storage with automatic optimization
- **Local Storage**: Flutter SharedPreferences for offline caching

## Technology Stack Details

### Frontend (Flutter)

**Core Framework**:
- Flutter SDK: 3.16.0
- Dart: 3.2.0

**Key Dependencies** (`pubspec.yaml`):
```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # State Management
  provider: ^6.1.0
  
  # HTTP & API
  http: ^1.1.0
  dio: ^5.4.0  # Alternative with interceptors
  
  # Voice Features
  speech_to_text: ^6.3.0
  flutter_tts: ^3.8.0
  permission_handler: ^11.0.1
  
  # Image Handling
  image_picker: ^1.0.4
  image: ^4.1.3  # Image compression
  
  # Local Storage
  shared_preferences: ^2.2.2
  hive: ^2.2.3  # For complex offline data
  hive_flutter: ^1.1.0
  
  # UI Components
  cached_network_image: ^3.3.0
  shimmer: ^3.0.0
  flutter_spinkit: ^5.2.0
  
  # Utilities
  intl: ^0.18.1  # Internationalization
  connectivity_plus: ^5.0.2  # Network status
  path_provider: ^2.1.1
```

### Backend (Node.js on AWS Lambda)

**Runtime**: Node.js 18.x

**Core Dependencies** (`package.json`):
```json
{
  "dependencies": {
    "@aws-sdk/client-bedrock-runtime": "^3.450.0",
    "@google-cloud/vision": "^4.0.0",
    "axios": "^1.6.0",
    "mongoose": "^8.0.0",
    "dotenv": "^16.3.0",
    "express": "^4.18.2",
    "serverless-http": "^3.2.0",
    "joi": "^17.11.0",
    "bcryptjs": "^2.4.3",
    "jsonwebtoken": "^9.0.2",
    "cloudinary": "^1.41.0",
    "node-cache": "^5.1.2"
  },
  "devDependencies": {
    "serverless": "^3.38.0",
    "serverless-offline": "^13.3.0"
  }
}
```

### Infrastructure

**AWS Services**:
- Lambda: Node.js 18.x runtime, 512MB memory, 30s timeout
- API Gateway: REST API with regional endpoint
- CloudWatch: Logs and metrics
- IAM: Roles and policies for Lambda execution

**Deployment Tool**:
- Serverless Framework 3.38.0

**Configuration** (`serverless.yml`):
```yaml
service: krishiai-mitra-api

provider:
  name: aws
  runtime: nodejs18.x
  region: ap-south-1  # Mumbai region for India
  memorySize: 512
  timeout: 30
  environment:
    MONGODB_URI: ${env:MONGODB_URI}
    BEDROCK_MODEL_ID: anthropic.claude-3-haiku-20240307-v1:0
    GOOGLE_VISION_KEY: ${env:GOOGLE_VISION_KEY}
    HUGGINGFACE_API_KEY: ${env:HUGGINGFACE_API_KEY}
    CLOUDINARY_URL: ${env:CLOUDINARY_URL}
    JWT_SECRET: ${env:JWT_SECRET}

functions:
  voiceQuery:
    handler: src/handlers/voice.handler
    events:
      - http:
          path: /api/voice/query
          method: post
          cors: true
  
  diseaseDetect:
    handler: src/handlers/disease.handler
    events:
      - http:
          path: /api/disease/detect
          method: post
          cors: true
  
  priceCheck:
    handler: src/handlers/price.handler
    events:
      - http:
          path: /api/price/mandi
          method: get
          cors: true
```

## Folder Structure

### Flutter App Structure

```
krishiai_mitra/
├── lib/
│   ├── main.dart                    # App entry point
│   ├── config/
│   │   ├── app_config.dart          # Environment configuration
│   │   ├── theme.dart               # App theme and colors
│   │   └── constants.dart           # API URLs, constants
│   ├── models/
│   │   ├── user.dart                # User profile model
│   │   ├── conversation.dart        # Voice conversation model
│   │   ├── diagnosis.dart           # Disease diagnosis model
│   │   ├── price_data.dart          # Mandi price model
│   │   └── api_response.dart        # Generic API response wrapper
│   ├── providers/
│   │   ├── auth_provider.dart       # Authentication state
│   │   ├── voice_provider.dart      # Voice assistant state
│   │   ├── disease_provider.dart    # Disease detection state
│   │   ├── price_provider.dart      # Price checker state
│   │   └── connectivity_provider.dart # Network status
│   ├── screens/
│   │   ├── splash_screen.dart       # App splash screen
│   │   ├── auth/
│   │   │   ├── login_screen.dart
│   │   │   └── register_screen.dart
│   │   ├── home/
│   │   │   └── home_screen.dart     # Main dashboard
│   │   ├── voice/
│   │   │   └── voice_assistant_screen.dart
│   │   ├── disease/
│   │   │   ├── disease_detector_screen.dart
│   │   │   └── diagnosis_detail_screen.dart
│   │   ├── price/
│   │   │   └── price_checker_screen.dart
│   │   └── profile/
│   │       └── profile_screen.dart
│   ├── widgets/
│   │   ├── common/
│   │   │   ├── custom_button.dart
│   │   │   ├── loading_indicator.dart
│   │   │   └── error_widget.dart
│   │   ├── voice/
│   │   │   ├── voice_input_button.dart
│   │   │   └── conversation_bubble.dart
│   │   ├── disease/
│   │   │   ├── image_picker_widget.dart
│   │   │   └── diagnosis_card.dart
│   │   └── price/
│   │       └── price_card.dart
│   ├── services/
│   │   ├── api_service.dart         # HTTP client wrapper
│   │   ├── auth_service.dart        # Authentication API calls
│   │   ├── voice_service.dart       # Voice API calls
│   │   ├── disease_service.dart     # Disease API calls
│   │   ├── price_service.dart       # Price API calls
│   │   ├── storage_service.dart     # Local storage wrapper
│   │   └── speech_service.dart      # Speech-to-text/TTS wrapper
│   └── utils/
│       ├── validators.dart          # Input validation
│       ├── image_utils.dart         # Image compression
│       ├── date_utils.dart          # Date formatting
│       └── logger.dart              # Logging utility
├── assets/
│   ├── images/
│   ├── icons/
│   └── translations/
│       ├── en.json
│       └── hi.json
├── test/
│   ├── unit/
│   ├── widget/
│   └── integration/
├── pubspec.yaml
└── README.md
```

### Backend Structure

```
krishiai-mitra-api/
├── src/
│   ├── handlers/
│   │   ├── voice.js              # Voice query Lambda handler
│   │   ├── disease.js            # Disease detection Lambda handler
│   │   ├── price.js              # Price check Lambda handler
│   │   └── auth.js               # Authentication Lambda handler
│   ├── controllers/
│   │   ├── voiceController.js    # Voice business logic
│   │   ├── diseaseController.js  # Disease detection logic
│   │   ├── priceController.js    # Price checking logic
│   │   └── authController.js     # Auth logic
│   ├── services/
│   │   ├── bedrockService.js     # Amazon Bedrock integration
│   │   ├── visionService.js      # Google Vision API integration
│   │   ├── huggingfaceService.js # HuggingFace API integration
│   │   ├── mandiService.js       # Data.gov.in API integration
│   │   ├── cloudinaryService.js  # Cloudinary integration
│   │   └── cacheService.js       # In-memory caching
│   ├── models/
│   │   ├── User.js               # User Mongoose model
│   │   ├── Conversation.js       # Conversation Mongoose model
│   │   ├── Diagnosis.js          # Diagnosis Mongoose model
│   │   └── PriceQuery.js         # Price query Mongoose model
│   ├── middleware/
│   │   ├── auth.js               # JWT authentication
│   │   ├── errorHandler.js       # Global error handler
│   │   ├── validator.js          # Request validation
│   │   └── rateLimiter.js        # Rate limiting
│   ├── utils/
│   │   ├── logger.js             # Winston logger
│   │   ├── response.js           # Response formatter
│   │   ├── errors.js             # Custom error classes
│   │   └── constants.js          # Constants and enums
│   └── config/
│       ├── database.js           # MongoDB connection
│       ├── aws.js                # AWS SDK configuration
│       └── env.js                # Environment variables
├── tests/
│   ├── unit/
│   └── integration/
├── serverless.yml                # Serverless Framework config
├── package.json
├── .env.example
└── README.md
```

## Component Design

### Feature 1: Voice Assistant

#### Flutter Implementation

**Voice Assistant Screen** (`lib/screens/voice/voice_assistant_screen.dart`):
```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';

class VoiceAssistantScreen extends StatefulWidget {
  @override
  _VoiceAssistantScreenState createState() => _VoiceAssistantScreenState();
}

class _VoiceAssistantScreenState extends State<VoiceAssistantScreen> {
  final SpeechToText _speech = SpeechToText();
  final FlutterTts _tts = FlutterTts();
  bool _isListening = false;
  String _currentLanguage = 'hi-IN'; // Hindi by default

  @override
  void initState() {
    super.initState();
    _initializeSpeech();
    _initializeTts();
  }

  Future<void> _initializeSpeech() async {
    await _speech.initialize(
      onStatus: (status) => setState(() => _isListening = status == 'listening'),
      onError: (error) => _handleError(error),
    );
  }

  Future<void> _initializeTts() async {
    await _tts.setLanguage(_currentLanguage == 'hi-IN' ? 'hi-IN' : 'en-US');
    await _tts.setSpeechRate(0.5);
  }

  Future<void> _startListening() async {
    if (!_isListening) {
      await _speech.listen(
        onResult: (result) => _handleSpeechResult(result.recognizedWords),
        localeId: _currentLanguage,
      );
    }
  }

  Future<void> _handleSpeechResult(String text) async {
    final provider = Provider.of<VoiceProvider>(context, listen: false);
    
    // Send query to backend
    await provider.sendVoiceQuery(text, _currentLanguage);
    
    // Speak the response
    if (provider.lastResponse != null) {
      await _tts.speak(provider.lastResponse!.answer);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Voice Assistant')),
      body: Consumer<VoiceProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              // Language selector
              SegmentedButton(
                segments: [
                  ButtonSegment(value: 'hi-IN', label: Text('हिंदी')),
                  ButtonSegment(value: 'en-US', label: Text('English')),
                ],
                selected: {_currentLanguage},
                onSelectionChanged: (Set<String> selected) {
                  setState(() => _currentLanguage = selected.first);
                  _initializeTts();
                },
              ),
              
              // Conversation history
              Expanded(
                child: ListView.builder(
                  itemCount: provider.conversations.length,
                  itemBuilder: (context, index) {
                    final conv = provider.conversations[index];
                    return ConversationBubble(conversation: conv);
                  },
                ),
              ),
              
              // Voice input button
              VoiceInputButton(
                isListening: _isListening,
                onPressed: _startListening,
              ),
            ],
          );
        },
      ),
    );
  }
}
```

**Voice Provider** (`lib/providers/voice_provider.dart`):
```dart
import 'package:flutter/foundation.dart';
import '../models/conversation.dart';
import '../services/voice_service.dart';
import '../services/storage_service.dart';

class VoiceProvider with ChangeNotifier {
  final VoiceService _voiceService = VoiceService();
  final StorageService _storage = StorageService();
  
  List<Conversation> _conversations = [];
  Conversation? _lastResponse;
  bool _isLoading = false;
  String? _error;

  List<Conversation> get conversations => _conversations;
  Conversation? get lastResponse => _lastResponse;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadConversations() async {
    _conversations = await _storage.getCachedConversations();
    notifyListeners();
  }

  Future<void> sendVoiceQuery(String query, String language) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _voiceService.sendQuery(query, language);
      _lastResponse = response;
      _conversations.add(response);
      
      // Cache locally
      await _storage.cacheConversation(response);
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }
}
```

#### Backend Implementation

**Voice Handler** (`src/handlers/voice.js`):
```javascript
const serverless = require('serverless-http');
const express = require('express');
const voiceController = require('../controllers/voiceController');
const { authenticate } = require('../middleware/auth');
const { validateVoiceQuery } = require('../middleware/validator');

const app = express();
app.use(express.json());

app.post('/api/voice/query', 
  authenticate, 
  validateVoiceQuery, 
  voiceController.handleVoiceQuery
);

module.exports.handler = serverless(app);
```

**Voice Controller** (`src/controllers/voiceController.js`):
```javascript
const bedrockService = require('../services/bedrockService');
const cacheService = require('../services/cacheService');
const Conversation = require('../models/Conversation');
const { successResponse, errorResponse } = require('../utils/response');
const logger = require('../utils/logger');

exports.handleVoiceQuery = async (req, res) => {
  try {
    const { query, language, userId } = req.body;
    
    // Check cache first (24-hour TTL)
    const cacheKey = `voice:${language}:${query.toLowerCase()}`;
    const cachedResponse = cacheService.get(cacheKey);
    
    if (cachedResponse) {
      logger.info('Returning cached voice response', { cacheKey });
      return successResponse(res, cachedResponse);
    }
    
    // Call Bedrock for AI response
    const aiResponse = await bedrockService.generateResponse(query, language);
    
    // Save to database
    const conversation = await Conversation.create({
      userId,
      query,
      response: aiResponse.answer,
      language,
      tokensUsed: aiResponse.tokensUsed,
      timestamp: new Date()
    });
    
    // Cache the response
    cacheService.set(cacheKey, {
      conversationId: conversation._id,
      query,
      answer: aiResponse.answer,
      language,
      cached: false
    }, 86400); // 24 hours
    
    return successResponse(res, {
      conversationId: conversation._id,
      query,
      answer: aiResponse.answer,
      language,
      cached: false
    });
    
  } catch (error) {
    logger.error('Voice query error', { error: error.message });
    return errorResponse(res, error.message, 500);
  }
};
```

**Bedrock Service** (`src/services/bedrockService.js`):
```javascript
const { BedrockRuntimeClient, InvokeModelCommand } = require('@aws-sdk/client-bedrock-runtime');
const logger = require('../utils/logger');

const client = new BedrockRuntimeClient({ region: 'us-east-1' });

const SYSTEM_PROMPTS = {
  'hi-IN': 'आप एक कृषि विशेषज्ञ हैं जो भारतीय किसानों की मदद करते हैं। सरल हिंदी में जवाब दें।',
  'en-US': 'You are an agricultural expert helping Indian farmers. Provide practical, actionable advice.'
};

exports.generateResponse = async (query, language) => {
  try {
    const systemPrompt = SYSTEM_PROMPTS[language] || SYSTEM_PROMPTS['en-US'];
    
    const payload = {
      anthropic_version: 'bedrock-2023-05-31',
      max_tokens: 500,
      system: systemPrompt,
      messages: [
        {
          role: 'user',
          content: query
        }
      ]
    };
    
    const command = new InvokeModelCommand({
      modelId: 'anthropic.claude-3-haiku-20240307-v1:0',
      contentType: 'application/json',
      accept: 'application/json',
      body: JSON.stringify(payload)
    });
    
    const response = await client.send(command);
    const responseBody = JSON.parse(new TextDecoder().decode(response.body));
    
    logger.info('Bedrock response received', { 
      tokensUsed: responseBody.usage.output_tokens 
    });
    
    return {
      answer: responseBody.content[0].text,
      tokensUsed: responseBody.usage.output_tokens
    };
    
  } catch (error) {
    logger.error('Bedrock service error', { error: error.message });
    throw new Error('Failed to generate AI response');
  }
};
```

### Feature 2: Disease Detection

#### Flutter Implementation

**Disease Detector Screen** (`lib/screens/disease/disease_detector_screen.dart`):
```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class DiseaseDetectorScreen extends StatefulWidget {
  @override
  _DiseaseDetectorScreenState createState() => _DiseaseDetectorScreenState();
}

class _DiseaseDetectorScreenState extends State<DiseaseDetectorScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    
    if (image != null) {
      setState(() => _selectedImage = File(image.path));
      _analyzeImage();
    }
  }

  Future<void> _analyzeImage() async {
    if (_selectedImage == null) return;
    
    final provider = Provider.of<DiseaseProvider>(context, listen: false);
    await provider.detectDisease(_selectedImage!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Disease Detection')),
      body: Consumer<DiseaseProvider>(
        builder: (context, provider, child) {
          return SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                // Image preview
                if (_selectedImage != null)
                  Container(
                    height: 300,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(
                        image: FileImage(_selectedImage!),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                
                SizedBox(height: 20),
                
                // Image picker buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _pickImage(ImageSource.camera),
                      icon: Icon(Icons.camera_alt),
                      label: Text('Camera'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _pickImage(ImageSource.gallery),
                      icon: Icon(Icons.photo_library),
                      label: Text('Gallery'),
                    ),
                  ],
                ),
                
                SizedBox(height: 20),
                
                // Loading indicator
                if (provider.isLoading)
                  CircularProgressIndicator(),
                
                // Diagnosis result
                if (provider.lastDiagnosis != null)
                  DiagnosisCard(diagnosis: provider.lastDiagnosis!),
                
                // Error message
                if (provider.error != null)
                  ErrorWidget(message: provider.error!),
              ],
            ),
          );
        },
      ),
    );
  }
}
```

**Disease Provider** (`lib/providers/disease_provider.dart`):
```dart
import 'package:flutter/foundation.dart';
import 'dart:io';
import '../models/diagnosis.dart';
import '../services/disease_service.dart';
import '../services/storage_service.dart';

class DiseaseProvider with ChangeNotifier {
  final DiseaseService _diseaseService = DiseaseService();
  final StorageService _storage = StorageService();
  
  List<Diagnosis> _diagnoses = [];
  Diagnosis? _lastDiagnosis;
  bool _isLoading = false;
  String? _error;

  List<Diagnosis> get diagnoses => _diagnoses;
  Diagnosis? get lastDiagnosis => _lastDiagnosis;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> detectDisease(File imageFile) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final diagnosis = await _diseaseService.detectDisease(imageFile);
      _lastDiagnosis = diagnosis;
      _diagnoses.insert(0, diagnosis);
      
      // Cache locally (keep last 10)
      await _storage.cacheDiagnosis(diagnosis);
      if (_diagnoses.length > 10) {
        _diagnoses.removeLast();
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }
}
```

#### Backend Implementation

**Disease Handler** (`src/handlers/disease.js`):
```javascript
const serverless = require('serverless-http');
const express = require('express');
const multer = require('multer');
const diseaseController = require('../controllers/diseaseController');
const { authenticate } = require('../middleware/auth');

const app = express();
const upload = multer({ 
  limits: { fileSize: 5 * 1024 * 1024 }, // 5MB limit
  fileFilter: (req, file, cb) => {
    if (file.mimetype.startsWith('image/')) {
      cb(null, true);
    } else {
      cb(new Error('Only image files allowed'));
    }
  }
});

app.post('/api/disease/detect', 
  authenticate, 
  upload.single('image'),
  diseaseController.detectDisease
);

module.exports.handler = serverless(app);
```

**Disease Controller** (`src/controllers/diseaseController.js`):
```javascript
const visionService = require('../services/visionService');
const huggingfaceService = require('../services/huggingfaceService');
const cloudinaryService = require('../services/cloudinaryService');
const cacheService = require('../services/cacheService');
const Diagnosis = require('../models/Diagnosis');
const { successResponse, errorResponse } = require('../utils/response');
const logger = require('../utils/logger');
const crypto = require('crypto');

exports.detectDisease = async (req, res) => {
  try {
    const { userId } = req.body;
    const imageFile = req.file;
    
    if (!imageFile) {
      return errorResponse(res, 'No image file provided', 400);
    }
    
    // Generate image hash for caching
    const imageHash = crypto
      .createHash('md5')
      .update(imageFile.buffer)
      .digest('hex');
    
    const cacheKey = `disease:${imageHash}`;
    const cachedResult = cacheService.get(cacheKey);
    
    if (cachedResult) {
      logger.info('Returning cached disease detection', { imageHash });
      return successResponse(res, { ...cachedResult, cached: true });
    }
    
    // Upload to Cloudinary
    const uploadResult = await cloudinaryService.uploadImage(
      imageFile.buffer,
      `diseases/${userId}/${Date.now()}`
    );
    
    // Analyze with Google Vision API
    const visionAnalysis = await visionService.analyzeImage(imageFile.buffer);
    
    // Classify disease with HuggingFace
    const diseaseClassification = await huggingfaceService.classifyDisease(
      imageFile.buffer,
      visionAnalysis.labels
    );
    
    // Prepare response
    const result = {
      diseaseName: diseaseClassification.disease,
      confidence: diseaseClassification.confidence,
      treatments: diseaseClassification.treatments,
      imageUrl: uploadResult.secure_url,
      detectedLabels: visionAnalysis.labels,
      language: req.body.language || 'en-US'
    };
    
    // Save to database
    const diagnosis = await Diagnosis.create({
      userId,
      imageUrl: uploadResult.secure_url,
      imageHash,
      diseaseName: result.diseaseName,
      confidence: result.confidence,
      treatments: result.treatments,
      detectedLabels: result.detectedLabels,
      timestamp: new Date()
    });
    
    // Cache result (7 days)
    cacheService.set(cacheKey, {
      diagnosisId: diagnosis._id,
      ...result
    }, 604800);
    
    return successResponse(res, {
      diagnosisId: diagnosis._id,
      ...result,
      cached: false
    });
    
  } catch (error) {
    logger.error('Disease detection error', { error: error.message });
    return errorResponse(res, error.message, 500);
  }
};
```

**Vision Service** (`src/services/visionService.js`):
```javascript
const vision = require('@google-cloud/vision');
const logger = require('../utils/logger');

const client = new vision.ImageAnnotatorClient({
  keyFilename: process.env.GOOGLE_VISION_KEY_PATH
});

exports.analyzeImage = async (imageBuffer) => {
  try {
    const [result] = await client.labelDetection({
      image: { content: imageBuffer }
    });
    
    const labels = result.labelAnnotations.map(label => ({
      description: label.description,
      score: label.score
    }));
    
    logger.info('Vision API analysis complete', { labelCount: labels.length });
    
    return { labels };
    
  } catch (error) {
    logger.error('Vision API error', { error: error.message });
    throw new Error('Image analysis failed');
  }
};
```

**HuggingFace Service** (`src/services/huggingfaceService.js`):
```javascript
const axios = require('axios');
const logger = require('../utils/logger');

const DISEASE_MODEL = 'linkanjarad/mobilenet_v2_1.0_224-plant-disease-identification';
const HF_API_URL = `https://api-inference.huggingface.co/models/${DISEASE_MODEL}`;

const TREATMENT_DATABASE = {
  'early_blight': {
    en: ['Apply fungicide', 'Remove infected leaves', 'Improve air circulation'],
    hi: ['फफूंदनाशक लगाएं', 'संक्रमित पत्तियां हटाएं', 'हवा का संचार बढ़ाएं']
  },
  'late_blight': {
    en: ['Apply copper-based fungicide', 'Destroy infected plants', 'Avoid overhead watering'],
    hi: ['तांबा आधारित फफूंदनाशक लगाएं', 'संक्रमित पौधे नष्ट करें', 'ऊपर से पानी देने से बचें']
  }
  // Add more diseases...
};

exports.classifyDisease = async (imageBuffer, visionLabels) => {
  try {
    const response = await axios.post(
      HF_API_URL,
      imageBuffer,
      {
        headers: {
          'Authorization': `Bearer ${process.env.HUGGINGFACE_API_KEY}`,
          'Content-Type': 'application/octet-stream'
        }
      }
    );
    
    const predictions = response.data;
    const topPrediction = predictions[0];
    
    const diseaseKey = topPrediction.label.toLowerCase().replace(/ /g, '_');
    const treatments = TREATMENT_DATABASE[diseaseKey] || {
      en: ['Consult agricultural expert'],
      hi: ['कृषि विशेषज्ञ से परामर्श करें']
    };
    
    logger.info('Disease classified', { 
      disease: topPrediction.label,
      confidence: topPrediction.score 
    });
    
    return {
      disease: topPrediction.label,
      confidence: topPrediction.score,
      treatments
    };
    
  } catch (error) {
    logger.error('HuggingFace API error', { error: error.message });
    throw new Error('Disease classification failed');
  }
};
```

### Feature 3: Mandi Price Checker

#### Flutter Implementation

**Price Checker Screen** (`lib/screens/price/price_checker_screen.dart`):
```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PriceCheckerScreen extends StatefulWidget {
  @override
  _PriceCheckerScreenState createState() => _PriceCheckerScreenState();
}

class _PriceCheckerScreenState extends State<PriceCheckerScreen> {
  final TextEditingController _searchController = TextEditingController();
  
  final List<String> _commonCrops = [
    'Wheat', 'Rice', 'Cotton', 'Sugarcane', 'Tomato',
    'Potato', 'Onion', 'Maize', 'Soybean', 'Groundnut'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Mandi Prices')),
      body: Consumer<PriceProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              // Search bar
              Padding(
                padding: EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search crop...',
                    prefixIcon: Icon(Icons.search),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.clear),
                      onPressed: () => _searchController.clear(),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onSubmitted: (value) {
                    if (value.isNotEmpty) {
                      provider.fetchPrices(value);
                    }
                  },
                ),
              ),
              
              // Common crops chips
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 8,
                  children: _commonCrops.map((crop) {
                    return ActionChip(
                      label: Text(crop),
                      onPressed: () {
                        _searchController.text = crop;
                        provider.fetchPrices(crop);
                      },
                    );
                  }).toList(),
                ),
              ),
              
              SizedBox(height: 16),
              
              // Loading indicator
              if (provider.isLoading)
                CircularProgressIndicator(),
              
              // Price list
              if (provider.prices.isNotEmpty)
                Expanded(
                  child: ListView.builder(
                    itemCount: provider.prices.length,
                    itemBuilder: (context, index) {
                      final price = provider.prices[index];
                      return PriceCard(priceData: price);
                    },
                  ),
                ),
              
              // Recommendation banner
              if (provider.recommendation != null)
                Container(
                  padding: EdgeInsets.all(16),
                  color: _getRecommendationColor(provider.recommendation!),
                  child: Row(
                    children: [
                      Icon(Icons.lightbulb, color: Colors.white),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          provider.recommendation!,
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              
              // Error message
              if (provider.error != null)
                ErrorWidget(message: provider.error!),
            ],
          );
        },
      ),
    );
  }
  
  Color _getRecommendationColor(String recommendation) {
    if (recommendation.contains('Sell now')) return Colors.green;
    if (recommendation.contains('Hold')) return Colors.orange;
    return Colors.blue;
  }
}
```

#### Backend Implementation

**Price Handler** (`src/handlers/price.js`):
```javascript
const serverless = require('serverless-http');
const express = require('express');
const priceController = require('../controllers/priceController');
const { authenticate } = require('../middleware/auth');

const app = express();
app.use(express.json());

app.get('/api/price/mandi', 
  authenticate, 
  priceController.getMandiPrices
);

module.exports.handler = serverless(app);
```

**Price Controller** (`src/controllers/priceController.js`):
```javascript
const mandiService = require('../services/mandiService');
const cacheService = require('../services/cacheService');
const PriceQuery = require('../models/PriceQuery');
const { successResponse, errorResponse } = require('../utils/response');
const logger = require('../utils/logger');

exports.getMandiPrices = async (req, res) => {
  try {
    const { crop, state, userId } = req.query;
    
    if (!crop) {
      return errorResponse(res, 'Crop name is required', 400);
    }
    
    // Check cache (6-hour TTL)
    const cacheKey = `price:${crop.toLowerCase()}:${state || 'all'}`;
    const cachedPrices = cacheService.get(cacheKey);
    
    if (cachedPrices) {
      logger.info('Returning cached price data', { cacheKey });
      return successResponse(res, { ...cachedPrices, cached: true });
    }
    
    // Fetch from Data.gov.in API
    const priceData = await mandiService.fetchMandiPrices(crop, state);
    
    // Generate recommendation
    const recommendation = generateRecommendation(priceData.prices);
    
    const result = {
      crop,
      prices: priceData.prices,
      recommendation,
      lastUpdated: priceData.lastUpdated,
      cached: false
    };
    
    // Save to database
    await PriceQuery.create({
      userId,
      crop,
      state,
      pricesCount: priceData.prices.length,
      recommendation,
      timestamp: new Date()
    });
    
    // Cache result (6 hours)
    cacheService.set(cacheKey, result, 21600);
    
    return successResponse(res, result);
    
  } catch (error) {
    logger.error('Price query error', { error: error.message });
    return errorResponse(res, error.message, 500);
  }
};

function generateRecommendation(prices) {
  if (prices.length === 0) return 'No price data available';
  
  // Calculate average and trend
  const avgPrice = prices.reduce((sum, p) => sum + p.modal_price, 0) / prices.length;
  const recentPrices = prices.slice(0, 3);
  const recentAvg = recentPrices.reduce((sum, p) => sum + p.modal_price, 0) / recentPrices.length;
  
  const trend = ((recentAvg - avgPrice) / avgPrice) * 100;
  
  if (trend > 5) {
    return 'Prices trending up. Consider holding for better rates.';
  } else if (trend < -5) {
    return 'Prices declining. Sell now to avoid further drops.';
  } else {
    return 'Prices stable. Good time to sell at current rates.';
  }
}
```

**Mandi Service** (`src/services/mandiService.js`):
```javascript
const axios = require('axios');
const logger = require('../utils/logger');

const DATA_GOV_API = 'https://api.data.gov.in/resource/9ef84268-d588-465a-a308-a864a43d0070';
const API_KEY = process.env.DATA_GOV_API_KEY;

exports.fetchMandiPrices = async (crop, state = null) => {
  try {
    const params = {
      'api-key': API_KEY,
      format: 'json',
      limit: 10,
      filters: {
        commodity: crop
      }
    };
    
    if (state) {
      params.filters.state = state;
    }
    
    const response = await axios.get(DATA_GOV_API, {
      params,
      timeout: 5000
    });
    
    const records = response.data.records || [];
    
    const prices = records.map(record => ({
      mandi: record.market,
      state: record.state,
      district: record.district,
      modal_price: parseFloat(record.modal_price),
      min_price: parseFloat(record.min_price),
      max_price: parseFloat(record.max_price),
      arrival_date: record.arrival_date
    }));
    
    // Sort by date (most recent first)
    prices.sort((a, b) => new Date(b.arrival_date) - new Date(a.arrival_date));
    
    logger.info('Mandi prices fetched', { 
      crop, 
      count: prices.length 
    });
    
    return {
      prices,
      lastUpdated: prices[0]?.arrival_date || new Date().toISOString()
    };
    
  } catch (error) {
    logger.error('Mandi API error', { error: error.message });
    
    // Return empty result instead of throwing
    return {
      prices: [],
      lastUpdated: new Date().toISOString()
    };
  }
};
```

## Database Schema (MongoDB)

### Collection: users

```javascript
{
  _id: ObjectId,
  phoneNumber: String,        // Unique, indexed
  name: String,
  location: {
    state: String,
    district: String,
    pincode: String
  },
  primaryCrops: [String],     // e.g., ["Wheat", "Rice"]
  preferredLanguage: String,  // "hi-IN" or "en-US"
  passwordHash: String,
  createdAt: Date,
  lastLoginAt: Date
}
```

**Indexes**:
- `phoneNumber`: unique, ascending
- `createdAt`: descending

**Example Document**:
```json
{
  "_id": "507f1f77bcf86cd799439011",
  "phoneNumber": "+919876543210",
  "name": "Ramesh Kumar",
  "location": {
    "state": "Punjab",
    "district": "Ludhiana",
    "pincode": "141001"
  },
  "primaryCrops": ["Wheat", "Rice"],
  "preferredLanguage": "hi-IN",
  "passwordHash": "$2a$10$...",
  "createdAt": "2024-01-15T10:30:00Z",
  "lastLoginAt": "2024-01-20T14:22:00Z"
}
```

### Collection: conversations

```javascript
{
  _id: ObjectId,
  userId: ObjectId,           // Reference to users
  query: String,              // User's voice query
  response: String,           // AI-generated response
  language: String,           // "hi-IN" or "en-US"
  tokensUsed: Number,         // Bedrock tokens consumed
  timestamp: Date,
  cached: Boolean             // Whether served from cache
}
```

**Indexes**:
- `userId`: ascending
- `timestamp`: descending
- Compound: `(userId, timestamp)`

**Example Document**:
```json
{
  "_id": "507f1f77bcf86cd799439012",
  "userId": "507f1f77bcf86cd799439011",
  "query": "Mere gehun ki patti peeli kyu ho rahi hai?",
  "response": "गेहूं की पत्तियों का पीला होना नाइट्रोजन की कमी का संकेत हो सकता है...",
  "language": "hi-IN",
  "tokensUsed": 150,
  "timestamp": "2024-01-20T14:25:30Z",
  "cached": false
}
```

### Collection: diagnoses

```javascript
{
  _id: ObjectId,
  userId: ObjectId,           // Reference to users
  imageUrl: String,           // Cloudinary URL
  imageHash: String,          // MD5 hash for deduplication
  diseaseName: String,        // Detected disease
  confidence: Number,         // 0-1 confidence score
  treatments: {
    en: [String],
    hi: [String]
  },
  detectedLabels: [{
    description: String,
    score: Number
  }],
  timestamp: Date
}
```

**Indexes**:
- `userId`: ascending
- `imageHash`: ascending (for cache lookup)
- `timestamp`: descending
- Compound: `(userId, timestamp)`

**Example Document**:
```json
{
  "_id": "507f1f77bcf86cd799439013",
  "userId": "507f1f77bcf86cd799439011",
  "imageUrl": "https://res.cloudinary.com/krishiai/image/upload/v1234567890/diseases/user123/image.jpg",
  "imageHash": "5d41402abc4b2a76b9719d911017c592",
  "diseaseName": "Early Blight",
  "confidence": 0.92,
  "treatments": {
    "en": ["Apply fungicide", "Remove infected leaves", "Improve air circulation"],
    "hi": ["फफूंदनाशक लगाएं", "संक्रमित पत्तियां हटाएं", "हवा का संचार बढ़ाएं"]
  },
  "detectedLabels": [
    { "description": "Leaf", "score": 0.98 },
    { "description": "Plant disease", "score": 0.85 }
  ],
  "timestamp": "2024-01-20T15:10:00Z"
}
```

### Collection: price_queries

```javascript
{
  _id: ObjectId,
  userId: ObjectId,           // Reference to users
  crop: String,               // Crop name searched
  state: String,              // Optional state filter
  pricesCount: Number,        // Number of mandis returned
  recommendation: String,     // Sell/Hold/Wait recommendation
  timestamp: Date
}
```

**Indexes**:
- `userId`: ascending
- `crop`: ascending
- `timestamp`: descending
- Compound: `(userId, timestamp)`

**Example Document**:
```json
{
  "_id": "507f1f77bcf86cd799439014",
  "userId": "507f1f77bcf86cd799439011",
  "crop": "Wheat",
  "state": "Punjab",
  "pricesCount": 8,
  "recommendation": "Prices stable. Good time to sell at current rates.",
  "timestamp": "2024-01-20T16:00:00Z"
}
```

### Collection: usage_metrics

```javascript
{
  _id: ObjectId,
  date: Date,                 // Daily aggregation
  metrics: {
    totalUsers: Number,
    activeUsers: Number,
    voiceQueries: Number,
    diseaseDetections: Number,
    priceChecks: Number,
    bedrockTokens: Number,
    visionApiCalls: Number,
    huggingfaceCalls: Number,
    errorRate: Number
  }
}
```

**Indexes**:
- `date`: descending (unique)

**Example Document**:
```json
{
  "_id": "507f1f77bcf86cd799439015",
  "date": "2024-01-20T00:00:00Z",
  "metrics": {
    "totalUsers": 150,
    "activeUsers": 45,
    "voiceQueries": 120,
    "diseaseDetections": 35,
    "priceChecks": 80,
    "bedrockTokens": 18000,
    "visionApiCalls": 35,
    "huggingfaceCalls": 35,
    "errorRate": 0.02
  }
}
```

## API Specifications

### Base URLs

- **Production**: `https://api.krishiai.com`
- **Development**: `https://dev-api.krishiai.com`
- **Local**: `http://localhost:3000`

### Authentication

All API endpoints require JWT authentication via Bearer token in the Authorization header:

```
Authorization: Bearer <jwt_token>
```

### Common Response Format

**Success Response**:
```json
{
  "success": true,
  "data": { ... },
  "timestamp": "2024-01-20T14:30:00Z"
}
```

**Error Response**:
```json
{
  "success": false,
  "error": {
    "message": "Error description",
    "code": "ERROR_CODE"
  },
  "timestamp": "2024-01-20T14:30:00Z"
}
```

### Endpoint 1: Voice Query

**POST** `/api/voice/query`

Process a voice query and return AI-generated agricultural advice.

**Request Headers**:
```
Content-Type: application/json
Authorization: Bearer <token>
```

**Request Body**:
```json
{
  "query": "Mere gehun ki patti peeli kyu ho rahi hai?",
  "language": "hi-IN",
  "userId": "507f1f77bcf86cd799439011"
}
```

**Request Parameters**:
- `query` (string, required): The user's agricultural question
- `language` (string, required): Language code ("hi-IN" or "en-US")
- `userId` (string, required): User's MongoDB ObjectId

**Success Response** (200 OK):
```json
{
  "success": true,
  "data": {
    "conversationId": "507f1f77bcf86cd799439012",
    "query": "Mere gehun ki patti peeli kyu ho rahi hai?",
    "answer": "गेहूं की पत्तियों का पीला होना नाइट्रोजन की कमी का संकेत हो सकता है। आप यूरिया खाद का प्रयोग करें और मिट्टी की जांच करवाएं।",
    "language": "hi-IN",
    "cached": false
  },
  "timestamp": "2024-01-20T14:30:00Z"
}
```

**Error Responses**:
- `400 Bad Request`: Invalid request parameters
- `401 Unauthorized`: Missing or invalid authentication token
- `429 Too Many Requests`: Rate limit exceeded
- `500 Internal Server Error`: Server error or AI service unavailable

**Rate Limits**:
- 10 requests per minute per user
- 100 requests per day per user

---

### Endpoint 2: Disease Detection

**POST** `/api/disease/detect`

Upload a crop image and receive disease diagnosis with treatment recommendations.

**Request Headers**:
```
Content-Type: multipart/form-data
Authorization: Bearer <token>
```

**Request Body** (multipart/form-data):
```
image: <binary file data>
userId: "507f1f77bcf86cd799439011"
language: "hi-IN"
```

**Request Parameters**:
- `image` (file, required): Image file (JPEG/PNG/WebP, max 5MB)
- `userId` (string, required): User's MongoDB ObjectId
- `language` (string, optional): Language for treatments ("hi-IN" or "en-US", default: "en-US")

**Success Response** (200 OK):
```json
{
  "success": true,
  "data": {
    "diagnosisId": "507f1f77bcf86cd799439013",
    "diseaseName": "Early Blight",
    "confidence": 0.92,
    "treatments": {
      "en": [
        "Apply fungicide containing chlorothalonil",
        "Remove and destroy infected leaves",
        "Improve air circulation around plants",
        "Avoid overhead watering"
      ],
      "hi": [
        "क्लोरोथैलोनिल युक्त फफूंदनाशक लगाएं",
        "संक्रमित पत्तियां हटाएं और नष्ट करें",
        "पौधों के चारों ओर हवा का संचार बढ़ाएं",
        "ऊपर से पानी देने से बचें"
      ]
    },
    "imageUrl": "https://res.cloudinary.com/krishiai/image/upload/v1234567890/diseases/user123/image.jpg",
    "detectedLabels": [
      { "description": "Leaf", "score": 0.98 },
      { "description": "Plant disease", "score": 0.85 },
      { "description": "Tomato", "score": 0.82 }
    ],
    "language": "hi-IN",
    "cached": false
  },
  "timestamp": "2024-01-20T15:10:00Z"
}
```

**Low Confidence Response** (200 OK):
```json
{
  "success": true,
  "data": {
    "diagnosisId": "507f1f77bcf86cd799439013",
    "diseaseName": "Unknown",
    "confidence": 0.45,
    "message": "Low confidence detection. Please capture a clearer image or consult an agricultural expert.",
    "suggestions": [
      "Ensure good lighting",
      "Focus on affected area",
      "Avoid blurry images"
    ],
    "cached": false
  },
  "timestamp": "2024-01-20T15:10:00Z"
}
```

**Error Responses**:
- `400 Bad Request`: No image file or invalid file format
- `401 Unauthorized`: Missing or invalid authentication token
- `413 Payload Too Large`: Image exceeds 5MB limit
- `429 Too Many Requests`: Rate limit exceeded
- `500 Internal Server Error`: Server error or AI service unavailable

**Rate Limits**:
- 5 requests per minute per user
- 50 requests per day per user

---

### Endpoint 3: Mandi Price Check

**GET** `/api/price/mandi`

Retrieve current mandi prices for a specific crop with sell/hold recommendations.

**Request Headers**:
```
Authorization: Bearer <token>
```

**Query Parameters**:
- `crop` (string, required): Crop name (e.g., "Wheat", "Rice", "Cotton")
- `state` (string, optional): State name for filtering (e.g., "Punjab", "Maharashtra")
- `userId` (string, required): User's MongoDB ObjectId

**Example Request**:
```
GET /api/price/mandi?crop=Wheat&state=Punjab&userId=507f1f77bcf86cd799439011
```

**Success Response** (200 OK):
```json
{
  "success": true,
  "data": {
    "crop": "Wheat",
    "prices": [
      {
        "mandi": "Ludhiana",
        "state": "Punjab",
        "district": "Ludhiana",
        "modal_price": 2150,
        "min_price": 2100,
        "max_price": 2200,
        "arrival_date": "2024-01-20"
      },
      {
        "mandi": "Jalandhar",
        "state": "Punjab",
        "district": "Jalandhar",
        "modal_price": 2140,
        "min_price": 2090,
        "max_price": 2180,
        "arrival_date": "2024-01-20"
      },
      {
        "mandi": "Amritsar",
        "state": "Punjab",
        "district": "Amritsar",
        "modal_price": 2160,
        "min_price": 2110,
        "max_price": 2210,
        "arrival_date": "2024-01-19"
      }
    ],
    "recommendation": "Prices stable. Good time to sell at current rates.",
    "lastUpdated": "2024-01-20",
    "cached": false
  },
  "timestamp": "2024-01-20T16:00:00Z"
}
```

**No Data Response** (200 OK):
```json
{
  "success": true,
  "data": {
    "crop": "Saffron",
    "prices": [],
    "recommendation": "No price data available for this crop.",
    "lastUpdated": "2024-01-20T16:00:00Z",
    "cached": false
  },
  "timestamp": "2024-01-20T16:00:00Z"
}
```

**Error Responses**:
- `400 Bad Request`: Missing crop parameter
- `401 Unauthorized`: Missing or invalid authentication token
- `429 Too Many Requests`: Rate limit exceeded
- `500 Internal Server Error`: Server error or external API unavailable

**Rate Limits**:
- 20 requests per minute per user
- 200 requests per day per user

**Cache Behavior**:
- Price data is cached for 6 hours
- Cached responses include `"cached": true` flag
- Stale data (>24 hours) includes warning in response

## Deployment Architecture

### AWS Lambda Configuration

**serverless.yml** (Complete Configuration):
```yaml
service: krishiai-mitra-api

frameworkVersion: '3'

provider:
  name: aws
  runtime: nodejs18.x
  region: ap-south-1  # Mumbai region for low latency to India
  stage: ${opt:stage, 'dev'}
  memorySize: 512
  timeout: 30
  
  environment:
    NODE_ENV: ${self:provider.stage}
    MONGODB_URI: ${env:MONGODB_URI}
    JWT_SECRET: ${env:JWT_SECRET}
    BEDROCK_MODEL_ID: anthropic.claude-3-haiku-20240307-v1:0
    GOOGLE_VISION_KEY_PATH: ${env:GOOGLE_VISION_KEY_PATH}
    HUGGINGFACE_API_KEY: ${env:HUGGINGFACE_API_KEY}
    CLOUDINARY_CLOUD_NAME: ${env:CLOUDINARY_CLOUD_NAME}
    CLOUDINARY_API_KEY: ${env:CLOUDINARY_API_KEY}
    CLOUDINARY_API_SECRET: ${env:CLOUDINARY_API_SECRET}
    DATA_GOV_API_KEY: ${env:DATA_GOV_API_KEY}
  
  iam:
    role:
      statements:
        - Effect: Allow
          Action:
            - bedrock:InvokeModel
          Resource: 
            - arn:aws:bedrock:us-east-1::foundation-model/anthropic.claude-3-haiku-20240307-v1:0
        - Effect: Allow
          Action:
            - logs:CreateLogGroup
            - logs:CreateLogStream
            - logs:PutLogEvents
          Resource: 
            - arn:aws:logs:${self:provider.region}:*:log-group:/aws/lambda/*

functions:
  voiceQuery:
    handler: src/handlers/voice.handler
    events:
      - http:
          path: /api/voice/query
          method: post
          cors:
            origin: '*'
            headers:
              - Content-Type
              - Authorization
    reservedConcurrency: 5  # Limit concurrent executions
  
  diseaseDetect:
    handler: src/handlers/disease.handler
    timeout: 30  # Longer timeout for image processing
    events:
      - http:
          path: /api/disease/detect
          method: post
          cors:
            origin: '*'
            headers:
              - Content-Type
              - Authorization
    reservedConcurrency: 3
  
  priceCheck:
    handler: src/handlers/price.handler
    events:
      - http:
          path: /api/price/mandi
          method: get
          cors:
            origin: '*'
            headers:
              - Content-Type
              - Authorization
    reservedConcurrency: 10
  
  authRegister:
    handler: src/handlers/auth.register
    events:
      - http:
          path: /api/auth/register
          method: post
          cors: true
  
  authLogin:
    handler: src/handlers/auth.login
    events:
      - http:
          path: /api/auth/login
          method: post
          cors: true

plugins:
  - serverless-offline

custom:
  serverless-offline:
    httpPort: 3000
```

### Deployment Steps

**Prerequisites**:
```bash
# Install Serverless Framework
npm install -g serverless

# Install AWS CLI
pip install awscli

# Configure AWS credentials
aws configure
```

**Environment Setup**:
```bash
# Create .env file
cat > .env << EOF
MONGODB_URI=mongodb+srv://username:password@cluster.mongodb.net/krishiai
JWT_SECRET=your-super-secret-jwt-key-change-in-production
GOOGLE_VISION_KEY_PATH=./google-vision-key.json
HUGGINGFACE_API_KEY=hf_xxxxxxxxxxxxxxxxxxxxx
CLOUDINARY_CLOUD_NAME=your-cloud-name
CLOUDINARY_API_KEY=123456789012345
CLOUDINARY_API_SECRET=your-cloudinary-secret
DATA_GOV_API_KEY=your-data-gov-api-key
EOF
```

**Deployment Commands**:
```bash
# Install dependencies
npm install

# Deploy to development
serverless deploy --stage dev

# Deploy to production
serverless deploy --stage prod

# Deploy single function (faster)
serverless deploy function -f voiceQuery --stage dev

# View logs
serverless logs -f voiceQuery --tail

# Remove deployment
serverless remove --stage dev
```

**Local Development**:
```bash
# Start local API server
serverless offline start

# Test endpoints locally
curl -X POST http://localhost:3000/api/voice/query \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <token>" \
  -d '{"query": "Test query", "language": "en-US", "userId": "123"}'
```

### Flutter App Deployment

**Android Build**:
```bash
# Build APK
flutter build apk --release

# Build App Bundle (for Play Store)
flutter build appbundle --release

# Output location
# build/app/outputs/flutter-apk/app-release.apk
# build/app/outputs/bundle/release/app-release.aab
```

**iOS Build**:
```bash
# Build iOS app
flutter build ios --release

# Archive for App Store
# Open Xcode and archive from there
```

**Environment Configuration** (`lib/config/app_config.dart`):
```dart
class AppConfig {
  static const String environment = String.fromEnvironment(
    'ENV',
    defaultValue: 'development',
  );
  
  static String get apiBaseUrl {
    switch (environment) {
      case 'production':
        return 'https://api.krishiai.com';
      case 'staging':
        return 'https://staging-api.krishiai.com';
      default:
        return 'http://localhost:3000';
    }
  }
  
  static const bool enableLogging = environment != 'production';
}
```

**Build with Environment**:
```bash
# Development build
flutter build apk --dart-define=ENV=development

# Production build
flutter build apk --release --dart-define=ENV=production
```

## Free Tier Cost Breakdown

### Detailed Service Usage and Costs

| Service | Free Tier Limit | Expected Demo Usage | Cost if Exceeded | Mitigation Strategy |
|---------|----------------|---------------------|------------------|---------------------|
| **AWS Lambda** | 1M requests/month<br>400K GB-seconds | 10K requests<br>5K GB-seconds | $0.20 per 1M requests<br>$0.0000166667 per GB-second | Aggressive caching (24h for voice, 7d for disease)<br>Reserved concurrency limits |
| **API Gateway** | 1M requests/month | 10K requests | $3.50 per 1M requests | Same as Lambda - caching reduces calls |
| **Amazon Bedrock** | 10K tokens/month (Claude Haiku) | 5K tokens | $0.00025 per 1K input tokens<br>$0.00125 per 1K output tokens | Cache identical queries for 24h<br>Limit response length to 500 tokens |
| **Google Cloud Vision** | 1000 requests/month | 200 requests | $1.50 per 1K requests | Cache by image hash (MD5)<br>Reuse results for identical images |
| **Hugging Face API** | Rate limited (free) | 200 requests | N/A (free tier) | Exponential backoff on rate limits<br>Cache results by image hash |
| **MongoDB Atlas** | 512MB storage<br>Unlimited reads/writes | 50MB storage<br>10K operations | $0.08 per GB/month | Data retention: 30 days for conversations<br>90 days for diagnoses<br>Indexes on frequently queried fields |
| **Cloudinary** | 25 credits/month<br>(~25GB bandwidth<br>~7.5GB storage) | 5 credits<br>(~5GB bandwidth) | $0.0018 per credit | Compress images before upload<br>Auto-optimize delivery<br>Delete old images after 90 days |
| **CloudWatch Logs** | 5GB ingestion<br>5GB storage | 500MB | $0.50 per GB ingestion<br>$0.03 per GB storage | Log only errors and warnings in production<br>7-day retention |
| **Data.gov.in API** | Unlimited (public) | Unlimited | Free | Cache for 6 hours<br>No cost concerns |

### Cost Optimization Strategies

#### 1. Caching Strategy

**Voice Queries**:
- Cache identical queries for 24 hours
- Use lowercase normalization for cache keys
- Expected cache hit rate: 40-50%
- Savings: ~2K Bedrock tokens per day

**Disease Detection**:
- Cache by MD5 image hash for 7 days
- Expected cache hit rate: 20-30%
- Savings: ~60 Vision API calls per day

**Mandi Prices**:
- Cache by crop+state for 6 hours
- Expected cache hit rate: 60-70%
- Savings: ~150 API calls per day

#### 2. Request Throttling

```javascript
// Rate limiter configuration
const rateLimits = {
  voice: { requests: 10, window: 60 },      // 10 per minute
  disease: { requests: 5, window: 60 },     // 5 per minute
  price: { requests: 20, window: 60 }       // 20 per minute
};

// Free tier monitoring
const freeT ierThresholds = {
  bedrock: { limit: 10000, alert: 8000 },   // Alert at 80%
  vision: { limit: 1000, alert: 800 },
  lambda: { limit: 1000000, alert: 800000 }
};
```

#### 3. Data Retention Policies

```javascript
// MongoDB TTL indexes for automatic cleanup
db.conversations.createIndex(
  { "timestamp": 1 },
  { expireAfterSeconds: 2592000 }  // 30 days
);

db.diagnoses.createIndex(
  { "timestamp": 1 },
  { expireAfterSeconds: 7776000 }  // 90 days
);

db.price_queries.createIndex(
  { "timestamp": 1 },
  { expireAfterSeconds: 2592000 }  // 30 days
);
```

#### 4. Image Optimization

```javascript
// Cloudinary upload with optimization
const uploadOptions = {
  folder: 'diseases',
  quality: 'auto:low',           // Automatic quality optimization
  fetch_format: 'auto',          // Automatic format selection (WebP)
  width: 800,                    // Resize to max 800px width
  crop: 'limit'                  // Don't upscale
};

// Expected savings: 60-70% bandwidth reduction
```

### Monitoring Dashboard

**Key Metrics to Track**:
```javascript
// Daily usage tracking
{
  date: "2024-01-20",
  usage: {
    lambdaInvocations: 450,
    lambdaGBSeconds: 225,
    bedrockTokens: 2100,
    visionApiCalls: 18,
    huggingfaceCalls: 18,
    mongodbStorage: 45,  // MB
    cloudinaryCredits: 2.5,
    cacheHitRate: 0.45
  },
  costs: {
    lambda: 0.00,
    bedrock: 0.00,
    vision: 0.00,
    mongodb: 0.00,
    cloudinary: 0.00,
    total: 0.00
  },
  alerts: []
}
```

### Cost Projection for Hackathon Demo

**Assumptions**:
- 100 test users
- 2-day demo period
- 5 interactions per user per day

**Projected Usage**:
- Voice queries: 500 (50% cached) = 250 Bedrock calls
- Disease detections: 200 (30% cached) = 140 Vision API calls
- Price checks: 300 (70% cached) = 90 Data.gov.in calls
- Total Lambda invocations: 1000
- Total storage: 50MB MongoDB + 2GB Cloudinary

**Projected Cost**: $0.00 (100% within free tier)

**Safety Margin**: 
- Lambda: 99.9% free tier remaining
- Bedrock: 75% free tier remaining
- Vision API: 86% free tier remaining
- MongoDB: 90% free tier remaining
- Cloudinary: 92% free tier remaining

## Sequence Diagrams

### Voice Assistant Flow

```
User → Flutter App → API Gateway → Lambda → Bedrock → Lambda → MongoDB → Lambda → Flutter App → User

Detailed Steps:
1. User taps microphone button in Flutter app
2. Flutter app requests microphone permission
3. User speaks agricultural question in Hindi/English
4. speech_to_text package converts audio to text
5. Flutter app sends POST request to /api/voice/query
   {
     "query": "Mere gehun ki patti peeli kyu ho rahi hai?",
     "language": "hi-IN",
     "userId": "507f..."
   }
6. API Gateway validates JWT token
7. API Gateway forwards request to Lambda function
8. Lambda checks in-memory cache for identical query
9. If cache miss:
   a. Lambda calls Bedrock service with query
   b. Bedrock (Claude 3 Haiku) generates response
   c. Lambda receives AI response with token count
10. Lambda saves conversation to MongoDB
11. Lambda caches response (24h TTL)
12. Lambda returns response to API Gateway
13. API Gateway returns response to Flutter app
14. Flutter app receives JSON response
15. flutter_tts package converts text to speech
16. User hears spoken answer in their language
17. Conversation bubble appears in UI with Q&A

Cache Hit Path (Steps 8-10 replaced):
8. Lambda finds cached response
9. Lambda returns cached response immediately
10. Skip MongoDB write and Bedrock call
```

### Disease Detection Flow

```
User → Flutter App → Camera → Flutter App → API Gateway → Lambda → Cloudinary → Lambda → Vision API → Lambda → HuggingFace → Lambda → MongoDB → Lambda → Flutter App → User

Detailed Steps:
1. User taps "Detect Disease" button
2. Flutter app shows camera/gallery picker
3. User captures or selects crop image
4. image_picker package returns image file
5. Flutter app compresses image (max 1024x1024, 85% quality)
6. Flutter app calculates MD5 hash of image
7. Flutter app sends POST multipart/form-data to /api/disease/detect
   {
     "image": <binary>,
     "userId": "507f...",
     "language": "hi-IN"
   }
8. API Gateway validates JWT token and file size (<5MB)
9. API Gateway forwards to Lambda function
10. Lambda receives image buffer
11. Lambda calculates image hash (MD5)
12. Lambda checks cache by image hash
13. If cache miss:
    a. Lambda uploads image to Cloudinary
    b. Cloudinary returns secure URL
    c. Lambda calls Google Vision API with image
    d. Vision API returns labels and features
    e. Lambda calls HuggingFace disease classification model
    f. HuggingFace returns disease name and confidence
    g. Lambda looks up treatments from database
14. Lambda saves diagnosis to MongoDB
15. Lambda caches result by image hash (7d TTL)
16. Lambda returns diagnosis response
17. API Gateway returns response to Flutter app
18. Flutter app displays:
    - Disease name
    - Confidence score (with color coding)
    - Treatment recommendations in user's language
    - Original image
19. If confidence < 60%:
    - Show warning message
    - Suggest capturing clearer image
    - Provide image quality tips

Cache Hit Path (Steps 13 replaced):
13. Lambda finds cached diagnosis by hash
14. Skip Cloudinary, Vision, HuggingFace calls
15. Return cached result immediately
```

### Mandi Price Flow

```
User → Flutter App → API Gateway → Lambda → Data.gov.in API → Lambda → MongoDB → Lambda → Flutter App → User

Detailed Steps:
1. User types crop name in search bar (e.g., "Wheat")
2. User taps search or selects from common crops chips
3. Flutter app sends GET request to /api/price/mandi
   ?crop=Wheat&state=Punjab&userId=507f...
4. API Gateway validates JWT token
5. API Gateway forwards to Lambda function
6. Lambda receives query parameters
7. Lambda creates cache key: "price:wheat:punjab"
8. Lambda checks cache (6h TTL)
9. If cache miss:
   a. Lambda calls Data.gov.in API
   b. API returns mandi price records
   c. Lambda parses and sorts by date
   d. Lambda calculates price trend
   e. Lambda generates recommendation:
      - If trend > 5%: "Hold for better rates"
      - If trend < -5%: "Sell now"
      - Else: "Good time to sell"
10. Lambda saves query to MongoDB (analytics)
11. Lambda caches result (6h TTL)
12. Lambda returns price data with recommendation
13. API Gateway returns response to Flutter app
14. Flutter app displays:
    - List of mandis with prices
    - Price cards sorted by date
    - Recommendation banner (color-coded)
    - Last updated timestamp
15. If data > 24h old:
    - Show staleness warning
16. If no data found:
    - Show "No prices available" message
    - Suggest alternative crops

Cache Hit Path (Steps 9-10 replaced):
9. Lambda finds cached price data
10. Return cached result immediately
11. Skip Data.gov.in API call and MongoDB write
```

### Offline Sync Flow

```
User (Offline) → Flutter App → Local Storage → User (Online) → Flutter App → API Gateway → Lambda

Detailed Steps:
1. connectivity_plus package detects network loss
2. Flutter app shows "Offline Mode" indicator
3. User captures disease image while offline
4. Flutter app saves image to local storage (Hive)
5. Flutter app adds to sync queue
6. User asks voice question while offline
7. Flutter app shows "Will process when online" message
8. Flutter app adds to sync queue
9. connectivity_plus detects network restored
10. Flutter app shows "Syncing..." indicator
11. Flutter app processes sync queue:
    a. Upload queued disease images
    b. Send queued voice queries
    c. Fetch latest price data
12. Flutter app receives responses
13. Flutter app updates local cache
14. Flutter app shows success notifications
15. Flutter app clears sync queue
16. User can view all updated data

Offline Data Access:
- Last 10 disease diagnoses (cached locally)
- Last 5 price queries (cached locally)
- Last 20 conversation messages (cached locally)
- All data stored in Hive database
- Automatic cleanup when storage > 50MB
```

## Error Handling Strategy

### Flutter Error Handling

**Global Error Handler** (`lib/utils/error_handler.dart`):
```dart
class ErrorHandler {
  static void handleError(dynamic error, {VoidCallback? onRetry}) {
    String message;
    String? actionText;
    VoidCallback? action;
    
    if (error is NetworkException) {
      message = 'No internet connection. Please check your network.';
      actionText = 'Retry';
      action = onRetry;
    } else if (error is AuthException) {
      message = 'Session expired. Please login again.';
      actionText = 'Login';
      action = () => navigateToLogin();
    } else if (error is RateLimitException) {
      message = 'Too many requests. Please try again in a few minutes.';
    } else if (error is ServerException) {
      message = 'Server error. Our team has been notified.';
      actionText = 'Retry';
      action = onRetry;
    } else {
      message = 'Something went wrong. Please try again.';
      actionText = 'Retry';
      action = onRetry;
    }
    
    // Show snackbar with error message
    showErrorSnackbar(message, actionText: actionText, action: action);
    
    // Log error for debugging
    logger.error('Error occurred', error: error);
  }
}
```

**API Service Error Handling** (`lib/services/api_service.dart`):
```dart
class ApiService {
  final Dio _dio = Dio();
  
  ApiService() {
    _dio.interceptors.add(InterceptorsWrapper(
      onError: (DioError error, handler) async {
        if (error.response?.statusCode == 401) {
          // Token expired - refresh or logout
          await _handleAuthError();
          return handler.reject(AuthException());
        } else if (error.response?.statusCode == 429) {
          // Rate limit exceeded
          return handler.reject(RateLimitException());
        } else if (error.type == DioErrorType.connectionTimeout ||
                   error.type == DioErrorType.receiveTimeout) {
          // Network timeout
          return handler.reject(NetworkException('Request timeout'));
        } else if (error.type == DioErrorType.unknown) {
          // No internet connection
          return handler.reject(NetworkException('No internet connection'));
        }
        
        return handler.next(error);
      },
    ));
    
    // Retry interceptor
    _dio.interceptors.add(RetryInterceptor(
      dio: _dio,
      retries: 3,
      retryDelays: [
        Duration(seconds: 1),
        Duration(seconds: 2),
        Duration(seconds: 4),
      ],
    ));
  }
  
  Future<T> get<T>(String path, {Map<String, dynamic>? params}) async {
    try {
      final response = await _dio.get(path, queryParameters: params);
      return response.data['data'] as T;
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<T> post<T>(String path, {dynamic data}) async {
    try {
      final response = await _dio.post(path, data: data);
      return response.data['data'] as T;
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  Exception _handleError(dynamic error) {
    if (error is DioError) {
      if (error.response != null) {
        final message = error.response!.data['error']['message'];
        return ServerException(message);
      }
    }
    return Exception('Unknown error occurred');
  }
}
```

### Backend Error Handling

**Global Error Handler Middleware** (`src/middleware/errorHandler.js`):
```javascript
const logger = require('../utils/logger');
const { errorResponse } = require('../utils/response');

class AppError extends Error {
  constructor(message, statusCode, code) {
    super(message);
    this.statusCode = statusCode;
    this.code = code;
    this.isOperational = true;
    Error.captureStackTrace(this, this.constructor);
  }
}

const errorHandler = (err, req, res, next) => {
  let error = { ...err };
  error.message = err.message;
  
  // Log error
  logger.error('Error occurred', {
    message: err.message,
    stack: err.stack,
    url: req.url,
    method: req.method,
    userId: req.user?.id
  });
  
  // Mongoose validation error
  if (err.name === 'ValidationError') {
    const message = Object.values(err.errors).map(e => e.message).join(', ');
    error = new AppError(message, 400, 'VALIDATION_ERROR');
  }
  
  // Mongoose duplicate key error
  if (err.code === 11000) {
    const field = Object.keys(err.keyValue)[0];
    error = new AppError(`${field} already exists`, 400, 'DUPLICATE_ERROR');
  }
  
  // JWT errors
  if (err.name === 'JsonWebTokenError') {
    error = new AppError('Invalid token', 401, 'INVALID_TOKEN');
  }
  
  if (err.name === 'TokenExpiredError') {
    error = new AppError('Token expired', 401, 'TOKEN_EXPIRED');
  }
  
  // Bedrock API errors
  if (err.name === 'ThrottlingException') {
    error = new AppError('AI service rate limit exceeded. Please try again later.', 429, 'RATE_LIMIT');
  }
  
  // Vision API errors
  if (err.message?.includes('QUOTA_EXCEEDED')) {
    error = new AppError('Image analysis quota exceeded. Please try again tomorrow.', 429, 'QUOTA_EXCEEDED');
  }
  
  // Default error
  const statusCode = error.statusCode || 500;
  const code = error.code || 'INTERNAL_ERROR';
  const message = error.isOperational 
    ? error.message 
    : 'Something went wrong. Please try again.';
  
  return errorResponse(res, message, statusCode, code);
};

// Async error wrapper
const asyncHandler = (fn) => (req, res, next) => {
  Promise.resolve(fn(req, res, next)).catch(next);
};

module.exports = { errorHandler, asyncHandler, AppError };
```

**Circuit Breaker Pattern** (`src/utils/circuitBreaker.js`):
```javascript
class CircuitBreaker {
  constructor(service, options = {}) {
    this.service = service;
    this.failureThreshold = options.failureThreshold || 5;
    this.resetTimeout = options.resetTimeout || 60000; // 1 minute
    this.state = 'CLOSED'; // CLOSED, OPEN, HALF_OPEN
    this.failureCount = 0;
    this.nextAttempt = Date.now();
  }
  
  async call(...args) {
    if (this.state === 'OPEN') {
      if (Date.now() < this.nextAttempt) {
        throw new Error('Circuit breaker is OPEN');
      }
      this.state = 'HALF_OPEN';
    }
    
    try {
      const result = await this.service(...args);
      this.onSuccess();
      return result;
    } catch (error) {
      this.onFailure();
      throw error;
    }
  }
  
  onSuccess() {
    this.failureCount = 0;
    this.state = 'CLOSED';
  }
  
  onFailure() {
    this.failureCount++;
    if (this.failureCount >= this.failureThreshold) {
      this.state = 'OPEN';
      this.nextAttempt = Date.now() + this.resetTimeout;
      logger.warn('Circuit breaker opened', { service: this.service.name });
    }
  }
}

// Usage
const bedrockCircuit = new CircuitBreaker(bedrockService.generateResponse, {
  failureThreshold: 3,
  resetTimeout: 30000
});

module.exports = CircuitBreaker;
```

**Retry Logic with Exponential Backoff** (`src/utils/retry.js`):
```javascript
async function retryWithBackoff(fn, maxRetries = 3, baseDelay = 1000) {
  for (let attempt = 0; attempt < maxRetries; attempt++) {
    try {
      return await fn();
    } catch (error) {
      if (attempt === maxRetries - 1) {
        throw error;
      }
      
      const delay = baseDelay * Math.pow(2, attempt);
      logger.info('Retrying after error', { attempt, delay });
      await new Promise(resolve => setTimeout(resolve, delay));
    }
  }
}

module.exports = { retryWithBackoff };
```

## Security Considerations

### 1. API Authentication and Authorization

**JWT Token Implementation**:
```javascript
// src/middleware/auth.js
const jwt = require('jsonwebtoken');
const { AppError } = require('./errorHandler');

const authenticate = async (req, res, next) => {
  try {
    // Extract token from header
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      throw new AppError('No token provided', 401, 'NO_TOKEN');
    }
    
    const token = authHeader.split(' ')[1];
    
    // Verify token
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    
    // Check token expiration
    if (decoded.exp < Date.now() / 1000) {
      throw new AppError('Token expired', 401, 'TOKEN_EXPIRED');
    }
    
    // Attach user to request
    req.user = {
      id: decoded.userId,
      phoneNumber: decoded.phoneNumber
    };
    
    next();
  } catch (error) {
    if (error.name === 'JsonWebTokenError') {
      return next(new AppError('Invalid token', 401, 'INVALID_TOKEN'));
    }
    next(error);
  }
};

// Token generation
const generateToken = (userId, phoneNumber) => {
  return jwt.sign(
    { userId, phoneNumber },
    process.env.JWT_SECRET,
    { expiresIn: '7d' }
  );
};

module.exports = { authenticate, generateToken };
```

### 2. Input Validation and Sanitization

**Request Validation Middleware**:
```javascript
// src/middleware/validator.js
const Joi = require('joi');
const { AppError } = require('./errorHandler');

const validateVoiceQuery = (req, res, next) => {
  const schema = Joi.object({
    query: Joi.string().min(3).max(500).required(),
    language: Joi.string().valid('hi-IN', 'en-US').required(),
    userId: Joi.string().pattern(/^[0-9a-fA-F]{24}$/).required()
  });
  
  const { error } = schema.validate(req.body);
  if (error) {
    throw new AppError(error.details[0].message, 400, 'VALIDATION_ERROR');
  }
  
  // Sanitize input
  req.body.query = req.body.query.trim();
  
  next();
};

const validateImageUpload = (req, res, next) => {
  if (!req.file) {
    throw new AppError('No image file provided', 400, 'NO_FILE');
  }
  
  // Check file type
  const allowedTypes = ['image/jpeg', 'image/png', 'image/webp'];
  if (!allowedTypes.includes(req.file.mimetype)) {
    throw new AppError('Invalid file type. Only JPEG, PNG, WebP allowed', 400, 'INVALID_FILE_TYPE');
  }
  
  // Check file size (5MB limit)
  if (req.file.size > 5 * 1024 * 1024) {
    throw new AppError('File too large. Maximum 5MB allowed', 413, 'FILE_TOO_LARGE');
  }
  
  next();
};

module.exports = { validateVoiceQuery, validateImageUpload };
```

### 3. Rate Limiting

**Rate Limiter Implementation**:
```javascript
// src/middleware/rateLimiter.js
const NodeCache = require('node-cache');
const { AppError } = require('./errorHandler');

const cache = new NodeCache({ stdTTL: 60 });

const rateLimiter = (options) => {
  const { requests, window, message } = options;
  
  return (req, res, next) => {
    const userId = req.user?.id || req.ip;
    const key = `ratelimit:${userId}:${req.path}`;
    
    const current = cache.get(key) || 0;
    
    if (current >= requests) {
      throw new AppError(
        message || 'Too many requests. Please try again later.',
        429,
        'RATE_LIMIT_EXCEEDED'
      );
    }
    
    cache.set(key, current + 1, window);
    
    // Add rate limit headers
    res.setHeader('X-RateLimit-Limit', requests);
    res.setHeader('X-RateLimit-Remaining', requests - current - 1);
    res.setHeader('X-RateLimit-Reset', Date.now() + (window * 1000));
    
    next();
  };
};

// Usage in routes
app.post('/api/voice/query', 
  authenticate,
  rateLimiter({ requests: 10, window: 60 }),
  voiceController.handleVoiceQuery
);

module.exports = rateLimiter;
```

### 4. Data Encryption

**Password Hashing**:
```javascript
// src/models/User.js
const bcrypt = require('bcryptjs');

const userSchema = new mongoose.Schema({
  phoneNumber: { type: String, required: true, unique: true },
  passwordHash: { type: String, required: true },
  // ... other fields
});

// Hash password before saving
userSchema.pre('save', async function(next) {
  if (!this.isModified('passwordHash')) return next();
  
  const salt = await bcrypt.genSalt(10);
  this.passwordHash = await bcrypt.hash(this.passwordHash, salt);
  next();
});

// Method to compare passwords
userSchema.methods.comparePassword = async function(candidatePassword) {
  return await bcrypt.compare(candidatePassword, this.passwordHash);
};
```

**Data at Rest Encryption** (MongoDB Atlas):
```javascript
// MongoDB Atlas automatically encrypts data at rest
// Enable in Atlas console: Security > Encryption at Rest
// Uses AES-256 encryption
```

**Data in Transit** (TLS/HTTPS):
```yaml
# API Gateway automatically provides HTTPS
# Enforce HTTPS only in serverless.yml
provider:
  endpointType: REGIONAL
  apiGateway:
    minimumCompressionSize: 1024
    shouldStartNameWithService: true
```

### 5. Secure API Key Management

**Environment Variables**:
```javascript
// src/config/env.js
const requiredEnvVars = [
  'MONGODB_URI',
  'JWT_SECRET',
  'GOOGLE_VISION_KEY_PATH',
  'HUGGINGFACE_API_KEY',
  'CLOUDINARY_API_KEY',
  'CLOUDINARY_API_SECRET'
];

// Validate all required env vars are present
requiredEnvVars.forEach(varName => {
  if (!process.env[varName]) {
    throw new Error(`Missing required environment variable: ${varName}`);
  }
});

// Never log sensitive values
const sanitizeForLogging = (obj) => {
  const sensitive = ['password', 'token', 'secret', 'key', 'api'];
  const sanitized = { ...obj };
  
  Object.keys(sanitized).forEach(key => {
    if (sensitive.some(s => key.toLowerCase().includes(s))) {
      sanitized[key] = '***REDACTED***';
    }
  });
  
  return sanitized;
};

module.exports = { sanitizeForLogging };
```

### 6. Image Upload Security

**Cloudinary Security Configuration**:
```javascript
// src/services/cloudinaryService.js
const cloudinary = require('cloudinary').v2;

cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET,
  secure: true  // Force HTTPS
});

exports.uploadImage = async (imageBuffer, folder) => {
  return new Promise((resolve, reject) => {
    const uploadStream = cloudinary.uploader.upload_stream(
      {
        folder,
        resource_type: 'image',
        allowed_formats: ['jpg', 'png', 'webp'],
        max_file_size: 5000000,  // 5MB
        access_mode: 'authenticated',  // Require signed URLs
        invalidate: true  // Invalidate CDN cache
      },
      (error, result) => {
        if (error) reject(error);
        else resolve(result);
      }
    );
    
    uploadStream.end(imageBuffer);
  });
};

// Generate signed URL for secure access
exports.getSignedUrl = (publicId) => {
  return cloudinary.url(publicId, {
    sign_url: true,
    type: 'authenticated'
  });
};
```

### 7. CORS Configuration

```javascript
// Strict CORS policy
const corsOptions = {
  origin: (origin, callback) => {
    const allowedOrigins = [
      'https://krishiai.com',
      'https://app.krishiai.com',
      'http://localhost:3000'  // Development only
    ];
    
    if (!origin || allowedOrigins.includes(origin)) {
      callback(null, true);
    } else {
      callback(new Error('Not allowed by CORS'));
    }
  },
  credentials: true,
  optionsSuccessStatus: 200
};

app.use(cors(corsOptions));
```

### 8. Security Headers

```javascript
// src/middleware/securityHeaders.js
const helmet = require('helmet');

app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'"],
      scriptSrc: ["'self'"],
      imgSrc: ["'self'", 'data:', 'https://res.cloudinary.com']
    }
  },
  hsts: {
    maxAge: 31536000,
    includeSubDomains: true,
    preload: true
  }
}));

// Additional security headers
app.use((req, res, next) => {
  res.setHeader('X-Content-Type-Options', 'nosniff');
  res.setHeader('X-Frame-Options', 'DENY');
  res.setHeader('X-XSS-Protection', '1; mode=block');
  next();
});
```

### 9. Audit Logging

```javascript
// src/utils/auditLogger.js
const AuditLog = require('../models/AuditLog');

const logAuditEvent = async (event) => {
  try {
    await AuditLog.create({
      userId: event.userId,
      action: event.action,
      resource: event.resource,
      ipAddress: event.ipAddress,
      userAgent: event.userAgent,
      timestamp: new Date(),
      metadata: event.metadata
    });
  } catch (error) {
    logger.error('Failed to log audit event', { error });
  }
};

// Usage
await logAuditEvent({
  userId: req.user.id,
  action: 'DISEASE_DETECTION',
  resource: 'diagnosis',
  ipAddress: req.ip,
  userAgent: req.headers['user-agent'],
  metadata: { confidence: 0.92, disease: 'Early Blight' }
});
```

### 10. Compliance and Privacy

**Data Privacy Measures**:
- No storage of raw voice recordings (only transcribed text)
- User consent for image storage
- Right to deletion (GDPR-style)
- Data retention policies (30-90 days)
- Anonymized analytics

**Compliance Checklist**:
- ✅ HTTPS/TLS for all communications
- ✅ JWT-based authentication
- ✅ Password hashing (bcrypt)
- ✅ Input validation and sanitization
- ✅ Rate limiting per user
- ✅ Secure API key storage
- ✅ Image upload validation
- ✅ CORS restrictions
- ✅ Security headers
- ✅ Audit logging
- ✅ Data encryption at rest
- ✅ Signed URLs for images
- ✅ No PII in logs

## Monitoring and Logging

### CloudWatch Metrics

**Lambda Function Metrics**:
```javascript
// src/utils/metrics.js
const { CloudWatch } = require('@aws-sdk/client-cloudwatch');
const cloudwatch = new CloudWatch({ region: 'ap-south-1' });

const publishMetric = async (metricName, value, unit = 'Count') => {
  try {
    await cloudwatch.putMetricData({
      Namespace: 'KrishiAI/Application',
      MetricData: [
        {
          MetricName: metricName,
          Value: value,
          Unit: unit,
          Timestamp: new Date()
        }
      ]
    });
  } catch (error) {
    logger.error('Failed to publish metric', { error });
  }
};

// Usage in controllers
await publishMetric('VoiceQuerySuccess', 1);
await publishMetric('DiseaseDetectionLatency', responseTime, 'Milliseconds');
await publishMetric('BedrockTokensUsed', tokensUsed, 'Count');
```

**Custom Dashboards**:
```javascript
// Key metrics to monitor
const metrics = {
  // Performance
  'LambdaInvocations': 'Count of all Lambda invocations',
  'LambdaDuration': 'Average execution time',
  'LambdaErrors': 'Count of Lambda errors',
  'ApiGatewayLatency': 'API response time',
  
  // Business
  'VoiceQueries': 'Total voice queries processed',
  'DiseaseDetections': 'Total disease detections',
  'PriceChecks': 'Total price checks',
  'ActiveUsers': 'Daily active users',
  
  // AI Services
  'BedrockTokensUsed': 'Bedrock tokens consumed',
  'VisionApiCalls': 'Vision API calls made',
  'HuggingFaceCalls': 'HuggingFace API calls',
  
  // Cache
  'CacheHitRate': 'Percentage of cache hits',
  'CacheMisses': 'Count of cache misses',
  
  // Errors
  'ErrorRate': 'Percentage of failed requests',
  'RateLimitExceeded': 'Count of rate limit hits'
};
```

### Structured Logging

**Winston Logger Configuration** (`src/utils/logger.js`):
```javascript
const winston = require('winston');

const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.errors({ stack: true }),
    winston.format.json()
  ),
  defaultMeta: {
    service: 'krishiai-api',
    environment: process.env.NODE_ENV
  },
  transports: [
    // CloudWatch Logs (production)
    new winston.transports.Console({
      format: winston.format.combine(
        winston.format.colorize(),
        winston.format.simple()
      )
    })
  ]
});

// Log levels: error, warn, info, debug
// Usage:
// logger.info('Voice query processed', { userId, query, tokensUsed });
// logger.error('Bedrock API error', { error: error.message, stack: error.stack });

module.exports = logger;
```

**Log Sampling** (Reduce CloudWatch costs):
```javascript
// Only log 10% of successful requests in production
const shouldLog = (level) => {
  if (process.env.NODE_ENV !== 'production') return true;
  if (level === 'error' || level === 'warn') return true;
  return Math.random() < 0.1;  // 10% sampling
};

if (shouldLog('info')) {
  logger.info('Request processed successfully', { userId, endpoint });
}
```

### Alerting Configuration

**CloudWatch Alarms**:
```javascript
// Critical alerts to configure in AWS Console
const alarms = [
  {
    name: 'HighErrorRate',
    metric: 'ErrorRate',
    threshold: 5,  // 5% error rate
    period: 300,   // 5 minutes
    evaluationPeriods: 2,
    action: 'SNS notification to admin'
  },
  {
    name: 'BedrockQuotaWarning',
    metric: 'BedrockTokensUsed',
    threshold: 8000,  // 80% of 10K free tier
    period: 3600,     // 1 hour
    evaluationPeriods: 1,
    action: 'SNS notification to admin'
  },
  {
    name: 'VisionApiQuotaWarning',
    metric: 'VisionApiCalls',
    threshold: 800,  // 80% of 1000 free tier
    period: 86400,   // 1 day
    evaluationPeriods: 1,
    action: 'SNS notification to admin'
  },
  {
    name: 'HighLatency',
    metric: 'ApiGatewayLatency',
    threshold: 5000,  // 5 seconds
    period: 300,
    evaluationPeriods: 3,
    action: 'SNS notification to admin'
  },
  {
    name: 'LambdaThrottling',
    metric: 'LambdaThrottles',
    threshold: 10,
    period: 60,
    evaluationPeriods: 1,
    action: 'SNS notification to admin'
  }
];
```

### Health Check Endpoint

```javascript
// src/handlers/health.js
exports.handler = async (event) => {
  const health = {
    status: 'healthy',
    timestamp: new Date().toISOString(),
    services: {}
  };
  
  // Check MongoDB connection
  try {
    await mongoose.connection.db.admin().ping();
    health.services.mongodb = 'healthy';
  } catch (error) {
    health.services.mongodb = 'unhealthy';
    health.status = 'degraded';
  }
  
  // Check Bedrock availability
  try {
    await bedrockClient.send(new ListFoundationModelsCommand({}));
    health.services.bedrock = 'healthy';
  } catch (error) {
    health.services.bedrock = 'unhealthy';
    health.status = 'degraded';
  }
  
  // Check cache
  health.services.cache = cacheService.isHealthy() ? 'healthy' : 'unhealthy';
  
  return {
    statusCode: health.status === 'healthy' ? 200 : 503,
    body: JSON.stringify(health)
  };
};
```

### Usage Analytics Dashboard

**Daily Metrics Collection**:
```javascript
// src/jobs/collectMetrics.js
const collectDailyMetrics = async () => {
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  
  const metrics = {
    date: today,
    totalUsers: await User.countDocuments(),
    activeUsers: await User.countDocuments({
      lastLoginAt: { $gte: today }
    }),
    voiceQueries: await Conversation.countDocuments({
      timestamp: { $gte: today }
    }),
    diseaseDetections: await Diagnosis.countDocuments({
      timestamp: { $gte: today }
    }),
    priceChecks: await PriceQuery.countDocuments({
      timestamp: { $gte: today }
    }),
    bedrockTokens: await Conversation.aggregate([
      { $match: { timestamp: { $gte: today } } },
      { $group: { _id: null, total: { $sum: '$tokensUsed' } } }
    ]),
    visionApiCalls: await Diagnosis.countDocuments({
      timestamp: { $gte: today },
      cached: false
    }),
    errorRate: await calculateErrorRate(today)
  };
  
  await UsageMetrics.create(metrics);
  
  // Check free tier limits
  await checkFreeTierLimits(metrics);
};

const checkFreeTierLimits = async (metrics) => {
  const alerts = [];
  
  if (metrics.bedrockTokens > 8000) {
    alerts.push('Bedrock tokens at 80% of free tier limit');
  }
  
  if (metrics.visionApiCalls > 800) {
    alerts.push('Vision API calls at 80% of free tier limit');
  }
  
  if (alerts.length > 0) {
    await sendAdminAlert(alerts);
  }
};
```

### Performance Monitoring

**Request Tracing**:
```javascript
// src/middleware/tracing.js
const { v4: uuidv4 } = require('uuid');

const tracingMiddleware = (req, res, next) => {
  const traceId = uuidv4();
  req.traceId = traceId;
  
  const startTime = Date.now();
  
  res.on('finish', () => {
    const duration = Date.now() - startTime;
    
    logger.info('Request completed', {
      traceId,
      method: req.method,
      path: req.path,
      statusCode: res.statusCode,
      duration,
      userId: req.user?.id
    });
    
    // Publish latency metric
    publishMetric(`${req.path.replace(/\//g, '_')}_Latency`, duration, 'Milliseconds');
  });
  
  next();
};

module.exports = tracingMiddleware;
```

## Correctness Properties

A property is a characteristic or behavior that should hold true across all valid executions of a system—essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.

### Property Reflection and Consolidation

After analyzing all acceptance criteria, several properties were identified as redundant or could be combined for more comprehensive testing:

- Caching properties (7.1, 7.2, 7.3, 7.4) can be consolidated into a single comprehensive caching property
- Persistence properties (2.8, 3.8, 4.2, 4.5) can be combined into a general persistence property
- Error handling properties (9.1, 9.2, 9.3, 9.4) share common patterns and can be consolidated
- Offline queuing properties (5.3, 5.4) can be combined into a single queuing property
- Language support properties (1.3, 1.7, 2.7, 4.7) can be consolidated

The following properties represent the unique, non-redundant correctness guarantees for the system:

### Voice Assistant Properties

**Property 1: Speech-to-Text Conversion**
*For any* valid audio input in Hindi or English, the Voice_Assistant should successfully convert it to text without data loss.
**Validates: Requirements 1.1**

**Property 2: Language Consistency**
*For any* voice query in a specific language (Hindi or English), the response should be in the same language as the input.
**Validates: Requirements 1.3, 1.7**

**Property 3: Text-to-Speech Generation**
*For any* text response from the AI, the Voice_Assistant should generate corresponding audio output.
**Validates: Requirements 1.4**

**Property 4: Session Context Maintenance**
*For any* sequence of queries within the same session, follow-up questions should have access to previous conversation context.
**Validates: Requirements 1.6**

**Property 5: Offline Voice Query Queuing**
*For any* voice query made while offline, the system should queue it and process it when connectivity is restored.
**Validates: Requirements 1.9, 5.4**

### Disease Detection Properties

**Property 6: Image Format and Size Validation**
*For any* uploaded file, the Disease_Detector should accept JPEG, PNG, or WebP formats up to 5MB and reject all other formats or sizes.
**Validates: Requirements 2.1**

**Property 7: Image Processing Pipeline**
*For any* valid crop image, the system should execute the complete pipeline: compression → Cloudinary upload → Vision API analysis → HuggingFace classification → response generation.
**Validates: Requirements 2.2, 2.3, 2.4**

**Property 8: Diagnosis Response Structure**
*For any* completed disease detection, the response should contain disease name, confidence score, treatments in both Hindi and English, and image URL.
**Validates: Requirements 2.5, 2.7**

**Property 9: Image Hash Caching**
*For any* two images with identical MD5 hashes, the second detection should return cached results without calling Vision API or HuggingFace.
**Validates: Requirements 7.3**

**Property 10: Offline Image Queuing**
*For any* image captured while offline, the system should queue it for upload and processing when connectivity is restored.
**Validates: Requirements 5.3**

### Price Checker Properties

**Property 11: Mandi Price Retrieval**
*For any* valid crop name, the Price_Checker should query the Data.gov.in API and return price data or an empty result.
**Validates: Requirements 3.1**

**Property 12: Price Data Structure**
*For any* price query response, each mandi entry should contain crop name, mandi location, current price, and last updated timestamp.
**Validates: Requirements 3.3**

**Property 13: Staleness Warning**
*For any* price data older than 24 hours, the system should display a staleness warning to the user.
**Validates: Requirements 3.4**

**Property 14: Price Recommendation Generation**
*For any* set of mandi prices, the system should generate exactly one recommendation: "sell now", "hold", or "wait for better prices" based on price trends.
**Validates: Requirements 3.5**

**Property 15: Closest Mandi Identification**
*For any* set of mandis with similar prices (within 5% variance), the system should highlight the mandi closest to the user's location.
**Validates: Requirements 3.11**

**Property 16: Price Data Fallback**
*For any* price query when Data.gov.in API is unavailable, the system should serve cached data with a clear staleness indicator.
**Validates: Requirements 3.7, 9.4**

### Authentication and Profile Properties

**Property 17: User Registration Persistence**
*For any* completed registration with valid data (name, phone, location, crops), a corresponding user record should exist in MongoDB_Store.
**Validates: Requirements 4.2**

**Property 18: Phone-Based Authentication**
*For any* authentication attempt, the system should accept phone numbers without requiring email addresses.
**Validates: Requirements 4.3**

**Property 19: Profile Update Persistence**
*For any* profile update operation, the changes should be immediately reflected in MongoDB_Store.
**Validates: Requirements 4.5**

**Property 20: Password Security**
*For any* stored user credential, the password should be hashed (not plaintext) using bcrypt or equivalent.
**Validates: Requirements 4.6**

### Offline and Synchronization Properties

**Property 21: Offline Mode Detection**
*For any* network connectivity loss, the system should display an offline mode indicator within 2 seconds.
**Validates: Requirements 5.1**

**Property 22: Offline Data Access**
*For any* cached data (diagnoses or prices), users should be able to view it while offline without network calls.
**Validates: Requirements 5.2**

**Property 23: Sync Queue Processing**
*For any* queued requests (voice queries or images) when connectivity is restored, all items should be processed in FIFO order.
**Validates: Requirements 5.5**

**Property 24: Cache Size Limits**
*For any* local cache, the system should maintain at most 10 disease diagnoses and 5 price queries, removing oldest entries when limits are exceeded.
**Validates: Requirements 5.6, 5.7**

**Property 25: Storage Eviction Policy**
*For any* local storage exceeding 50MB, the system should remove oldest cached data first until under the limit.
**Validates: Requirements 5.8**

### Caching and Cost Optimization Properties

**Property 26: Universal Caching Behavior**
*For any* identical request (voice query, disease image hash, or price query) within the cache TTL period, the system should return cached results without calling external APIs.
**Validates: Requirements 7.1, 7.2, 7.3, 7.4**

**Property 27: Cache TTL Enforcement**
*For any* cached item, it should be automatically invalidated after its TTL expires (24h for voice, 7d for disease, 6h for prices).
**Validates: Requirements 7.2, 7.3, 7.4**

**Property 28: Image Compression**
*For any* image upload, the system should compress it before sending to Cloudinary_Storage, reducing size by at least 30%.
**Validates: Requirements 7.7**

**Property 29: Data Retention Policy**
*For any* database record, conversations should be deleted after 30 days, diagnoses after 90 days, and price queries after 30 days.
**Validates: Requirements 7.8**

**Property 30: Usage Metrics Logging**
*For any* API call (Bedrock, Vision, HuggingFace, Data.gov.in), the system should log the usage to MongoDB_Store for monitoring.
**Validates: Requirements 7.9**

**Property 31: Graceful Degradation**
*For any* service that exceeds free tier limits, the system should serve cached responses and notify users of temporary limitations.
**Validates: Requirements 7.10**

### Performance and Throttling Properties

**Property 32: Performance Warning Logging**
*For any* Lambda function execution exceeding 5 seconds, the system should log a performance warning with execution details.
**Validates: Requirements 6.3**

**Property 33: Request Throttling**
*For any* user exceeding rate limits (10/min for voice, 5/min for disease, 20/min for price), subsequent requests should be throttled with 429 status.
**Validates: Requirements 6.4, 8.6**

**Property 34: API Response Compression**
*For any* API response larger than 1KB, the system should compress it using gzip before sending to the client.
**Validates: Requirements 6.9**

### Security Properties

**Property 35: Voice Recording Deletion**
*For any* voice query, raw audio recordings should not exist in storage after transcription is complete.
**Validates: Requirements 8.3**

**Property 36: API Authentication**
*For any* API endpoint request without a valid JWT token, the system should return 401 Unauthorized.
**Validates: Requirements 8.4**

**Property 37: Input Sanitization**
*For any* user input containing SQL injection patterns, script tags, or malicious code, the system should reject it with a validation error.
**Validates: Requirements 8.5**

**Property 38: Secure Error Messages**
*For any* security error (authentication failure, authorization failure), the error message should not expose sensitive system details like stack traces or database schemas.
**Validates: Requirements 8.7**

**Property 39: Session Timeout**
*For any* user session with no activity for 30 minutes, the system should automatically invalidate the session and require re-authentication.
**Validates: Requirements 8.10**

### Error Handling and Resilience Properties

**Property 40: Localized Error Messages**
*For any* error occurring during a user request, the error message should be in the user's preferred language (Hindi or English).
**Validates: Requirements 9.1**

**Property 41: Service Unavailability Handling**
*For any* external service (Bedrock, Vision API, HuggingFace, Data.gov.in) that is unavailable, the system should provide a user-friendly message and fallback option.
**Validates: Requirements 9.2, 9.3, 9.4**

**Property 42: Database Retry with Exponential Backoff**
*For any* MongoDB connection failure, the system should retry up to 3 times with exponential backoff (1s, 2s, 4s) before failing.
**Validates: Requirements 9.5**

**Property 43: Upload Retry Capability**
*For any* failed image upload to Cloudinary, the system should allow the user to retry or select a different image.
**Validates: Requirements 9.6**

**Property 44: Circuit Breaker Pattern**
*For any* external API that fails 5 consecutive times, the circuit breaker should open and reject requests for 60 seconds before attempting again.
**Validates: Requirements 9.7**

**Property 45: Error Logging**
*For any* error occurrence, the system should log detailed diagnostics including error message, stack trace, user ID, and request context.
**Validates: Requirements 9.8**

**Property 46: App Crash Prevention**
*For any* backend error response, the Flutter app should handle it gracefully without crashing and provide a recovery path.
**Validates: Requirements 9.9**

**Property 47: Timeout Error Handling**
*For any* network request that times out, the system should provide a specific timeout error message with a retry option.
**Validates: Requirements 9.10**

### Monitoring and Analytics Properties

**Property 48: Action Logging**
*For any* user action (voice query, disease detection, price check), the system should log it to MongoDB_Store with timestamp and user ID.
**Validates: Requirements 10.1**

**Property 49: Analytics Tracking**
*For any* user session, the system should track daily active users, feature usage counts, and session duration.
**Validates: Requirements 10.2**

**Property 50: Free Tier Monitoring**
*For any* API call to paid services, the system should update real-time usage counters for free tier monitoring.
**Validates: Requirements 10.3**

**Property 51: Daily Usage Reports**
*For any* completed day, the system should generate a usage report containing API call counts, costs, and key metrics.
**Validates: Requirements 10.4**

**Property 52: Performance Metrics Collection**
*For any* Lambda function invocation, the system should track error rate and response time for monitoring.
**Validates: Requirements 10.5**

**Property 53: Health Check Endpoints**
*For any* health check request, the system should return the status of all backend services (MongoDB, Bedrock, cache).
**Validates: Requirements 10.6**

**Property 54: Popular Items Tracking**
*For any* crop query or disease detection, the system should increment counters to track the most common crops and diseases.
**Validates: Requirements 10.8**

**Property 55: Feedback Collection**
*For any* user interaction, the system should provide an optional feedback mechanism and store submitted feedback.
**Validates: Requirements 10.9**

## Testing Strategy

### Dual Testing Approach

The KrishiAI Mitra testing strategy employs both unit testing and property-based testing as complementary approaches to ensure comprehensive coverage:

- **Unit Tests**: Verify specific examples, edge cases, error conditions, and integration points
- **Property Tests**: Verify universal properties across all inputs through randomization
- **Together**: Unit tests catch concrete bugs in specific scenarios, while property tests verify general correctness across the input space

### Property-Based Testing Framework

**Selected Library**: 
- **Backend (Node.js)**: `fast-check` (v3.15.0)
- **Frontend (Flutter/Dart)**: `test` package with custom property testing utilities

**Configuration**:
```javascript
// Backend: fast-check configuration
const fc = require('fast-check');

// Minimum 100 iterations per property test
const propertyConfig = {
  numRuns: 100,
  verbose: true,
  seed: Date.now(),  // Reproducible with seed
  endOnFailure: false  // Run all iterations
};

// Example property test
describe('Voice Assistant Properties', () => {
  it('Property 2: Language Consistency', () => {
    fc.assert(
      fc.property(
        fc.record({
          query: fc.string({ minLength: 3, maxLength: 500 }),
          language: fc.constantFrom('hi-IN', 'en-US')
        }),
        async ({ query, language }) => {
          const response = await voiceService.processQuery(query, language);
          return response.language === language;
        }
      ),
      propertyConfig
    );
  });
  // Tag: Feature: krishiai-mitra, Property 2: Language Consistency
});
```

**Flutter Property Testing**:
```dart
// Custom property testing utility
class PropertyTest {
  static Future<void> assert<T>(
    Generator<T> generator,
    Future<bool> Function(T) property,
    {int runs = 100}
  ) async {
    for (int i = 0; i < runs; i++) {
      final input = generator.generate();
      final result = await property(input);
      expect(result, isTrue, reason: 'Property failed on input: $input');
    }
  }
}

// Example usage
test('Property 21: Offline Mode Detection', () async {
  await PropertyTest.assert(
    NetworkStateGenerator(),
    (networkState) async {
      await connectivityProvider.simulateNetworkChange(networkState);
      await Future.delayed(Duration(seconds: 2));
      return connectivityProvider.isOfflineModeVisible == !networkState.isConnected;
    },
    runs: 100
  );
  // Tag: Feature: krishiai-mitra, Property 21: Offline Mode Detection
});
```

### Unit Testing Strategy

**Backend Unit Tests** (Jest):
```javascript
// src/tests/unit/voiceController.test.js
describe('Voice Controller', () => {
  describe('handleVoiceQuery', () => {
    it('should return cached response for identical query', async () => {
      const query = 'Test agricultural question';
      const language = 'en-US';
      
      // First call - cache miss
      const response1 = await voiceController.handleVoiceQuery({
        body: { query, language, userId: 'test-user' }
      });
      
      // Second call - cache hit
      const response2 = await voiceController.handleVoiceQuery({
        body: { query, language, userId: 'test-user' }
      });
      
      expect(response2.data.cached).toBe(true);
      expect(response2.data.answer).toBe(response1.data.answer);
    });
    
    it('should handle Bedrock service unavailability', async () => {
      bedrockService.generateResponse = jest.fn().mockRejectedValue(
        new Error('Service unavailable')
      );
      
      const response = await voiceController.handleVoiceQuery({
        body: { query: 'Test', language: 'en-US', userId: 'test-user' }
      });
      
      expect(response.statusCode).toBe(500);
      expect(response.body.error.message).toContain('unavailable');
    });
    
    it('should reject queries exceeding rate limit', async () => {
      const userId = 'test-user';
      
      // Make 10 requests (at limit)
      for (let i = 0; i < 10; i++) {
        await voiceController.handleVoiceQuery({
          body: { query: `Query ${i}`, language: 'en-US', userId }
        });
      }
      
      // 11th request should be throttled
      const response = await voiceController.handleVoiceQuery({
        body: { query: 'Query 11', language: 'en-US', userId }
      });
      
      expect(response.statusCode).toBe(429);
    });
  });
});
```

**Flutter Unit Tests**:
```dart
// test/providers/voice_provider_test.dart
void main() {
  group('VoiceProvider', () {
    late VoiceProvider provider;
    late MockVoiceService mockService;
    
    setUp(() {
      mockService = MockVoiceService();
      provider = VoiceProvider(service: mockService);
    });
    
    test('should add conversation to list after successful query', () async {
      final mockResponse = Conversation(
        query: 'Test query',
        answer: 'Test answer',
        language: 'en-US',
      );
      
      when(mockService.sendQuery(any, any))
          .thenAnswer((_) async => mockResponse);
      
      await provider.sendVoiceQuery('Test query', 'en-US');
      
      expect(provider.conversations.length, 1);
      expect(provider.conversations.first.query, 'Test query');
    });
    
    test('should set error state when service fails', () async {
      when(mockService.sendQuery(any, any))
          .thenThrow(Exception('Network error'));
      
      await provider.sendVoiceQuery('Test query', 'en-US');
      
      expect(provider.error, isNotNull);
      expect(provider.isLoading, false);
    });
  });
}
```

### Integration Testing

**API Integration Tests**:
```javascript
// src/tests/integration/disease-detection.test.js
describe('Disease Detection Integration', () => {
  it('should complete full disease detection pipeline', async () => {
    const imageBuffer = fs.readFileSync('test/fixtures/tomato-leaf.jpg');
    
    const response = await request(app)
      .post('/api/disease/detect')
      .set('Authorization', `Bearer ${testToken}`)
      .attach('image', imageBuffer, 'tomato-leaf.jpg')
      .field('userId', testUserId)
      .field('language', 'en-US');
    
    expect(response.status).toBe(200);
    expect(response.body.data).toHaveProperty('diseaseName');
    expect(response.body.data).toHaveProperty('confidence');
    expect(response.body.data).toHaveProperty('treatments');
    expect(response.body.data.treatments).toHaveProperty('en');
    expect(response.body.data.treatments).toHaveProperty('hi');
    
    // Verify database record
    const diagnosis = await Diagnosis.findById(response.body.data.diagnosisId);
    expect(diagnosis).toBeDefined();
    expect(diagnosis.userId.toString()).toBe(testUserId);
  });
  
  it('should serve cached result for identical image', async () => {
    const imageBuffer = fs.readFileSync('test/fixtures/wheat-leaf.jpg');
    
    // First request
    const response1 = await request(app)
      .post('/api/disease/detect')
      .set('Authorization', `Bearer ${testToken}`)
      .attach('image', imageBuffer, 'wheat-leaf.jpg')
      .field('userId', testUserId);
    
    // Second request with same image
    const response2 = await request(app)
      .post('/api/disease/detect')
      .set('Authorization', `Bearer ${testToken}`)
      .attach('image', imageBuffer, 'wheat-leaf.jpg')
      .field('userId', testUserId);
    
    expect(response2.body.data.cached).toBe(true);
    expect(response2.body.data.diseaseName).toBe(response1.body.data.diseaseName);
  });
});
```

**Flutter Integration Tests**:
```dart
// integration_test/disease_detection_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  group('Disease Detection Flow', () {
    testWidgets('should complete full disease detection flow', (tester) async {
      await tester.pumpWidget(MyApp());
      
      // Navigate to disease detection screen
      await tester.tap(find.text('Disease Detection'));
      await tester.pumpAndSettle();
      
      // Tap camera button
      await tester.tap(find.byIcon(Icons.camera_alt));
      await tester.pumpAndSettle();
      
      // Wait for image processing
      await tester.pump(Duration(seconds: 10));
      
      // Verify diagnosis card appears
      expect(find.byType(DiagnosisCard), findsOneWidget);
      expect(find.textContaining('Confidence:'), findsOneWidget);
      expect(find.textContaining('Treatment:'), findsOneWidget);
    });
  });
}
```

### Test Coverage Goals

**Backend Coverage Targets**:
- Overall: 80% line coverage
- Controllers: 90% coverage
- Services: 85% coverage
- Models: 95% coverage
- Utilities: 80% coverage

**Frontend Coverage Targets**:
- Overall: 75% line coverage
- Providers: 85% coverage
- Services: 80% coverage
- Widgets: 70% coverage
- Models: 90% coverage

### Test Execution

**Backend Test Commands**:
```bash
# Run all tests
npm test

# Run unit tests only
npm run test:unit

# Run integration tests only
npm run test:integration

# Run property tests only
npm run test:property

# Run with coverage
npm run test:coverage

# Run specific test file
npm test -- src/tests/unit/voiceController.test.js
```

**Flutter Test Commands**:
```bash
# Run all tests
flutter test

# Run unit tests
flutter test test/unit

# Run widget tests
flutter test test/widget

# Run integration tests
flutter test integration_test

# Run with coverage
flutter test --coverage

# Run specific test
flutter test test/providers/voice_provider_test.dart
```

### Continuous Integration

**GitHub Actions Workflow** (`.github/workflows/test.yml`):
```yaml
name: Test Suite

on: [push, pull_request]

jobs:
  backend-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: '18'
      - run: npm install
      - run: npm run test:coverage
      - uses: codecov/codecov-action@v3
  
  frontend-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.16.0'
      - run: flutter pub get
      - run: flutter test --coverage
      - uses: codecov/codecov-action@v3
```

### Test Data Management

**Test Fixtures**:
```javascript
// src/tests/fixtures/index.js
module.exports = {
  users: {
    testUser: {
      phoneNumber: '+919876543210',
      name: 'Test Farmer',
      location: { state: 'Punjab', district: 'Ludhiana' },
      primaryCrops: ['Wheat', 'Rice']
    }
  },
  
  conversations: {
    hindiQuery: {
      query: 'Mere gehun ki patti peeli kyu ho rahi hai?',
      language: 'hi-IN'
    },
    englishQuery: {
      query: 'Why are my wheat leaves turning yellow?',
      language: 'en-US'
    }
  },
  
  images: {
    tomatoLeaf: 'test/fixtures/images/tomato-leaf.jpg',
    wheatLeaf: 'test/fixtures/images/wheat-leaf.jpg',
    invalidFormat: 'test/fixtures/images/test.pdf'
  }
};
```

### Mocking Strategy

**External Service Mocks**:
```javascript
// src/tests/mocks/bedrockService.js
class MockBedrockService {
  async generateResponse(query, language) {
    return {
      answer: `Mock answer for: ${query}`,
      tokensUsed: 100
    };
  }
}

// src/tests/mocks/visionService.js
class MockVisionService {
  async analyzeImage(imageBuffer) {
    return {
      labels: [
        { description: 'Leaf', score: 0.98 },
        { description: 'Plant disease', score: 0.85 }
      ]
    };
  }
}
```

### Performance Testing

**Load Testing** (using Artillery):
```yaml
# artillery-config.yml
config:
  target: 'https://api.krishiai.com'
  phases:
    - duration: 60
      arrivalRate: 10  # 10 requests per second
scenarios:
  - name: 'Voice Query'
    flow:
      - post:
          url: '/api/voice/query'
          headers:
            Authorization: 'Bearer {{token}}'
          json:
            query: 'Test query'
            language: 'en-US'
            userId: '{{userId}}'
```

**Run Load Tests**:
```bash
artillery run artillery-config.yml
```

### Test Documentation

Each test file should include:
- Clear test descriptions
- Setup and teardown procedures
- Mock data and fixtures
- Expected outcomes
- Property tags for property-based tests

**Example Test Documentation**:
```javascript
/**
 * Voice Controller Unit Tests
 * 
 * Tests the voice query handling logic including:
 * - Caching behavior
 * - Error handling
 * - Rate limiting
 * - Language support
 * 
 * Property Tests:
 * - Property 2: Language Consistency
 * - Property 5: Offline Voice Query Queuing
 * 
 * Dependencies:
 * - bedrockService (mocked)
 * - cacheService (mocked)
 * - MongoDB (test database)
 */
```
