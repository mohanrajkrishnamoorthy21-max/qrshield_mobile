🛡️ QR Shield – Anti-QR Phishing Detection System

# 📌 Overview

QR Shield is a mobile security application designed to detect and prevent QR code-based phishing attacks. It scans QR codes, extracts URLs, and evaluates their safety using a risk scoring engine based on HTTPS validation, domain analysis, and typosquatting detection.

---

## 🚀 Features

- 📷 Real-time QR Code Scanning  
- 🔗 URL Extraction & Validation  
- 🔐 HTTPS / HTTP Security Check  
- 🧠 Domain Analysis  
- ⚠️ Typosquatting Detection  
- 📊 Risk Score Engine (Safe / Suspicious / Dangerous)  
- 📜 Scan History Storage  
- 🌐 Django REST API Integration  

---

## 🧠 How It Works

Scan QR → Extract URL → Analyze Security → Generate Risk Score → Display Result

---

## 📊 Risk Scoring System

| Score Range | Status |
|-------------|--------|
| 0 – 30      | 🟢 Safe |
| 31 – 60     | 🟡 Suspicious |
| 61 – 100    | 🔴 Dangerous |

---

## 🛠️ Tech Stack

### 📱 Frontend
- Flutter (Dart)
- QR Scanner Package
- SQLite (Local Storage)

### 🖥️ Backend
- Django
- Django REST Framework
- Python
