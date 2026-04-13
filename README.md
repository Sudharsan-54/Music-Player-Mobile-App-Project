# Jazz Music Player

A powerful, cross-platform music player built with Flutter, designed to handle high-quality audio formats and extract audio from video files.

## 🎵 Features

- **Multi-format Support**: Play MP3, FLAC, ALAC, and more.
- **Video-to-Audio Extraction**: Easily convert and extract audio from video files using FFmpeg.
- **Background Playback**: Full support for background audio control via `audio_service`.
- **Metadata Support**: Automatic extraction of album art, artist, and title metadata using `audiotags`.
- **Local Library Management**: Organized local database powered by `sqflite` for fast and offline access.
- **State Management**: Robust and scalable state management using `Riverpod`.
- **Responsive UI**: Dark-themed, modern interface built with Flutter's Material Design.

## 🛠️ Architecture & Tech Stack

The project follows a modular architecture for better maintainability and scalability.

- **Framework**: [Flutter](https://flutter.dev)
- **State Management**: [Riverpod](https://riverpod.dev)
- **Navigation**: [GoRouter](https://pub.dev/packages/go_router)
- **Audio Engine**: [just_audio](https://pub.dev/packages/just_audio) & [audio_service](https://pub.dev/packages/audio_service)
- **Media Conversion**: [ffmpeg_kit_flutter](https://pub.dev/packages/ffmpeg_kit_flutter)
- **Local Storage**: [sqflite](https://pub.dev/packages/sqflite)
- **Theming**: Custom dark theme with flexible UI components.

## 📂 Project Structure

```text
lib/
├── core/          # Core utilities, services (MusicHandler), and themes
├── database/      # SQLite database configuration and DAO
├── features/      # Feature-specific logic and UI
├── models/        # Data models for tracks, playlists, etc.
├── providers/     # Global Riverpod providers
├── routing/       # App routing configuration (GoRouter)
├── services/      # Business logic and external API services
├── views/         # Shared UI components and screens
└── main.dart      # Application entry point
```

## 🚀 Getting Started

### Prerequisites

- Flutter SDK: `^3.7.0`
- Android Studio / VS Code
- Git

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/your-username/jazz_music.git
   cd jazz_music
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run the application:**
   ```bash
   flutter run
   ```




## 📲 Sharing & Distribution

### Android (Direct Share)
To share the app with others for testing on Android:
1. Generate a release APK:
   ```bash
   flutter build apk --release
   ```
2. Locate the file at: `build/app/outputs/flutter-apk/app-release.apk`
3. Send this APK file to any Android device to install it.

### iOS (Testing)
To share on iOS, you typically use Apple's official channels:
- **TestFlight**: Upload your build to App Store Connect to invite external testers.
- **Physical Device**: Connect an iPhone to your Mac and run `flutter run --release`.

### App Stores
For official distribution, follow the Flutter deployment guides:
- [Build and release an Android app](https://docs.flutter.dev/deployment/android)
- [Build and release an iOS app](https://docs.flutter.dev/deployment/ios)

## 📱 Platform Support

- [x] Android
- [x] iOS (Native extraction supported via FFmpeg)
- [x] Windows / macOS / Linux (Desktop support via FFI)
- [x] Web (Basic playback support)

## 🤝 Contributing

Contributions are welcome! If you'd like to improve Jazz Music Player, please:

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git checkout -b feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

Distributed under the MIT License. See `LICENSE` for more information.

---
Built with ❤️ using Flutter.
