# Atmos Mobile App: Weather Meets AI

A pure native mobile application (Android & iOS) delivering seamless weather forecasting paired with an intelligent AI chatbot.

## The "Why"
**What is it?** A beautiful, Flutter-based mobile application that serves as your daily weather guide and smart companion.
**Who is it for?** Anyone who wants quick, accurate weather updates and a conversational AI to help plan their day.
**What are the core features?** 
- Real-time weather forecasting using OpenWeather.
- An intelligent, messenger-style AI chat interface.
- Firebase-backed user conversation history.

## Visuals
*(Screenshot of the mobile app home screen goes here)*

## Getting Started
Ensure you have the Flutter SDK (>= 3.0.0) installed and a mobile emulator (Android/iOS) running or a physical device connected. This is a pure mobile app, not a web app.

### Installation
```bash
git clone https://github.com/yourusername/atmos.git
cd atmos/atmos_frontend
flutter pub get
```

## Usage
Ensure the Atmos backend is running, then launch the mobile app:
```bash
flutter run
```
If you are testing on an Android emulator, ensure your API endpoints point to `10.0.2.2` instead of `localhost`.

## Folder Structure
```text
atmos_frontend/
├── android/        # Android native runner
├── ios/            # iOS native runner
├── lib/            # Dart source code (screens, widgets, API clients)
├── assets/         # Images, fonts, and icons (e.g., cloud_circle.png)
└── pubspec.yaml    # Flutter project configuration
```

## Configuration
The frontend primarily relies on the backend for API keys, but ensure your `lib/config` (if any) points to the correct local or production backend URL.

## Roadmap & Contributing
**Roadmap:**
- Add home screen widgets for iOS/Android.
- Implement push notifications for severe weather alerts.

**Contributing:**
Pull requests are welcome! Feel free to open an issue or submit a PR to help improve the app.

## License & Contact
- **License:** MIT License
- **Contact:** Reach out at charliemangyao@gmail.com.com or find us on Facebook *santino.cc7*.
