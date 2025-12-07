# SpoofAudioApp — Instrukcja uruchomienia (Django + Flutter)

Poniżej znajdziesz skróconą, praktyczną instrukcję jak przygotować środowisko (Python/Django i Flutter), gdzie umieścić modele i plik standaryzujący dane, jak uruchomić aplikację w trybie desktopowym oraz na emulatorze, a także opcję uruchomienia przez Docker.

## Wymagania wstępne
- **System:** Windows
- **Shell:** `powershell.exe` (Windows PowerShell 5.1)
- **Python:** 3.10+ (zalecane)
	- Pobierz z: https://www.python.org/downloads/
	- Zaznacz „Add Python to PATH” podczas instalacji.
- **Flutter SDK:** 3.x
	- Pobierz z: https://docs.flutter.dev/get-started/install/windows
	- Po rozpakowaniu dodaj ścieżkę do `flutter\bin` w `PATH`.
- **Android Studio + Emulator** (do uruchamiania Fluttera na Androidzie)
	- Zainstaluj Android Studio i utwórz AVD (Android Virtual Device).
- **Git** (opcjonalnie) do pracy z repozytorium.

## Struktura repozytorium (skrót)
- `djangoApp/` — backend (Django REST + logika klasyfikacji audio)
	- `audio_classifier/` — analiza, XAI, ładowanie i architektura modeli
	- `django_project/` — konfiguracja projektu Django (`settings.py`, `urls.py` itd.)
	- `manage_database/` — modele i migracje bazy danych
	- `requirements.txt` / `requirements.docker.txt` — zależności Pythona
	- `Pipfile` (jeśli używasz pipenv)
- `flutterApp/flutter_frontend/` — frontend Flutter
	- `lib/` — kod aplikacji (widoki, logika, stałe)
	- `pubspec.yaml` — zależności Flutter
	- `docker/` — opcjonalne pliki do uruchomienia frontendu w kontenerze
- `docker-compose.yml` — uruchomienie usług w Dockerze
- `DOCKER_SETUP.md` — dodatkowe uwagi dot. Dockera

## Umieszczenie modeli i pliku standaryzującego (Django)
- Katalog na najlepsze modele: `djangoApp/audio_classifier/models/best_models/`
	- Umieść wybrane, przeszkolone modele z konkretnymi nazwami wymaganymi przez kod (np. nazwy odpowiadające architekturze i wersji). Jeśli masz wytyczne co do nazw plików (np. `model_bilstm_v1.pt`, `scaler.pkl`), trzymaj się ich konsekwentnie.
	- Plik **standaryzujący dane** (np. scaler, normalizer) umieść w tym samym katalogu i załaduj w kodzie zgodnie z funkcjami w `audio_classifier/models` (np. `load_model.py`, `extract_feature_func.py`).
	- Jeśli nazwy muszą być dokładnie określone przez aplikację, sprawdź odwołania w `djangoApp/audio_classifier/models/load_model.py` i `models_architecture.py`.

## Konfiguracja i uruchomienie Django (lokalnie)
1. Wejdź do katalogu `djangoApp/` i utwórz wirtualne środowisko:
```powershell
cd "i:\Program Files\PracaInzApka\djangoApp"
python -m venv .venv
".venv\Scripts\Activate.ps1"
```
2. Zainstaluj zależności:
```powershell
pip install -r requirements.txt
```
3. Zainicjuj bazę danych i wykonaj migracje:
```powershell
python manage.py makemigrations
python manage.py migrate
python manage.py createsuperuser
```
4. Uruchom serwer developerski Django:
```powershell
python manage.py runserver
```
- Domyślnie będzie dostępny pod `http://127.0.0.1:8000/`.

## Konfiguracja i uruchomienie Flutter
1. Sprawdź instalację Flutter:
```powershell
flutter --version
flutter doctor
```
2. Zainstaluj zależności w projekcie frontendu:
```powershell
cd "i:\Program Files\PracaInzApka\flutterApp\flutter_frontend"
flutter pub get
```
3. Uruchom aplikację:
- **Desktop (Windows):**
```powershell
flutter config --enable-windows-desktop
flutter run -d windows
```
- **Android (emulator):**
	 - Uruchom AVD (Android Emulator) w Android Studio.
```powershell
flutter devices
flutter run -d emulator-5554
```
	(Zastąp `emulator-5554` właściwym ID urządzenia.)

## Integracja Django + Flutter
- Flutter komunikuje się z backendem Django poprzez API (REST). Upewnij się, że `BASE_URL`/`API_URL` w plikach Flutter (np. w `lib/constants.dart`) wskazuje na uruchomiony backend, np. `http://127.0.0.1:8000/` lub adres Dockera.
- Jeśli używasz emulatora Androida, pamiętaj o hostach specjalnych:
	- `10.0.2.2` to host `localhost` z perspektywy emulatora Android.

## Uruchomienie w Docker (opcjonalnie)
- Wymagany: Docker Desktop dla Windows.
- Z poziomu głównego katalogu repozytorium:
```powershell
cd "i:\Program Files\PracaInzApka"
docker compose up --build
```
- Uruchomienie w tle:
```powershell
docker compose up --build -d
```
- Bez przebudowy kontenerów:
```powershell
docker compose up
```
- Wyłączenie:
```powershell
docker compose down
```

## Krótko o funkcjach i strukturze (Django)
- **`audio_classifier/analyse_func.py`**: funkcje analizy audio i przygotowania cech.
- **`audio_classifier/xai_func.py`**: metody XAI do objaśniania predykcji modeli.
- **`audio_classifier/models`**: architektury (`models_architecture.py`), ładowanie/zarządzanie modelami (`load_model.py`), ekstrakcja cech (`extract_feature_func.py`), katalog `best_models` na wybrane modele i plik standaryzujący.
- **`manage_database/`**: modele bazy danych, migracje, widoki API.
- **`django_project/settings.py`**: konfiguracja projektu, aplikacji, baz danych, static/media.

## Wymagania (dependencies)
- **Python (Django):** w `djangoApp/requirements.txt`.
- **Flutter:** w `flutterApp/flutter_frontend/pubspec.yaml`.
- Dodatkowe wymagania Dockera: `requirements.docker.txt` oraz `docker-compose.yml` (usługi backend/front).

## Najczęstsze problemy i wskazówki
- **PATH:** Upewnij się, że `python`, `pip`, `flutter` są dostępne w `PATH`.
- **Uprawnienia PowerShell:** jeśli aktywacja venv jest blokowana, uruchom PowerShell jako Administrator i ustaw politykę:
```powershell
Set-ExecutionPolicy RemoteSigned
```
- **Modele i standaryzacja:** brak plików w `best_models` lub zła nazwa spowoduje błędy ładowania. Sprawdź logikę w `load_model.py`.
- **Emulator sieć:** z Androida używaj `http://10.0.2.2:8000/` zamiast `localhost`.

## Skrót: szybkie komendy
```powershell
# Django
cd "i:\Program Files\PracaInzApka\djangoApp"; python -m venv .venv; ".venv\Scripts\Activate.ps1"; pip install -r requirements.txt; python manage.py migrate; python manage.py runserver

# Flutter (Windows desktop)
cd "i:\Program Files\PracaInzApka\flutterApp\flutter_frontend"; flutter pub get; flutter config --enable-windows-desktop; flutter run -d windows

# Docker
cd "i:\Program Files\PracaInzApka"; docker compose up --build
```