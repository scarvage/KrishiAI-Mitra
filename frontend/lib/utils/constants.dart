// Backend base URL — change this to your deployed server address
// For local development use your machine's LAN IP (e.g. http://192.168.1.x:3000)
// For Android emulator use http://10.0.2.2:3000
const String kBackendBaseUrl = 'http://192.168.1.43:3000';

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
