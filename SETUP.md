# Smart Anti-Phishing QR Scanner - Setup Guide

## Quick Start

### 1. Install Dependencies
```bash
cd qrshield_mobile
flutter pub get
```

### 2. Start Django Backend
```bash
cd django_backend
pip install django django-cors-headers
python manage.py runserver 0.0.0.0:8000
```

### 3. Run Flutter App
```bash
flutter run
```

## New Features
- Dark theme with modern UI
- Advanced risk scoring (0-100)
- Detailed explanations
- Scan history
- ML + rule-based detection

## API Response Format
```json
{
  "url": "...",
  "status": "SAFE/SUSPICIOUS/PHISHING",
  "score": 0-100,
  "confidence": 0.0-1.0,
  "reasons": [...],
  "features": {
    "has_https": true/false,
    "has_ip": true/false,
    "long_url": true/false,
    "suspicious_keyword": true/false
  }
}
```

## Risk Scoring
- 0-30: SAFE (green)
- 31-60: SUSPICIOUS (orange)  
- 61-100: PHISHING (red)

## Architecture
```
lib/
├── core/
│   ├── theme/app_theme.dart
│   └── widgets/custom_widgets.dart
├── models/scan_result.dart
├── services/
│   ├── api_service_new.dart
│   └── database_service.dart
└── screens/
    ├── splash_screen.dart
    ├── home_screen_new.dart
    ├── scan_screen_new.dart
    ├── result_screen.dart
    └── history_screen.dart
```

Ready to run!
