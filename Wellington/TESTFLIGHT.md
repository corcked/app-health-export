# Wellington — TestFlight Deployment Guide

## Что уже настроено

- [x] Team ID: `VU3ZBTK8XM` (Debug + Release)
- [x] Bundle ID: `com.wellington.healthexport`
- [x] Automatic Signing
- [x] Entitlements: HealthKit, iCloud Documents
- [x] Export Compliance: `ITSAppUsesNonExemptEncryption = NO`
- [x] Privacy Policy: `privacy-policy.html`
- [ ] App Icon (нужно добавить 1024x1024 PNG)

---

## Шаг 1: Создать App Icon

Добавить PNG 1024x1024px в:
```
Wellington/Resources/Assets.xcassets/AppIcon.appiconset/
```

Обновить `Contents.json`:
```json
{
  "images": [
    {
      "filename": "AppIcon.png",
      "idiom": "universal",
      "platform": "ios",
      "size": "1024x1024"
    }
  ],
  "info": {
    "author": "xcode",
    "version": 1
  }
}
```

## Шаг 2: Зарегистрировать App ID

1. Открыть [developer.apple.com/account](https://developer.apple.com/account)
2. Certificates, Identifiers & Profiles → Identifiers → `+`
3. Выбрать "App IDs" → "App"
4. Заполнить:
   - Description: `Wellington Health Export`
   - Bundle ID: `com.wellington.healthexport` (Explicit)
5. Включить Capabilities:
   - ✅ HealthKit
   - ✅ iCloud (включить CloudKit)
   - ✅ Background Modes
6. Register

## Шаг 3: Создать приложение в App Store Connect

1. Открыть [appstoreconnect.apple.com](https://appstoreconnect.apple.com)
2. My Apps → `+` → New App
3. Заполнить:
   - Platform: iOS
   - Name: `Wellington`
   - Primary Language: English (U.S.)
   - Bundle ID: выбрать `com.wellington.healthexport`
   - SKU: `wellington-health-export`
   - User Access: Full Access
4. В разделе App Information:
   - Privacy Policy URL: (URL где размещён `privacy-policy.html`)
   - Category: Health & Fitness

## Шаг 4: Открыть проект в Xcode и проверить

1. Открыть `Wellington.xcodeproj` в Xcode
2. Выбрать target "Wellington"
3. Signing & Capabilities:
   - Убедиться что Team = ваша команда
   - Signing Certificate = автоматический
4. Добавить capabilities через `+ Capability`:
   - HealthKit (если не добавлен автоматически)
   - iCloud → отметить CloudKit
   - Background Modes → отметить "Background processing"

## Шаг 5: Archive и Upload

1. Выбрать устройство: **Any iOS Device (arm64)**
2. Product → Archive
3. Дождаться завершения архивации
4. Window → Organizer
5. Выбрать архив → Distribute App
6. Выбрать **App Store Connect** → Upload
7. Оставить все чекбоксы по умолчанию → Upload
8. Дождаться загрузки (~5-10 мин)

## Шаг 6: Настроить TestFlight

1. В App Store Connect → Wellington → TestFlight
2. Дождаться обработки билда (~15-30 мин, придёт email)
3. Заполнить Export Compliance (должно быть автоматически "No" благодаря ключу)
4. **Internal Testing:**
   - Создать группу тестировщиков
   - Добавить участников (по Apple ID email)
   - Выбрать билд → Start Testing
   - Тестировщикам придёт приглашение в TestFlight
5. **External Testing** (опционально, требует Beta App Review):
   - Создать группу
   - Заполнить: What to Test, Contact Info
   - Отправить на Review

## Шаг 7: Увеличение версии для следующих билдов

Для каждого нового билда в TestFlight увеличивайте `CURRENT_PROJECT_VERSION` в project.pbxproj:
- Текущий: `1`
- Следующий: `2`, `3`, ...

Или через Xcode: Target → General → Build (increment number).

---

## Где разместить Privacy Policy

Варианты:
1. **GitHub Pages** — бесплатно, пушнуть `privacy-policy.html` в отдельный репо с GitHub Pages
2. **В репозитории приложения** — GitHub raw URL (не рекомендуется, может сломаться)
3. **Любой хостинг** — Netlify, Vercel, свой сервер

Нужен публичный HTTPS URL для App Store Connect.
