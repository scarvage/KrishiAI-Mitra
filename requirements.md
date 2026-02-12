# Requirements Document: KrishiAI Mitra

## Introduction

KrishiAI Mitra is an AI-powered mobile agriculture assistant designed to empower small and marginal farmers in India with timely, accessible agricultural guidance. The platform addresses a critical gap where 70% of Indian farmers lack access to expert agricultural advice in their local languages. By leveraging cutting-edge AI technologies and free-tier cloud services, KrishiAI Mitra provides three core capabilities: multilingual voice-based agricultural consultation, AI-powered crop disease detection, and real-time market price intelligence.

This hackathon project demonstrates how modern AI can democratize agricultural knowledge, helping farmers make informed decisions about crop health, market timing, and farming practices—all through an intuitive mobile interface that works in Hindi and English.

## Project Vision

To become the trusted digital companion for Indian farmers, providing instant access to agricultural expertise through AI-powered voice assistance, visual disease diagnosis, and market intelligence—bridging the knowledge gap that affects millions of small-scale farmers.

## Glossary

- **KrishiAI_System**: The complete mobile application and backend infrastructure
- **Voice_Assistant**: The multilingual conversational AI component powered by Amazon Bedrock
- **Disease_Detector**: The image analysis component that identifies crop diseases
- **Price_Checker**: The market intelligence component that provides mandi price data
- **Farmer_User**: The primary end user - small or marginal farmers in India
- **Mandi**: Traditional Indian agricultural marketplace
- **Bedrock_Service**: Amazon Bedrock AI service using Claude model
- **Vision_API**: Google Cloud Vision API for image analysis
- **HuggingFace_Model**: Hugging Face Inference API for disease classification
- **Lambda_Function**: AWS Lambda serverless compute functions
- **MongoDB_Store**: MongoDB Atlas database instance
- **Cloudinary_Storage**: Cloudinary cloud storage for images
- **Flutter_App**: Cross-platform mobile application built with Flutter
- **Free_Tier**: Cloud service usage within free tier limits

## Tech Stack Specification

### Frontend
- **Flutter**: 3.16.0 or higher
- **Dart**: 3.2.0 or higher
- **Key Packages**:
  - `speech_to_text`: ^6.3.0 (voice input)
  - `flutter_tts`: ^3.8.0 (text-to-speech output)
  - `image_picker`: ^1.0.4 (camera/gallery access)
  - `http`: ^1.1.0 (API communication)
  - `provider`: ^6.1.0 (state management)
  - `shared_preferences`: ^2.2.2 (local storage)

### Backend
- **Node.js**: 18.x LTS
- **Runtime**: AWS Lambda (Node.js 18.x)
- **Key Packages**:
  - `@aws-sdk/client-bedrock-runtime`: ^3.450.0
  - `@google-cloud/vision`: ^4.0.0
  - `axios`: ^1.6.0
  - `mongoose`: ^8.0.0
  - `dotenv`: ^16.3.0

### AI Services
- **Amazon Bedrock**: Claude 3 Haiku (free tier: 10K tokens/month)
- **Google Cloud Vision API**: (free tier: 1000 requests/month)
- **Hugging Face Inference API**: Free tier with rate limits

### Infrastructure
- **Database**: MongoDB Atlas M0 (free tier: 512MB storage)
- **Storage**: Cloudinary Free (25 credits/month, ~25GB bandwidth)
- **Compute**: AWS Lambda (free tier: 1M requests/month, 400K GB-seconds)
- **API Gateway**: AWS API Gateway (free tier: 1M requests/month)

## Requirements

### Requirement 1: Multilingual Voice Assistant

**User Story:** As a farmer, I want to ask agricultural questions in my native language using voice, so that I can get instant expert advice without typing or reading complex text.

#### Acceptance Criteria

