# 위드셀 (WithSell)
Flutter 앱 프로젝트입니다.  
Firestore를 이용해 데이터를 저장/갱신/삭제하고, REST API 호출을 통해 데이터를 동기화합니다.  
네트워크 연결이 불안정하거나 오프라인인 경우에도 사용할 수 있도록, 마지막으로 수신한 JSON 데이터를 SharedPreferences에 캐시로 저장합니다.

## Features
- Firestore: 데이터 저장/갱신/삭제(CRUD)
- REST API: 단발성 호출로 데이터 조회/동기화
- SharedPreferences: 마지막 수신 JSON 캐시(오프라인 fallback)

## Tech Stack
- Flutter: 3.38.4 (FVM: Use)
- Firebase: Firestore
- Architecture: MVVM
- Local Storage: SharedPreferences

## Data Flow (High Level)

