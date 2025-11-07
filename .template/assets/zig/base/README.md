# {{MODULE_NAME}}

Zig модуль workspace, созданный автоматически.

## Технологический стек

- **Стек**: Zig
- **Тип**: {{TYPE}}
- **Система сборки**: Zig build system

## Сборка

```bash
# Из корня workspace
make {{MODULE_NAME}} zig build           # Debug сборка
make {{MODULE_NAME}} zig build -Doptimize=ReleaseFast  # Release сборка
```

## Разработка

Этот модуль является частью polyglot workspace и разрабатывается с использованием host-first подхода (инструменты запускаются на хосте, если доступны, иначе в Alpine контейнере).

### Запуск

```bash
make {{MODULE_NAME}} zig build run       # Сборка и запуск
make {{MODULE_NAME}} zig run src/main.zig  # Прямой запуск без build.zig
```

### Тестирование

```bash
make {{MODULE_NAME}} zig build test      # Запуск всех тестов
make {{MODULE_NAME}} zig test src/main.zig  # Тесты конкретного файла
```

### Проверка кода

```bash
# Форматирование
make {{MODULE_NAME}} zig fmt src/        # Форматировать код
make {{MODULE_NAME}} zig fmt --check src/  # Проверка без изменений

# Проверка компиляции
make {{MODULE_NAME}} zig build-exe src/main.zig -fno-emit-bin
```

## Структура

```
.
├── src/              # Исходный код Zig
│   └── main.zig      # Точка входа
├── build.zig         # Система сборки
├── build.zig.zon     # Менеджер зависимостей (Zig 0.11+)
└── README.md         # Документация
```

## Режимы оптимизации

```bash
# Debug (по умолчанию)
make {{MODULE_NAME}} zig build

# ReleaseSafe (оптимизация + проверки)
make {{MODULE_NAME}} zig build -Doptimize=ReleaseSafe

# ReleaseFast (максимальная производительность)
make {{MODULE_NAME}} zig build -Doptimize=ReleaseFast

# ReleaseSmall (минимальный размер)
make {{MODULE_NAME}} zig build -Doptimize=ReleaseSmall
```

## Дополнительные команды

```bash
# Кросс-компиляция
make {{MODULE_NAME}} zig build -Dtarget=x86_64-linux
make {{MODULE_NAME}} zig build -Dtarget=aarch64-macos
make {{MODULE_NAME}} zig build -Dtarget=wasm32-wasi

# Генерация документации
make {{MODULE_NAME}} zig build-lib src/main.zig -femit-docs

# Очистка артефактов
make {{MODULE_NAME}} rm -rf zig-out zig-cache

# Информация о целях сборки
make {{MODULE_NAME}} zig build --help

# Трансляция C кода в Zig
make {{MODULE_NAME}} zig translate-c file.c

# Использование Zig как C компилятора
make {{MODULE_NAME}} zig cc file.c -o output
```

## Зависимости

Начиная с Zig 0.11+, зависимости управляются через `build.zig.zon`:

```bash
# Добавление зависимости (вручную редактируйте build.zig.zon)
# Затем обновите build.zig для подключения зависимости
make {{MODULE_NAME}} zig build
```