1. WHEN a Farmer_User speaks a question in Hindi or English, THE Voice_Assistant SHALL capture the audio and convert it to text
2. WHEN the voice input is converted to text, THE Voice_Assistant SHALL send the query to Bedrock_Service for processing
3. WHEN Bedrock_Service processes the query, THE Voice_Assistant SHALL return a contextually relevant agricultural answer in the same language
4. WHEN an answer is generated, THE Voice_Assistant SHALL convert the text response to speech and play it to the Farmer_User
5. IF the voice input is unclear or contains excessive background noise, THEN THE Voice_Assistant SHALL prompt the Farmer_User to repeat the question
6. WHEN a conversation session is active, THE Voice_Assistant SHALL maintain context for follow-up questions within the same session
7. THE Voice_Assistant SHALL support both Hindi and English language inputs and outputs
8. WHEN the Bedrock_Service free tier limit is approached, THE KrishiAI_System SHALL notify administrators and gracefully degrade to cached responses
9. WHEN network connectivity is unavailable, THE Voice_Assistant SHALL inform the Farmer_User and queue the question for later processing
10. THE Voice_Assistant SHALL respond to queries within 5 seconds under normal network conditions

### Requirement 2: Crop Disease Detection

**User Story:** As a farmer, I want to upload a photo of my diseased crop and receive an instant diagnosis, so that I can take timely action to prevent crop loss.

#### Acceptance Criteria

1. WHEN a Farmer_User captures or selects a crop image, THE Disease_Detector SHALL accept images in JPEG, PNG, or WebP formats up to 5MB
2. WHEN an image is uploaded, THE Disease_Detector SHALL compress and upload it to Cloudinary_Storage
3. WHEN the image is stored, THE Disease_Detector SHALL send it to Vision_API for initial analysis and feature extraction
4. WHEN Vision_API completes analysis, THE Disease_Detector SHALL send the processed features to HuggingFace_Model for disease classification
5. WHEN disease classification is complete, THE Disease_Detector SHALL return the disease name, confidence score, and recommended treatments
6. IF the confidence score is below 60 percent, THEN THE Disease_Detector SHALL suggest the Farmer_User capture a clearer image or consult an expert
7. WHEN a disease is detected, THE Disease_Detector SHALL provide treatment recommendations in both Hindi and English
8. THE Disease_Detector SHALL store the diagnosis history in MongoDB_Store for future reference
9. WHEN Vision_API or HuggingFace_Model free tier limits are reached, THE Disease_Detector SHALL notify the Farmer_User and suggest retry timing
10. THE Disease_Detector SHALL complete the entire diagnosis process within 10 seconds under normal conditions
11. WHEN the image quality is insufficient for analysis, THE Disease_Detector SHALL provide specific guidance on capturing better images

### Requirement 3: Real-time Mandi Price Checker

**User Story:** As a farmer, I want to check current market prices for my crops across different mandis, so that I can decide the best time and place to sell my produce.

#### Acceptance Criteria

1. WHEN a Farmer_User searches for a crop name, THE Price_Checker SHALL query the Data.gov.in API for current mandi prices
2. WHEN price data is retrieved, THE Price_Checker SHALL display prices from at least 5 nearby mandis sorted by distance
3. WHEN displaying prices, THE Price_Checker SHALL show the crop name, mandi location, current price, and last updated timestamp
4. WHEN price data is older than 24 hours, THE Price_Checker SHALL display a staleness warning to the Farmer_User
5. WHEN analyzing price trends, THE Price_Checker SHALL provide a simple recommendation: sell now, hold, or wait for better prices
6. THE Price_Checker SHALL support searching for at least 20 common crops including wheat, rice, cotton, sugarcane, and vegetables
7. WHEN the Data.gov.in API is unavailable, THE Price_Checker SHALL serve cached price data with a clear timestamp
8. THE Price_Checker SHALL cache price data in MongoDB_Store for offline access
9. WHEN displaying prices, THE Price_Checker SHALL show price trends using simple visual indicators
10. THE Price_Checker SHALL complete price queries within 3 seconds under normal network conditions
11. WHEN multiple mandis have similar prices, THE Price_Checker SHALL highlight the closest mandi by distance

### Requirement 4: User Authentication and Profile Management

**User Story:** As a farmer, I want to create a profile with my location and primary crops, so that the app can provide personalized recommendations.

