# 📝 مهامي — تطبيق To-Do بـ Flutter مع تحديث عن بُعد

تطبيق قائمة مهام عربي (RTL) تقدر **تحدّثه عن بُعد** ويوصل التحديث للمستخدمين **بدون ما يحمّلون التطبيق من جديد**.

## ✨ المميزات
- إضافة / تعديل / حذف المهام (اسحب للحذف + زر تراجع)
- أولوية (منخفضة / عادية / عالية) وتاريخ استحقاق مع تنبيه "متأخرة"
- فلترة: الكل / الحالية / المكتملة + شريط تقدّم
- حفظ محلي على الجهاز (المهام ما تنحذف مع التحديثات)
- وضع ليلي تلقائي، Material 3

## 🚀 طرق التحديث عن بُعد (3 مستويات)

| المستوى | وش يحدّث؟ | كيف؟ | يحتاج تثبيت؟ |
|---|---|---|---|
| **1. Remote Config** | النصوص، الألوان، الإعلانات، تشغيل/إيقاف ميزات | عدّل `remote/config.json` في GitHub | ❌ لا — يظهر خلال دقائق |
| **2. Shorebird Code Push** | **أي كود Dart** (شاشات، منطق، ميزات جديدة، إصلاح أخطاء) | `git push` على `main` ← GitHub Actions يرسل patch | ❌ لا — يتنزل بالخلفية ويشتغل عند إعادة فتح التطبيق |
| **3. APK كامل** | كود Native / إضافة Plugin جديدة | شغّل workflow **Release APK** | ✅ نعم (نادراً) — التطبيق ينبّه المستخدم تلقائياً |

### المستوى 1 — Remote Config
عدّل [`remote/config.json`](remote/config.json) من موقع GitHub مباشرة:
```json
{
  "app_title": "مهامي",
  "primary_color": "#4F46E5",
  "announcement": { "enabled": true, "text": "رسالتك هنا", "url": null },
  "features": { "show_stats": true, "show_priority": true },
  "apk_update": { "min_build": 0, "message": "...", "apk_url": "..." }
}
```
- `primary_color` يغيّر لون التطبيق كامل.
- `apk_update.min_build`: لو رقم build المثبّت أقل منه يظهر للمستخدم بانر "حمّل النسخة الجديدة".

### المستوى 2 — Shorebird (تحديث الكود نفسه) ⭐
**إعداد لمرة واحدة:**
1. ثبّت Shorebird على جهازك:
   ```bash
   curl --proto '=https' --tlsv1.2 https://raw.githubusercontent.com/shorebirdtech/install/main/install.sh -sSf | bash
   ```
2. سجّل دخول واطلع توكن CI:
   ```bash
   shorebird login:ci
   ```
3. في GitHub: **Settings → Secrets and variables → Actions → New repository secret**
   الاسم: `SHOREBIRD_TOKEN` والقيمة: التوكن اللي طلع لك.
4. **Actions → Release APK → Run workflow** — يسوي `shorebird init` تلقائياً ويبني APK ويرفعه في Releases.
5. حمّل `app-release.apk` من **Releases** وثبّته على جوالك (**هذي آخر مرة تثبّت فيها**).

**بعدها كل تحديث = `git push` بس:**
```bash
# عدّل أي شيء في lib/
git commit -am "ميزة جديدة"
git push
```
GitHub Actions يشغّل `shorebird patch android` تلقائياً ⇐ التطبيق ينزّل التحديث بالخلفية ⇐ يظهر بانر "تم تنزيل تحديث" ⇐ المستخدم يقفل التطبيق ويفتحه ✅

> أو من جهازك مباشرة: `shorebird patch android --release-version=latest`

### المستوى 3 — إصدار كامل جديد
فقط إذا أضفت Plugin جديدة أو غيّرت ملفات `android/`:
1. ارفع الـ version في `pubspec.yaml` (مثلاً `1.1.0+2`)
2. **Actions → Release APK → Run workflow**
3. عدّل `apk_update.min_build` في `remote/config.json` إلى `2` ← كل المستخدمين يشوفون تنبيه التحميل.

## 🔐 توقيع التطبيق
الـ Secrets التالية مضبوطة في المستودع (ضرورية عشان النسخ الجديدة تتثبّت فوق القديمة):
`ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`
⚠️ احتفظ بنسخة من ملف المفتاح — لو ضاع ما تقدر تحدّث التطبيق بـ APK جديد.

## 🧑‍💻 التشغيل محلياً
```bash
flutter pub get
flutter test
flutter run
```
> ملاحظة: `flutter run` ما يدعم Shorebird (شاشة التحديثات بتقول "غير مفعّل") — هذا طبيعي. للتجربة استخدم `shorebird preview`.

## 📁 البنية
```
lib/
├── main.dart                  # نقطة البداية + فحص التحديث عند الرجوع للتطبيق
├── app_config.dart            # روابط GitHub
├── models/task.dart
├── services/
│   ├── task_store.dart        # تخزين المهام
│   ├── remote_config.dart     # الإعدادات عن بُعد
│   └── update_service.dart    # Shorebird code push
├── screens/
│   ├── home_screen.dart
│   └── updates_screen.dart
└── widgets/task_editor.dart
remote/config.json             # ← عدّله للتحكم بالتطبيق عن بُعد
.github/workflows/
├── ci.yml                     # فحص + اختبارات
├── release.yml                # بناء APK ورفعه
└── patch.yml                  # تحديث OTA تلقائي عند push
```
