# Adding Custom Fonts to FlowFit

This document explains how to add custom fonts such as "General Sans" to FlowFit so the UI uses them across the app.

## Steps

1. Add font files
   - Create a directory `assets/fonts/<FontFamilyName>/` and put your `.ttf` or `.otf` files there.
   - Example: `assets/fonts/GeneralSans/GeneralSans-Regular.ttf` and `assets/fonts/GeneralSans/GeneralSans-Bold.ttf`.
   - Make sure you have the correct license to include the font files in your repo.

2. Update `pubspec.yaml` (example)

```yaml
flutter:
  fonts:
    - family: GeneralSans
      fonts:
        - asset: assets/fonts/GeneralSans/GeneralSans-Regular.ttf
        - asset: assets/fonts/GeneralSans/GeneralSans-Bold.ttf
          weight: 700
```

3. Run `flutter pub get` in the project root:

```bash
flutter pub get
```

If font changes don't appear, try:

```bash
flutter clean
flutter pub get
```

4. Configure the font in your app theme (the project already does this in `lib/theme/app_theme.dart`):

```dart
ThemeData(
  fontFamily: 'GeneralSans',
  // existing textTheme blocks will use this font automatically
)
```

5. Use the font in Widgets
   - Use `Theme.of(context)` text styles or explicit `TextStyle(fontFamily: 'GeneralSans')` in Text widgets.

6. Example: Add sample text to verify the font

```dart
Text(
  'Hello FlowFit',
  style: Theme.of(context).textTheme.displayLarge,
)
```

## Notes
- Avoid committing licensed fonts unless the license allows it. Add them locally or in a private repo if needed.
- Add a `.gitignore` rule if you want to keep fonts local and not commit them.
- If you want to add multiple fonts (e.g., Inter or Roboto) add more `fonts:` entries to `pubspec.yaml` and use `fontFamily` accordingly.
- If your app still shows system default fonts after adding, verify the `family` name in the `pubspec.yaml` matches the `fontFamily` in your theme and that you run `flutter clean` + `flutter pub get`.

## Quick run to verify font

1. Start the app on a device/emulator:

```bash
# If you want to quickly start the app on a device and open the demo directly:
# Use the compile-time env var `INITIAL_ROUTE` (no source edit required):
flutter run -d <device-id> -t lib/main.dart --dart-define=INITIAL_ROUTE=/font-demo

# Otherwise launch normally and navigate to the demo route in the UI:
flutter run -d <device-id> -t lib/main.dart
```

2. Navigate to the font demo route (`/font-demo`) in the app, or open `http://localhost:xxxx/font-demo` depending on how routes are used. The demo screen shows different text styles so you can verify the font loads correctly.

### Programmatic verification

If you prefer a programmatic verification, `FontDemoScreen` reads the `FontManifest.json` at runtime and will display if `GeneralSans` is present in the manifest. It also shows the default text style font family applied to the app so you can confirm the theme is using the font.

If you don't see `GeneralSans present in FontManifest: yes` on the demo screen, then the font is not registered or not packaged into the app correctly.