#### Acceptance Criteria

1. WHEN a new Farmer_User opens the app, THE KrishiAI_System SHALL provide a simple registration flow requiring name, phone number, location, and primary crops
2. WHEN registration is complete, THE KrishiAI_System SHALL store the user profile in MongoDB_Store
3. THE KrishiAI_System SHALL support phone number-based authentication without requiring email addresses
4. WHEN a Farmer_User logs in, THE KrishiAI_System SHALL retrieve their profile and personalize recommendations based on location and crops
5. WHEN a Farmer_User updates their profile, THE KrishiAI_System SHALL persist changes to MongoDB_Store immediately
6. THE KrishiAI_System SHALL store user credentials securely using industry-standard hashing
7. WHEN authentication fails, THE KrishiAI_System SHALL provide clear error messages in the user's preferred language

### Requirement 5: Offline Capability and Data Synchronization

**User Story:** As a farmer in a rural area with intermittent connectivity, I want to access previously loaded information offline, so that I can still benefit from the app when network is unavailable.

#### Acceptance Criteria

1. WHEN the Flutter_App detects no network connectivity, THE KrishiAI_System SHALL display an offline mode indicator
2. WHILE offline, THE KrishiAI_System SHALL allow Farmer_Users to view previously cached disease diagnoses and price data
3. WHEN a Farmer_User captures an image while offline, THE KrishiAI_System SHALL queue it for upload when connectivity is restored
4. WHEN a Farmer_User asks a voice question while offline, THE KrishiAI_System SHALL queue it and notify them it will be processed when online
5. WHEN connectivity is restored, THE KrishiAI_System SHALL automatically sync queued requests and update cached data
6. THE KrishiAI_System SHALL cache the last 10 disease diagnoses locally on the device
7. THE KrishiAI_System SHALL cache the last 5 price queries locally on the device
8. WHEN local storage exceeds 50MB, THE KrishiAI_System SHALL remove oldest cached data first

### Requirement 6: Performance and Scalability

**User Story:** As a system administrator, I want the application to handle multiple concurrent users efficiently within free tier limits, so that we can serve maximum farmers without incurring costs.

#### Acceptance Criteria

1. THE Lambda_Functions SHALL execute within 3 seconds for 95 percent of requests
2. THE Lambda_Functions SHALL be configured with 512MB memory allocation for optimal cost-performance ratio
3. WHEN Lambda_Function execution time exceeds 5 seconds, THE KrishiAI_System SHALL log a performance warning
4. THE KrishiAI_System SHALL implement request throttling to stay within free tier limits
5. WHEN free tier limits are approached at 80 percent, THE KrishiAI_System SHALL send alerts to administrators
6. THE MongoDB_Store SHALL maintain response times under 100ms for 95 percent of queries
7. THE KrishiAI_System SHALL implement database connection pooling to optimize MongoDB_Store connections
8. THE Flutter_App SHALL load the home screen within 2 seconds on devices with 2GB RAM or higher
9. THE KrishiAI_System SHALL compress all API responses to minimize data transfer costs
10. WHEN concurrent users exceed 100, THE KrishiAI_System SHALL implement request queuing to prevent service degradation

### Requirement 7: Cost Optimization and Free Tier Management

**User Story:** As a project owner, I want to maximize usage within free tier limits, so that the hackathon project remains cost-free while serving maximum users.

#### Acceptance Criteria

1. THE KrishiAI_System SHALL implement aggressive caching to minimize API calls to Bedrock_Service, Vision_API, and HuggingFace_Model
2. THE KrishiAI_System SHALL cache identical voice queries for 24 hours to reduce Bedrock_Service token usage
3. THE KrishiAI_System SHALL cache disease detection results for identical image hashes to reduce Vision_API calls
4. THE KrishiAI_System SHALL cache mandi price data for 6 hours to reduce Data.gov.in API calls
5. WHEN any service approaches 90 percent of free tier limit, THE KrishiAI_System SHALL implement rate limiting for new requests
6. THE Lambda_Functions SHALL be configured with minimum memory and timeout values to optimize GB-seconds usage
7. THE KrishiAI_System SHALL implement image compression before uploading to Cloudinary_Storage to stay within bandwidth limits
8. THE MongoDB_Store SHALL implement data retention policies to stay within 512MB storage limit
9. THE KrishiAI_System SHALL log all API usage metrics to MongoDB_Store for monitoring
10. WHEN free tier limits are exceeded, THE KrishiAI_System SHALL gracefully degrade to cached responses with user notification

