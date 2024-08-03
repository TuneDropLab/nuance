# Nuance

Welcome to Nuance, a Flutter-based music recommendation application that integrates with Spotify. This application is designed to provide a personalized music experience by generating song recommendations based on user input. 

## Key Features

- **User Authentication**: Nuance uses Spotify for user authentication. This allows us to personalize the user experience and provide recommendations based on the user's Spotify listening history. The authentication process is handled in the [`auth_provider.dart`](lib/providers/auth_provider.dart#L1-L50) file.

- **Music Recommendations**: One of the core features of Nuance is its ability to provide music recommendations. This is achieved by leveraging machine learning algorithms to analyze user input and generate relevant song recommendations. The logic for this feature can be found in the [`home_recommedations_provider.dart`](lib/providers/home_recommedations_provider.dart#L1-L23) and [`recomedation_service.dart`](lib/services/recomedation_service.dart#L1-L400) files.

- **User Profile**: Nuance fetches and displays user profile information from Spotify. This includes the user's name and profile picture. The code for this feature is located in the [`home_screen.dart`](lib/screens/home_screen.dart#L630-L690) file.

## Prerequisites

Before you can run Nuance, you'll need the following installed on your machine:

- Flutter SDK
- Dart
- A Spotify Developer Account

## Setup

To set up Nuance on your local machine, follow these steps:

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

We welcome contributions to Nuance! If you'd like to contribute, please make sure to read the [`CONTRIBUTING.md`](CONTRIBUTING.md) for guidelines.

## License

Nuance is licensed under the MIT License. For more details, see the [`LICENSE.md`](LICENSE.md) file.