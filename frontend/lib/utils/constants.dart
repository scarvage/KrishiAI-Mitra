// ─── Environment Switch ───────────────────────────────────────────────────────
// Set to true  → uses your local dev server
// Set to false → uses the production server URL
const bool kUseLocalServer = true;

// Local dev URLs:
//   Physical device on same WiFi → your machine's LAN IP (find with `ifconfig | grep 192`)
//   Android emulator             → http://10.0.2.2:3000
//   iOS simulator                → http://localhost:3000
const String _kLocalUrl = 'http://192.168.1.3:3000';
const String _kProductionUrl = 'http://52.72.248.60:3000'; // TODO: replace when deployed

const String kBackendBaseUrl = kUseLocalServer ? _kLocalUrl : _kProductionUrl;

// 10 major crops with display names and emoji icons
const List<Map<String, String>> kMajorCrops = [
  {'name': 'Wheat', 'emoji': '🌾', 'hi': 'गेहूं'},
  {'name': 'Rice', 'emoji': '🍚', 'hi': 'चावल'},
  {'name': 'Cotton', 'emoji': '🌿', 'hi': 'कपास'},
  {'name': 'Sugarcane', 'emoji': '🎋', 'hi': 'गन्ना'},
  {'name': 'Maize', 'emoji': '🌽', 'hi': 'मक्का'},
  {'name': 'Soybean', 'emoji': '🫘', 'hi': 'सोयाबीन'},
  {'name': 'Onion', 'emoji': '🧅', 'hi': 'प्याज'},
  {'name': 'Potato', 'emoji': '🥔', 'hi': 'आलू'},
  {'name': 'Tomato', 'emoji': '🍅', 'hi': 'टमाटर'},
  {'name': 'Mustard', 'emoji': '🌻', 'hi': 'सरसों'},
];

// All Indian states and union territories
const List<String> kIndianStates = [
  'Andhra Pradesh',
  'Arunachal Pradesh',
  'Assam',
  'Bihar',
  'Chhattisgarh',
  'Goa',
  'Gujarat',
  'Haryana',
  'Himachal Pradesh',
  'Jharkhand',
  'Karnataka',
  'Kerala',
  'Madhya Pradesh',
  'Maharashtra',
  'Manipur',
  'Meghalaya',
  'Mizoram',
  'Nagaland',
  'Odisha',
  'Punjab',
  'Rajasthan',
  'Sikkim',
  'Tamil Nadu',
  'Telangana',
  'Tripura',
  'Uttar Pradesh',
  'Uttarakhand',
  'West Bengal',
  'Delhi',
  'Jammu and Kashmir',
  'Ladakh',
];
