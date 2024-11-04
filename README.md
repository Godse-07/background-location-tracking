# Location Tracker

A Flutter application that tracks the user's location in real-time using a foreground service. The app periodically updates the user's location and displays the tracked data in a user-friendly interface.

## Features

- **Real-Time Location Tracking**: Continuously tracks the user's location.
- **Foreground Service**: Runs a background service that keeps tracking even when the app is not in the foreground.
- **Notification Updates**: Sends notifications with the current latitude and longitude.
- **Permission Handling**: Manages location permissions and informs the user if permission is denied or permanently denied.
- **Data Table Display**: Displays tracked location data in a structured table format.

## Tech Stack

- Flutter
- Dart
- `geolocator`: For retrieving the user's location.
- `flutter_background_service`: For running background tasks.
- `flutter_local_notifications`: For displaying notifications.
- `permission_handler`: For managing permissions.
- `intl`: For date and time formatting.

## Getting Started

To run this project locally, follow these steps:

### Prerequisites

- Flutter SDK installed on your machine.
- Android Studio or Visual Studio Code for development.
- An Android device or emulator for testing.

### Installation

1. Clone the repository:

   ```bash
   git clone https://github.com/Godse-07/background-location-tracking.git
2. Navigate to the project directory:
 
   ```bash
   cd background-location-tracking
3. Install dependencies:
   
   ```bash
   flutter pub get
4. Run the app:

   ```bash
   flutter run
