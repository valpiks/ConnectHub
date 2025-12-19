# ConnectHub

Монорепозиторий приложения **ConnectHub**:

- **Backend** — FastAPI‑сервис c авторизацией, рекомендациями, событиями, друзьями и чатами (папка `Backend`).
- **Frontend** — мобильное приложение на Flutter для работы с платформой (папка `Frontend`).
- Инфраструктура — `docker-compose`, Nginx, PostgreSQL, MinIO, переменные окружения через `.env`.

Приложение позволяет:

- регистрироваться и авторизовываться;
- заполнять профиль и теги интересов;
- искать людей и события, получать рекомендации;
- добавлять в друзья и матчиться;
- вести чаты.

## Структура репозитория

- `Backend/` — бэкенд‑часть (FastAPI, PostgreSQL, MinIO, Nginx, Docker).
  - `backend/app` — исходники приложения:
    - `main.py` — точка входа FastAPI (роуты, middleware, health‑check);
    - `routers/` — эндпоинты: `auth`, `users`, `events`, `chats`, `files`, `admin`;
    - `models/`, `schemas/`, `services/`, `core/` — бизнес‑логика, схемы и утилиты;
    - `config.py` — настройки через `pydantic-settings` и `.env`.
  - `docker-compose.yml` — сборка и запуск PostgreSQL, MinIO, backend и Nginx.
  - `env.base` — пример env‑файла для бэкенда.
- `Frontend/` — Flutter‑приложение.
  - `lib/main.dart` — точка входа приложения;
  - `lib/core` — тема, навигация (`go_router`), API‑клиент (Dio + `flutter_dotenv`);
  - `lib/features` — экранная логика и UI;
  - `.env.base` — пример env‑файла для клиента.

## Используемый стек

- **Backend**
  - Python 3.11
  - FastAPI
  - SQLAlchemy
  - PostgreSQL
  - MinIO (хранение файлов)
  - Uvicorn
  - Nginx
  - Docker / Docker Compose

- **Frontend**
  - Flutter
  - Dart
  - `flutter_riverpod`
  - `go_router`
  - `dio`
  - `flutter_dotenv`

## Быстрый старт через Docker

Требования:

- установлен Docker и Docker Compose;
- Python и Flutter локально не обязательны (для варианта с контейнерами).

1. Перейдите в корень бэкенда:

   ```bash
   cd Backend
   ```

2. Создайте `.env` на основе `env.base`:

   ```bash
   cp env.base .env
   # отредактируйте значения при необходимости
   ```

   Важные переменные:

   - `DB_NAME`, `DB_USER`, `DB_PASSWORD`, `DB_PORT` — настройки PostgreSQL;
   - `SERVER_PORT` — порт backend‑сервиса внутри docker‑сети;
   - `DEBUG`, `MOCK_MODE` — режимы отладки и мок‑данных;
   - `JWT_SECRET` — секрет для JWT‑токенов;
   - `MINIO_ENDPOINT`, `MINIO_ACCESS_KEY`, `MINIO_SECRET_KEY`, `MINIO_BUCKET` — настройки MinIO.

3. Поднимите инфраструктуру:

   ```bash
   docker compose up --build
   # или, в зависимости от версии:
   # docker-compose up --build
   ```

4. После старта:

- Nginx слушает `http://localhost:80`;
- backend‑API доступно через прокси Nginx;
- OpenAPI/Swagger:
  - Swagger UI — `http://localhost/docs`
  - OpenAPI JSON — `http://localhost/docs-json`
- Health‑check бэкенда — `GET /health`.

## Локальный запуск бэкенда без Docker

Требования:

- Python 3.11+
- локальный PostgreSQL (или другой совместимый, с соответствующим `DATABASE_URL`)

1. Перейдите в папку backend‑приложения:

   ```bash
   cd Backend/backend
   ```

2. Создайте виртуальное окружение и установите зависимости:

   ```bash
   python -m venv .venv
   source .venv/bin/activate  # Windows: .venv\Scripts\activate
   pip install -r requirements.txt
   ```

3. Создайте `.env` в `Backend/backend/app` или в корне `Backend` (в зависимости от сценария использования) на основе `env.base` и/или `config.py`. Параметр `database_url` можно переопределить переменной окружения `DATABASE_URL`.

4. Запустите Uvicorn:

   ```bash
   uvicorn app.main:app --reload
   ```

   По умолчанию приложение будет доступно по адресу `http://127.0.0.1:8000`.

## Запуск Flutter‑клиента

Требования:

- установлен Flutter SDK;
- настроенный эмулятор/устройство (Android или iOS).

1. Перейдите в папку клиента:

   ```bash
   cd Frontend
   ```

2. Создайте `.env` на основе `.env.base`:

   ```bash
   cp .env.base .env
   ```

   Важный параметр:

   - `API_URL` — базовый URL для API, например:
     - `http://10.0.2.2/api` — для Android‑эмулятора при проксировании на `localhost`;
     - `http://localhost/api` — при прямом доступе с устройства/браузера.

3. Установите зависимости:

   ```bash
   flutter pub get
   ```

4. Запустите приложение:

   ```bash
   flutter run
   ```

Приложение использует:

- `flutter_dotenv` — подгрузка `.env`;
- `Dio` + собственный `ApiClient` — HTTP‑клиент;
- `go_router` — навигация;
- `flutter_riverpod` — управление состоянием.

## Полезные ссылки

- Backend API Swagger: `/docs` (после запуска бэкенда)
- OpenAPI JSON: `/docs-json`
- Health‑check: `/health`

## Дополнительно

- Детали реализации бэкенда см. в `Backend/backend/app` и `Backend/README.md`.
- Детали Flutter‑клиента см. в `Frontend/README.md` и `pubspec.yaml`.

