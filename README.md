# Flutter Map Practice

This project implements a Flutter application integrating Kakao Map using a Modular MVC Architecture.

## Getting Started

Because the initial codebase was manually bootstrapped, you need to run the following command to let Flutter generate the missing native platform boilerplate (e.g., Xcode project, Android Gradle files):

```bash
flutter create --org com.m2soft --project-name flutter_map_practice .
```

After running the above command:
1. Ensure your `.env` file is present in the root directory (it is ignored by git for security).
2. Run `flutter pub get`
3. Run `flutter run`

## Architecture

This project follows a strict Modular MVC architecture under `lib/modules/map/`.
- **Model:** `map_location_model.dart` defines data structures.
- **View:** `map_screen.dart` contains pure UI components.
- **Controller:** `map_controller.dart` manages state and Kakao Map logic.

## Environment Variables
The application expects the following keys in the `.env` file:
- `KAKAO_MAP_JS_KEY`
- `KAKAO_NATIVE_APP_KEY`
- `KAKAO_REST_API_KEY`