### Requirement 8: Security and Data Privacy

**User Story:** As a farmer, I want my personal information and farm data to be secure, so that I can trust the application with sensitive information.

#### Acceptance Criteria

1. THE KrishiAI_System SHALL encrypt all data in transit using TLS 1.2 or higher
2. THE KrishiAI_System SHALL encrypt sensitive user data at rest in MongoDB_Store
3. THE KrishiAI_System SHALL not store raw voice recordings after transcription is complete
4. THE KrishiAI_System SHALL implement API authentication using secure tokens for all Lambda_Function endpoints
5. THE KrishiAI_System SHALL validate and sanitize all user inputs to prevent injection attacks
6. THE KrishiAI_System SHALL implement rate limiting per user to prevent abuse
7. WHEN a security error occurs, THE KrishiAI_System SHALL log the incident without exposing sensitive details to the user
8. THE KrishiAI_System SHALL comply with Indian data protection regulations for agricultural data
9. THE Cloudinary_Storage SHALL be configured with private access controls for uploaded images
10. THE KrishiAI_System SHALL implement session timeout after 30 minutes of inactivity

### Requirement 9: Error Handling and Resilience

**User Story:** As a farmer, I want the app to handle errors gracefully and provide clear guidance, so that I can understand what went wrong and how to proceed.

#### Acceptance Criteria

1. WHEN any Lambda_Function encounters an error, THE KrishiAI_System SHALL return a user-friendly error message in the Farmer_User's preferred language
2. WHEN Bedrock_Service is unavailable, THE Voice_Assistant SHALL inform the Farmer_User and suggest trying again later
3. WHEN Vision_API or HuggingFace_Model fails, THE Disease_Detector SHALL provide fallback suggestions and allow retry
4. WHEN Data.gov.in API is unavailable, THE Price_Checker SHALL serve cached data with a clear staleness indicator
5. IF MongoDB_Store connection fails, THEN THE KrishiAI_System SHALL retry the connection up to 3 times with exponential backoff
6. WHEN image upload to Cloudinary_Storage fails, THE Disease_Detector SHALL allow the Farmer_User to retry or select a different image
7. THE KrishiAI_System SHALL implement circuit breaker patterns for all external API calls
8. WHEN multiple errors occur in sequence, THE KrishiAI_System SHALL log detailed diagnostics for debugging
9. THE Flutter_App SHALL never crash due to backend errors and SHALL always provide a recovery path
10. WHEN network requests timeout, THE KrishiAI_System SHALL provide specific timeout error messages with retry options

### Requirement 10: Monitoring and Analytics

**User Story:** As a project administrator, I want to track usage patterns and system health, so that I can optimize the application and demonstrate impact.

#### Acceptance Criteria

1. THE KrishiAI_System SHALL log all voice queries, disease detections, and price checks to MongoDB_Store
2. THE KrishiAI_System SHALL track daily active users, feature usage, and session duration
3. THE KrishiAI_System SHALL monitor free tier usage for all cloud services in real-time
4. THE KrishiAI_System SHALL generate daily usage reports showing API call counts and costs
5. THE KrishiAI_System SHALL track error rates and response times for all Lambda_Functions
6. THE KrishiAI_System SHALL implement health check endpoints for all backend services
7. WHEN error rates exceed 5 percent, THE KrishiAI_System SHALL send alerts to administrators
8. THE KrishiAI_System SHALL track the most common crops queried and diseases detected
9. THE KrishiAI_System SHALL measure user satisfaction through optional feedback after each interaction
10. THE KrishiAI_System SHALL provide a dashboard showing key metrics: total users, queries processed, diseases detected, and cost savings

