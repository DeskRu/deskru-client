# DeskRu macOS Client - Design Spec

## Цель

Собрать кастомный macOS клиент RustDesk с ребрендингом под DeskRu, зашитыми серверными настройками, и автоматической сборкой через GitHub Actions. Это пилотная сборка - после успешной macOS-версии масштабируем на все платформы (Windows, Linux, Android, iOS).

## Серверные настройки (зашитые в клиент)

| Параметр | Значение |
|----------|----------|
| ID-сервер | `deskru.ru` |
| Relay-сервер | `deskru.ru` |
| API-сервер | `https://api.deskru.ru` |
| Ключ | `IIHJ75Hqj8IEjQvQ/eNOnEZb2+D3MjGKL4GIJLdooBU=` |
| REQUIRE_LOGIN | `Y` |

## Ребрендинг

### Название и идентификаторы

- Название приложения: **DeskRu** (везде вместо "RustDesk")
- Bundle ID: `ru.deskru.client` (вместо `com.carriez.rustdesk`)
- Версия: совпадает с версией upstream RustDesk

### Визуальные ассеты

- Иконка: placeholder (стандартная, заменим позже)
- Splash screen: текст "DeskRu" вместо "RustDesk"
- About page: "DeskRu" с указанием "Разработано на основе RustDesk (rustdesk.com)" (AGPL-3.0)

### Удаление упоминаний RustDesk

- Заголовки окон
- Строки интерфейса (Flutter l10n)
- macOS-специфичные файлы (Info.plist, entitlements)
- Splash/About экраны

### Без изменений

- Тема интерфейса (стандартная RustDesk тема)
- Функциональность клиента
- Цвета и шрифты

## Сборка (GitHub Actions)

### Workflow

- На базе существующего `flutter-build.yml`
- Target: macOS (arm64 + x86_64 dmg)
- Триггер: `workflow_dispatch` (ручной запуск)
- Без Apple Developer подписи и нотаризации

### Артефакты

- `DeskRu-<version>-macos-arm64.dmg`
- `DeskRu-<version>-macos-x86_64.dmg`

## Вне скоупа (этап 1)

- Другие платформы (Windows, Linux, Android, iOS)
- Apple Developer подпись и нотаризация
- Кастомные цвета/тема
- Настоящие иконки и ассеты
- Автообновление клиента
- Публикация в App Store

## Юридическое

DeskRu - Клиент на базе RustDesk (AGPL-3.0)
