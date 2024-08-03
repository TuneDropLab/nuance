# Nuance

Nuance is a Flutter application that integrates with Spotify to provide music recommendations. It uses Spotify's authentication and leverages machine learning to generate song recommendations based on user input.

## Features

- User Authentication: Nuance uses Spotify for user authentication. See [`auth_provider.dart`](lib/providers/auth_provider.dart#L1-L50) for more details.
- Music Recommendations: Nuance provides music recommendations based on user input. See [`home_recommedations_provider.dart`](lib/providers/home_recommedations_provider.dart#L1-L23) and [`recomedation_service.dart`](lib/services/recomedation_service.dart#L1-L400) for more details.
- User Profile: Nuance fetches and displays user profile information. See [`home_screen.dart`](lib/screens/home_screen.dart#L630-L690) for more details.

## Prerequisites

- Flutter SDK
- Dart
- Spotify Developer Account

## Setup

1. Clone the repository: `git clone https://github.com/your-repo/nuance.git`.
2. Navigate to the project directory: `cd nuance`.
3. Install dependencies: `flutter pub get`.

## Running the Application

### Android

1. Update the `build.gradle` file with your Android SDK details and dependencies.
2. Run the application: `flutter run`.

### iOS

1. Update the `Podfile` with your iOS platform version and dependencies.
2. Run the application: `flutter run`.

## Contributing

Contributions are welcome. Please make sure to read the [`CONTRIBUTING.md`](CONTRIBUTING.md) for guidelines.

## License

This project is licensed under the MIT License. See [`LICENSE.md`](LICENSE.md) for more details.