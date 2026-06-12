# Flutter Map Practice

Kakao Map API Integration Project using Flutter.

## How to Download and Run

1. Clone the repository.
   ```bash
   git clone https://github.com/ShinHeeYoun/FlutterMapPractice.git
   ```
2. Navigate to the project directory.
   ```bash
   cd FlutterMapPractice
   ```
3. Install dependencies.
   ```bash
   flutter pub get
   ```
4. Create a `.env` file in the root directory and add your Kakao API Keys.
   ```env
   KAKAO_MAP_JS_KEY=your_javascript_key
   KAKAO_NATIVE_APP_KEY=your_native_app_key
   KAKAO_REST_API_KEY=your_rest_api_key
   ```
   Note: The `http://localhost:8080` domain must be registered in the Kakao Developers Console (Web Platform -> Site Domain) and the Kakao Map API must be activated.
5. Run the application.
   ```bash
   flutter run
   ```

## Troubleshooting History

### 1. File Locking and Permission Errors
- **Symptom:** Build compilation errors due to file locking and permission issues in the OneDrive directory.
- **Resolution:** Migrated the project root directory entirely out of the OneDrive folder to `D:\Develop\Flutter_practice` to avoid synchronization conflicts.

### 2. Android Manifest Namespace Deprecation
- **Symptom:** Gradle build failure due to the deprecated `package` attribute in `AndroidManifest.xml`.
- **Resolution:** Removed the `package` attribute from `AndroidManifest.xml`. Namespace management is now handled by Gradle (`build.gradle`).

### 3. SDK Version Mismatch
- **Symptom:** Third-party plugins failed to compile because they were strictly bound to API 35, which conflicted with the modern `webview_flutter` compiling against SDK 36.
- **Resolution:** Injected a hook in the root `android/build.gradle.kts` to dynamically force all subprojects to compile against SDK 36 using Kotlin DSL reflection before the evaluation phase.

### 4. Multi-Drive Kotlin Cache Bug
- **Symptom:** `java.lang.IllegalArgumentException` during incremental compilation caused by the Windows C: and D: cross-drive relative path error.
- **Resolution:** Disabled Kotlin incremental compilation by adding `kotlin.incremental=false` to `android/gradle.properties`.

### 5. Kakao Map Webview "kakao is not defined" Error
- **Symptom:** The Kakao Map JavaScript SDK failed to load inside the Android WebView, returning a ReferenceError for `kakao`.
- **Resolution:** 
  1. Updated `android/app/src/main/AndroidManifest.xml` to include `android:usesCleartextTraffic="true"`.
  2. Defined `baseUrl: 'http://localhost:8080'` in the `AuthRepository.initialize` method to avoid the restricted `about:blank` or `https` strict-origin policies in newer Chromium versions.
  3. Corrected a typographical error in the API key provided in the source code.
  4. Confirmed that the domain `http://localhost:8080` was correctly registered in the Kakao Developers Console under Web Platform -> Site Domain, and the API was toggled ON.

### 6. Kakao Map Blank Screen on Emulator (Current Location)
- **Symptom:** When attempting to move to the current location, the map displayed a blank screen with only the location marker.
- **Resolution:** The default GPS location of Android emulators is Mountain View, California (Google HQ). Since Kakao Map only provides map tiles for South Korea, the map cannot render outside this region. Implemented a bounding box check `(Lat: 33~39, Lng: 124~132)` covering the Korean peninsula. If the GPS location falls outside these bounds, the app safely defaults to Gangnam Station `(37.4979, 127.0276)` and displays a `SnackBar` notification to the user.

## Update History

- **2026-06-12 15:00:** Project initialized and modular MVC architecture applied.
- **2026-06-12 15:15:** Resolved environment migration, Gradle namespace issues, and SDK compilation mismatches.
- **2026-06-12 15:25:** Implemented device geolocation tracking using `geolocator` and added location permissions.
- **2026-06-12 15:47:** Resolved Kakao Map SDK `kakao is not defined` error by correcting the API key typo and updating the WebView base URL.
- **2026-06-12 15:50:** Documentation rewritten with detailed troubleshooting steps.
- **2026-06-12 16:30:** Implemented search UI with Kakao Local API integration. Added distance-based sorting, dropdown search results, and location boundary fallback for emulators.
