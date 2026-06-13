# Flutter Map Practice (플러터 카카오맵 연습)

Flutter를 이용한 카카오맵(Kakao Map) API 연동 프로젝트입니다.

## 다운로드 및 실행 방법

1. 저장소를 클론합니다.
   ```bash
   git clone https://github.com/ShinHeeYoun/FlutterMapPractice.git
   ```
2. 프로젝트 디렉토리로 이동합니다.
   ```bash
   cd FlutterMapPractice
   ```
3. 패키지 의존성을 설치합니다.
   ```bash
   flutter pub get
   ```
4. 최상위 디렉토리에 `.env` 파일을 생성하고 발급받은 카카오 API 키를 입력합니다.
   ```env
   KAKAO_MAP_JS_KEY=본인의_자바스크립트_키
   KAKAO_NATIVE_APP_KEY=본인의_네이티브_앱_키
   KAKAO_REST_API_KEY=본인의_REST_API_키
   ```
   **참고:** 카카오 디벨로퍼스 콘솔(웹 플랫폼 -> 사이트 도메인)에 반드시 `http://localhost:8080` 도메인이 등록되어 있어야 하며, 카카오맵 API가 활성화(ON) 상태여야 합니다.
5. 앱을 실행합니다.
   ```bash
   flutter run
   ```

## 트러블슈팅 (문제 해결 이력)

### 1. 파일 잠금(Locking) 및 권한 오류
- **증상:** OneDrive 디렉토리 동기화로 인한 파일 잠금 및 권한 문제로 빌드 컴파일 에러 발생.
- **해결 방안:** 동기화 충돌을 피하기 위해 프로젝트 루트 디렉토리를 OneDrive 외부인 `D:\Develop\Flutter_practice`로 완전히 이전했습니다.

### 2. Android Manifest 네임스페이스(Namespace) 지원 중단(Deprecation) 오류
- **증상:** `AndroidManifest.xml` 내에 사용이 중단된 `package` 속성이 있어 Gradle 빌드 실패.
- **해결 방안:** `AndroidManifest.xml`에서 `package` 속성을 제거했습니다. 현재 네임스페이스 관리는 Gradle(`build.gradle`)에서 처리하도록 변경되었습니다.

### 3. SDK 버전 불일치 문제
- **증상:** 최신 `webview_flutter` 플러그인은 SDK 36을 기준으로 컴파일되는데, 일부 서드파티 플러그인이 API 35에 강제로 종속되어 있어 컴파일 실패.
- **해결 방안:** 루트 `android/build.gradle.kts`에 Hook(가로채기) 로직을 주입하여, 평가 단계 이전에 Kotlin DSL 리플렉션을 통해 모든 하위 프로젝트가 SDK 36으로 강제 컴파일되도록 조치했습니다.

### 4. 멀티 드라이브(Multi-Drive) Kotlin 캐시 버그
- **증상:** Windows의 C: 드라이브와 D: 드라이브 간 상대 경로 교차 문제로 인해 증분 컴파일(Incremental Compilation) 중 `java.lang.IllegalArgumentException` 에러 발생.
- **해결 방안:** `android/gradle.properties` 파일에 `kotlin.incremental=false`를 추가하여 Kotlin 증분 컴파일을 비활성화했습니다.

### 5. 카카오맵 웹뷰 "kakao is not defined" 에러
- **증상:** Android 웹뷰 내에서 카카오맵 JavaScript SDK가 로드되지 못하고 `kakao` 객체에 대해 ReferenceError를 반환하는 문제.
- **해결 방안:** 
  1. `android/app/src/main/AndroidManifest.xml`에 `android:usesCleartextTraffic="true"` 옵션을 추가했습니다.
  2. 최신 Chromium 버전에 적용된 `about:blank` 및 엄격한 `https` 오리진 정책을 피하기 위해 `AuthRepository.initialize` 메서드에 `baseUrl: 'http://localhost:8080'`을 명시적으로 정의했습니다.
  3. 소스코드에 입력된 API 키의 오타를 수정했습니다.
  4. 카카오 디벨로퍼스 콘솔의 [플랫폼 -> 웹] 설정에 `http://localhost:8080`이 정상 등록되어 있고, API 상태가 ON인지 재확인했습니다.

### 6. 에뮬레이터에서 카카오맵 백화 현상 (현재 위치 오류)
- **증상:** 앱에서 현재 위치로 이동을 시도할 때, 지도가 그려지지 않고 마커만 덩그러니 나오는 백화 현상 발생.
- **해결 방안:** 안드로이드 에뮬레이터의 기본 GPS 위치는 구글 본사(미국 캘리포니아 마운틴뷰)로 설정되어 있습니다. 카카오맵은 한국 영토 내의 지도 타일만 제공하므로 해당 위치에서는 지도를 렌더링할 수 없습니다. 이를 방지하기 위해 한국 영토를 감싸는 Boundary Check (위도: 33~39, 경도: 124~132) 로직을 구현했습니다. 만약 GPS가 이 범위를 벗어날 경우 앱이 자동으로 위치를 강남역(37.4979, 127.0276)으로 지정하며, 사용자에게 안내하는 `SnackBar` 알림을 띄웁니다.

## 업데이트 내역

- **2026-06-12 15:00:** 프로젝트 초기화 및 모듈 기반 MVC 아키텍처 적용.
- **2026-06-12 15:15:** 개발 환경 이전, Gradle 네임스페이스 이슈 해결 및 SDK 컴파일 불일치 오류 수정.
- **2026-06-12 15:25:** `geolocator` 패키지를 이용한 기기 GPS 추적 기능 및 위치 권한 요청 로직 추가.
- **2026-06-12 15:47:** 웹뷰 베이스 URL(baseUrl) 할당 및 API 키 오타 수정을 통한 `kakao is not defined` 에러 완벽 해결.
- **2026-06-12 15:50:** 트러블슈팅 조치 과정을 상세하게 포함하여 문서(README.md) 전면 재작성.
- **2026-06-12 16:30:** 카카오 로컬(Local) API 연동 장소 검색 UI 구현. 거리 및 정확도 기반 정렬 알고리즘, 검색 결과 드롭다운, 에뮬레이터 해외 위치 대비 강남역 폴백 로직 추가.
- **2026-06-12 16:50:** 대대적인 MVC 및 Clean Architecture 리팩토링 진행.
  - 너무 길었던 UI 코드를 `SearchBarWidget` 및 `SearchResultOverlay`로 쪼개어 모듈화(컴포넌트화).
  - 컨트롤러 내부의 복잡한 로직을 `LocationService`(GPS 및 폴백 제어)와 `KakaoMapRepository`(HTTP 네트워크 통신)로 완벽히 분리.
  - 타입 안정성을 보장하기 위해 기존의 Map 형태 데이터 대신 명시적인 `PlaceModel` 객체를 도입.
  - 커스텀 Exception 클래스들을 활용한 Try-Catch 기반의 에러 핸들링 및 상태 관리 구현.
