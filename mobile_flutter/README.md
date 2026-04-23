# BetaUp Mobile

This folder contains a Flutter mobile client for BetaUp. It keeps the existing Java backend unchanged and talks to the same Spring Boot API used by the current React frontend.

## Scope

- JWT login and registration
- Role-based mobile navigation for `CLIMBER` and `COACH`
- Climber dashboard, climb logs, badge progress, and feedback history
- Coach dashboard, climber roster/detail, feedback management, and badge rule management

## API base URL

The app reads `BETAUP_API_BASE_URL` from `--dart-define`.

Example:

```bash
flutter run --dart-define=BETAUP_API_BASE_URL=http://10.0.2.2:8080/api
```

If no override is supplied, the app uses:

- Android emulator: `http://10.0.2.2:8080/api`
- Other platforms: `http://127.0.0.1:8080/api`

## Notes

- The Flutter SDK is not installed in the current workspace, so this client was scaffolded manually instead of via `flutter create`.
- Before the first run, generate the native platform folders inside `mobile_flutter/`:

```bash
cd mobile_flutter
flutter create .
flutter pub get
```

- The backend remains in `backend/` and does not need code changes for this mobile client.

## Windows path workaround

When this project is placed under a non-ASCII Windows path, `flutter run -d windows`
can generate a broken `windows/flutter/ephemeral/generated_config.cmake`, which then
causes missing `cpp_client_wrapper/*.cc` build errors.

Use the helper script below from the current `mobile_flutter/` directory. It creates
an ASCII junction path and runs the Windows build there:

```powershell
powershell -ExecutionPolicy Bypass -File .\tool\run_windows.ps1
```

Extra Flutter arguments are forwarded, for example:

```powershell
powershell -ExecutionPolicy Bypass -File .\tool\run_windows.ps1 --dart-define=BETAUP_API_BASE_URL=http://127.0.0.1:8080/api
```

To verify compilation only:

```powershell
powershell -ExecutionPolicy Bypass -File .\tool\run_windows.ps1 -BuildOnly
```
