# fleeting_monitoring_app

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Assumptions
- Device has stable internet access.
- Firestore collection `cars/CAR A` is available.
- Location updates are sent every 5 seconds.
- `google-services.json` and Maps API key are configured.


##Limitations
The core functionality of this Flutter project — real-time car tracking using Firebase and Google Maps — is fully implemented and tested on the web platform. Additionally, the bonus feature of local data storage using Hive has been successfully integrated.

Due to unexpected system-level driver issues, I was unable to complete Android testing before the submission deadline. These issues require a full system format, which is already planned.

For security reasons, my Google Maps API key is not included in the public repository. To run the project locally, users will need to use their own API key and configure it appropriately.

The project follows Flutter’s cross-platform development standards, and the mobile version can be deployed with minimal adjustments once the environment is restored.

To meet the deadline, I prioritized delivering a stable and complete web version. I am fully prepared to finalize and test the Android build as soon as my development setup is back online.

