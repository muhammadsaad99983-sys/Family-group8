# Family Group – مرحلہ 1

## شامل فیچرز
لاگ اِن/پاس ورڈ، افراد کا اضافہ/ترمیم/حذف، تصویر، سرچ (نام، والد، موبائل، CNIC)،
ڈیش بورڈ (گنتی، سالگرہیں)، اردو/انگریزی، ڈارک/لائٹ، AES-256 انکرپٹڈ لوکل ڈیٹا۔

## APK اور AAB بنانے کا طریقہ
1. GitHub پر نئی repository بنائیں اور اس پوری فولڈر کو اپلوڈ کریں۔
2. Actions ٹیب → "Build Android APK and AAB" → Run workflow۔
3. مکمل ہونے پر Artifacts سے `family-group-release` ڈاؤن لوڈ کریں (APK + AAB)۔

یا اپنے کمپیوٹر پر: `flutter create --platforms=android .` پھر `flutter run`۔

## Play Store
AAB پر اپلوڈ کی (upload keystore) سے سائن کرنا ہوگا۔ keystore بنائیں:
`keytool -genkey -v -keystore upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload`
پھر `android/key.properties` اور `android/app/build.gradle` میں signingConfig شامل کریں
(Flutter ڈاکس: docs.flutter.dev/deployment/android)۔ اس کے بغیر بلڈ debug key سے سائن ہوتا ہے۔

## اگلے مراحل
2: شجرۂ نسب | 3: بیک اَپ/ایکسپورٹ/امپورٹ | 4: سالگرہ نوٹیفکیشن، خاندانی واقعات