## Non-Functional Requirements

### Performance
- Voice query response time: < 5 seconds (95th percentile)
- Disease detection processing: < 10 seconds (95th percentile)
- Price query response time: < 3 seconds (95th percentile)
- App launch time: < 2 seconds on mid-range devices
- API response time: < 1 second for cached data

### Scalability
- Support 1000+ concurrent users within free tier limits
- Handle 10,000+ daily API requests across all features
- Scale Lambda functions automatically based on demand
- Implement request queuing for burst traffic

### Reliability
- System uptime: 99% during hackathon demo period
- Graceful degradation when services are unavailable
- Automatic retry with exponential backoff for failed requests
- Circuit breaker implementation for external APIs

### Usability
- Simple, intuitive UI requiring minimal training
- Support for Hindi and English throughout the app
- Voice-first interface for low-literacy users
- Clear visual feedback for all actions
- Accessibility support for visually impaired users

### Maintainability
- Modular architecture with clear separation of concerns
- Comprehensive error logging and monitoring
- Environment-based configuration management
- Clear documentation for all APIs and components

### Compatibility
- Android 8.0 (API level 26) or higher
- iOS 12.0 or higher
- Support for devices with 2GB RAM minimum
- Work on screen sizes from 4.5" to 7" tablets

## Success Metrics

### Technical Metrics
- 95% of voice queries processed successfully
- 90% of disease detections completed with confidence > 60%
- 100% of price queries return data (cached or live)
- Zero cost overruns beyond free tier limits
- < 2% error rate across all features
- Average response time < 5 seconds

### Impact Metrics
- 100+ farmers onboarded during hackathon demo
- 500+ voice queries processed
- 200+ disease detections performed
- 300+ price checks completed
- 80%+ user satisfaction rating
- Demonstrate 50% time savings vs traditional methods

## AWS Services Usage Table

| Service | Purpose | Free Tier Limit | Expected Usage | Buffer |
|---------|---------|-----------------|----------------|--------|
| AWS Lambda | Backend compute | 1M requests/month, 400K GB-seconds | 10K requests (demo) | 99% available |
| API Gateway | REST API endpoints | 1M requests/month | 10K requests (demo) | 99% available |
| Amazon Bedrock | AI voice assistant | 10K tokens/month (Claude Haiku) | 5K tokens (demo) | 50% available |
| CloudWatch Logs | Logging & monitoring | 5GB ingestion, 5GB storage | 500MB (demo) | 90% available |

## External Services Usage

| Service | Purpose | Free Tier Limit | Expected Usage |
|---------|---------|-----------------|----------------|
| Google Cloud Vision | Image analysis | 1000 requests/month | 200 requests (demo) |
| Hugging Face API | Disease classification | Rate limited (free) | 200 requests (demo) |
| MongoDB Atlas | Database | 512MB storage | 50MB (demo) |
| Cloudinary | Image storage | 25 credits/month (~25GB) | 5 credits (demo) |
| Data.gov.in API | Mandi prices | Public API (no limit) | Unlimited with caching |

## Risk Mitigation Strategies

### Risk 1: Free Tier Exhaustion
- **Mitigation**: Aggressive caching, request throttling, usage monitoring
- **Fallback**: Graceful degradation to cached responses

### Risk 2: API Rate Limits
- **Mitigation**: Implement exponential backoff, request queuing
- **Fallback**: Serve cached data with staleness indicators

### Risk 3: Poor Network Connectivity
- **Mitigation**: Offline mode, local caching, request queuing
- **Fallback**: Inform users and queue requests for sync

### Risk 4: Low Image Quality
- **Mitigation**: Image quality validation, user guidance
- **Fallback**: Request better image or suggest expert consultation

### Risk 5: Inaccurate AI Responses
- **Mitigation**: Confidence scoring, human-in-the-loop for low confidence
- **Fallback**: Disclaimer and expert consultation suggestion

