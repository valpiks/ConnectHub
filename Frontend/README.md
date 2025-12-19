# ConnectHub Mobile

Мобильный клиент приложения **ConnectHub** на Flutter.

## Быстрый старт

1. Установите зависимости:

   ```bash
   flutter pub get
   ```

2. Создайте `.env` на основе `.env.base`:

   ```bash
   cp .env.base .env
   ```

   Важный параметр:

   - `API_URL` — базовый URL вашего backend‑API (например, `http://10.0.2.2/api` для Android‑эмулятора).

3. Запустите приложение:

   ```bash
   flutter run
   ```

## Стек

- Flutter, Dart
- `flutter_riverpod`
- `go_router`
- `dio`
- `flutter_dotenv`
