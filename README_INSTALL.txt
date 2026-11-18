Mofuchi Dashboard using your images

1. Your six PNG images are already in assets/images/weather_img/. Keep them there.
2. Back up your existing lib/screens/dashboard_screen.dart.
3. Replace it with lib/screens/dashboard_screen.dart from this ZIP.
4. In pubspec.yaml beneath flutter: add:
   assets:
     - assets/images/weather_img/
   (Only if you do not already register assets/images/ or this folder.)
5. Save, run flutter pub get, then flutter run or hot restart.
Dashboard reads logged-in user data from Firestore emotion_logs.