### Risk 6: Language Barriers
- **Mitigation**: Support Hindi and English, voice-first interface
- **Fallback**: Visual indicators and simple language

## Development Timeline (2-Day Hackathon)

### Day 1 (8 hours)
- **Hours 0-2**: Project setup, AWS/GCP account configuration, Flutter project initialization
- **Hours 2-4**: Backend Lambda functions for all three features (skeleton)
- **Hours 4-6**: Flutter UI for home screen and voice assistant
- **Hours 6-8**: Integrate Bedrock API, test voice assistant end-to-end

### Day 2 (8 hours)
- **Hours 0-2**: Disease detection UI and Vision API integration
- **Hours 2-4**: Price checker UI and Data.gov.in API integration
- **Hours 4-6**: Testing, bug fixes, offline mode implementation
- **Hours 6-8**: Demo preparation, presentation deck, video recording

## Out of Scope

The following items are explicitly out of scope for this hackathon project:

1. **Payment Integration**: No in-app purchases or premium features
2. **Social Features**: No farmer community, forums, or social sharing
3. **Weather Integration**: No weather forecasts or alerts
4. **Soil Testing**: No soil analysis or recommendations
5. **Crop Planning**: No seasonal planning or crop rotation advice
6. **Marketplace**: No direct buying/selling of crops
7. **Expert Consultation**: No live video/chat with agricultural experts
8. **IoT Integration**: No sensor data or smart farming devices
9. **Government Schemes**: No information about subsidies or schemes
10. **Multi-tenant**: No support for agricultural organizations or cooperatives
11. **Advanced Analytics**: No predictive modeling or ML training
12. **Regional Languages**: Only Hindi and English (no Tamil, Telugu, etc.)
13. **Web Application**: Mobile-only, no web interface
14. **Push Notifications**: No proactive alerts or reminders
15. **Livestock Management**: Focus only on crops, not animals

## Acceptance Criteria Summary

The KrishiAI Mitra project will be considered successful when:

1. All three core features (Voice Assistant, Disease Detection, Price Checker) are functional and demonstrated
2. The application runs on both Android and iOS devices
3. Voice queries in Hindi and English return relevant agricultural advice
4. Disease detection provides diagnosis with confidence scores and treatment recommendations
5. Price checker displays current mandi prices with sell/hold recommendations
6. All features operate within free tier limits with zero cost overruns
7. The application handles offline scenarios gracefully
8. User authentication and profile management work correctly
9. The demo successfully onboards and serves at least 10 test users
10. All critical user journeys complete without crashes or blocking errors
11. The codebase is documented and deployable by following README instructions
12. A working demo video showcases all three features in action

## Appendix: Sample User Journeys

### Journey 1: First-Time Farmer User
1. Download and install KrishiAI Mitra app
2. Register with phone number, location (Punjab), and primary crop (wheat)
3. Ask voice question: "Mere gehun ki patti peeli kyu ho rahi hai?" (Why are my wheat leaves turning yellow?)
4. Receive AI response with possible causes and solutions
5. Capture photo of affected wheat plant
6. Receive disease diagnosis: Nitrogen deficiency, 85% confidence
7. View treatment recommendations in Hindi
8. Check current wheat prices in nearby mandis
9. Receive recommendation: Hold for 1 week, prices trending upward

### Journey 2: Experienced User with Poor Connectivity
1. Open app in area with intermittent network
2. View previously cached disease diagnoses
3. Capture new crop image while offline
4. Receive notification that image will be processed when online
5. Move to area with connectivity
6. App automatically uploads queued image
7. Receive disease diagnosis notification
8. Check cached mandi prices from yesterday with staleness warning

### Journey 3: Disease Detection Power User
1. Open app and navigate to disease detection
2. Capture image of tomato plant with spots
3. Receive diagnosis: Early Blight, 92% confidence
4. View detailed treatment recommendations
5. Save diagnosis to history
6. Ask voice follow-up: "Early blight ka ilaj kaise kare?" (How to treat early blight?)
7. Receive detailed voice response with treatment steps
8. Check history to compare with previous diagnosis from last week
