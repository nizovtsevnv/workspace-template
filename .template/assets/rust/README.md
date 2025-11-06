# {{MODULE_NAME}}

Rust модуль workspace, созданный автоматически.

## Технологический стек

- **Стек**: Rust
- **Тип**: {{TYPE}}
- **Система сборки**: Cargo

## Сборка

```bash
# Из корня workspace
make {{MODULE_NAME}} cargo build         # Debug сборка
make {{MODULE_NAME}} cargo build --release  # Release сборка
```

## Разработка

Этот модуль является частью polyglot workspace и разрабатывается с использованием host-first подхода (инструменты запускаются на хосте, если доступны, иначе в Alpine контейнере).

### Запуск

```bash
make {{MODULE_NAME}} cargo run           # Запуск debug версии
make {{MODULE_NAME}} cargo run --release # Запуск release версии
make {{MODULE_NAME}} cargo run -- <args> # С аргументами
```

### Тестирование

```bash
make {{MODULE_NAME}} cargo test          # Запуск всех тестов
make {{MODULE_NAME}} cargo test --lib    # Только unit тесты
make {{MODULE_NAME}} cargo test --doc    # Только doc тесты
make {{MODULE_NAME}} cargo bench         # Бенчмарки
```

### Проверка кода

```bash
# Clippy (линтер)
make {{MODULE_NAME}} cargo clippy
make {{MODULE_NAME}} cargo clippy -- -D warnings  # Treat warnings as errors

# Rustfmt (форматтер)
make {{MODULE_NAME}} cargo fmt
make {{MODULE_NAME}} cargo fmt -- --check  # Проверка без изменений

# Проверка компиляции без сборки
make {{MODULE_NAME}} cargo check
```

## Структура

```
.
├── src/              # Исходный код Rust
│   ├── main.rs       # Точка входа (для bin)
│   └── lib.rs        # Библиотека (для lib)
├── tests/            # Интеграционные тесты
├── benches/          # Бенчмарки
├── examples/         # Примеры использования
├── Cargo.toml        # Манифест проекта
├── Cargo.lock        # Lockfile
├── rustfmt.toml      # Конфигурация форматтера
└── README.md         # Документация
```

## Дополнительные команды

```bash
# Добавить зависимость
make {{MODULE_NAME}} cargo add <crate>
make {{MODULE_NAME}} cargo add --dev <crate>

# Обновить зависимости
make {{MODULE_NAME}} cargo update

# Генерация документации
make {{MODULE_NAME}} cargo doc
make {{MODULE_NAME}} cargo doc --open  # Открыть в браузере

# Проверка устаревших зависимостей
make {{MODULE_NAME}} cargo outdated

# Аудит безопасности
make {{MODULE_NAME}} cargo audit

# Очистка артефактов
make {{MODULE_NAME}} cargo clean
```

## Dioxus специфичные команды

Если это Dioxus проект:

```bash
# Dev сервер с hot reload
make {{MODULE_NAME}} cargo run

# Сборка для web
make {{MODULE_NAME}} cargo build --target wasm32-unknown-unknown

# Релизная сборка
make {{MODULE_NAME}} cargo build --release
```
