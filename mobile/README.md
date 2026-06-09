# Flowly Mobile

Flutter/Dart Android/iOS version of the Flowly app. The mobile app reuses the existing Express API in `../server` and Supabase Auth.

## Run

### 1. Start the API in terminal 1

Location:

```text
/Users/leminhhuy/Drive/flowly-mobile
```

Command:

```bash
cd /Users/leminhhuy/Drive/flowly-mobile
npm run dev:server
```

API entry file:

```text
/Users/leminhhuy/Drive/flowly-mobile/server/index.js
```

API env file:

```text
/Users/leminhhuy/Drive/flowly-mobile/.env
```

### 2. Start Flutter in terminal 2

Location:

```text
/Users/leminhhuy/Drive/flowly-mobile/mobile
```

Command:

```bash
cd /Users/leminhhuy/Drive/flowly-mobile/mobile
flutter run
```

Flutter entry file:

```text
/Users/leminhhuy/Drive/flowly-mobile/mobile/lib/main.dart
```

Flutter public config file:

```text
/Users/leminhhuy/Drive/flowly-mobile/mobile/assets/config/app.env
```

Plain `flutter run` works because the app reads public Supabase config from
`assets/config/app.env`.

### Optional combined command

If you want one command from the repository root:

```bash
cd /Users/leminhhuy/Drive/flowly-mobile
npm run dev:mobile
```

This is optional. The normal Flutter command is still:

```bash
cd mobile
flutter run
```

Use these API URLs by target:

- iOS simulator: `http://localhost:3000`
- Android emulator: `http://10.0.2.2:3000`
- Real phone/iPad: `http://<your-mac-lan-ip>:3000`

If the backend is not reachable at startup, pass overrides directly:

```bash
flutter run \
  --dart-define-from-file=.env \
  --dart-define=FLOWLY_API_BASE_URL=http://<api-host>:3000 \
  --dart-define=SUPABASE_URL=<your-supabase-url> \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=<your-supabase-publishable-key>
```

Flutter does not auto-load `.env` files. Use `--dart-define-from-file=.env`
for temporary overrides, or keep `assets/config/app.env` updated for plain
`flutter run`.

For Google/Facebook OAuth, add this redirect URL in Supabase Auth settings:

```text
flowly://login-callback
```

In Supabase Dashboard, this goes under Authentication > URL Configuration >
Additional Redirect URLs. Google/Facebook provider credentials still use the
normal Supabase callback URL shown by Supabase.

If the browser lands on `ryanle.top` after Google login, Supabase has not accepted
the mobile redirect URL yet and is falling back to the old Site URL. Add the
`flowly://login-callback` URL above, then stop and run the app again.

## Implemented

- Login, register, forgot password, Google/Facebook OAuth trigger
- Success screen matching the mobile mockup style
- Mobile Home with summary cards, month calendar, search, add task, complete/delete
- Schedule weekly strip, hourly timeline, add/edit/delete schedule, repeat creation
- Tasks screen with status chips and card list adapted from the Kanban web app
- Flowly Bot modal using `/api/ai/parse`
- Account sheet with profile update, language toggle, logout
- Responsive width/padding for iPad/tablet layouts
