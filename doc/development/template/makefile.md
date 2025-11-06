# Система автоматизации Makefile

Минимальная система команд для управления polyglot workspace и модулями.

## Содержание

- [Быстрый старт](#быстрый-старт)
- [Глобальные команды](#глобальные-команды)
- [Команды модулей](#команды-модулей)
- [Создание Makefile модуля](#создание-makefile-модуля)
- [Архитектура](#архитектура)

## Быстрый старт

```bash
# Создать новый модуль (интерактивно)
make module

# Или с параметрами
make module MODULE_STACK=nodejs MODULE_TYPE=bun MODULE_NAME=my-service

# Работа с конкретным модулем (автоопределение технологий)
make mymodule                    # Справка с найденными технологиями
make mymodule bun install        # Команда пакетного менеджера
make mymodule npm test           # Запуск тестов через npm
make mymodule composer require   # Установка PHP пакета

# Если в модуле есть Makefile
make mymodule test               # Makefile команда

# Справка
make help
```

## Глобальные команды

### Создание модулей

#### `make module`
Создание нового модуля проекта с интерактивным выбором стека и типа.

**Интерактивное использование:**
```bash
make module
# → Выбор стека: Node.js, PHP, Python, Rust
# → Выбор типа проекта
# → Ввод имени модуля
# → Автоматическая инициализация
```

**С параметрами (для автоматизации):**
```bash
# Node.js проекты
make module MODULE_STACK=nodejs MODULE_TYPE=bun MODULE_NAME=my-service
make module MODULE_STACK=nodejs MODULE_TYPE=npm MODULE_NAME=my-lib
make module MODULE_STACK=nodejs MODULE_TYPE=nextjs MODULE_NAME=my-app
make module MODULE_STACK=nodejs MODULE_TYPE=expo MODULE_NAME=mobile-app
make module MODULE_STACK=nodejs MODULE_TYPE=svelte MODULE_NAME=web-ui

# PHP проекты
make module MODULE_STACK=php MODULE_TYPE=composer-lib MODULE_NAME=my-lib
make module MODULE_STACK=php MODULE_TYPE=laravel MODULE_NAME=api

# Python проекты
make module MODULE_STACK=python MODULE_TYPE=uv MODULE_NAME=data-processor
make module MODULE_STACK=python MODULE_TYPE=poetry MODULE_NAME=ml-model

# Rust проекты
make module MODULE_STACK=rust MODULE_TYPE=bin MODULE_NAME=cli-tool
make module MODULE_STACK=rust MODULE_TYPE=lib MODULE_NAME=shared-lib
make module MODULE_STACK=rust MODULE_TYPE=dioxus MODULE_NAME=web-ui
```

**Поддерживаемые типы модулей:**

**Node.js** (`MODULE_STACK=nodejs`):
- `bun` - TypeScript проект с Bun
- `npm` - проект с npm
- `pnpm` - проект с pnpm
- `yarn` - проект с Yarn
- `nextjs` - Next.js приложение с TypeScript и Tailwind
- `expo` - React Native приложение с Expo
- `svelte` - SvelteKit приложение

**PHP** (`MODULE_STACK=php`):
- `composer-lib` - Composer библиотека
- `composer-project` - Composer проект
- `laravel` - Laravel приложение

**Python** (`MODULE_STACK=python`):
- `uv` - проект с UV (быстрый, рекомендуется)
- `poetry` - проект с Poetry

**Rust** (`MODULE_STACK=rust`):
- `bin` - исполняемое приложение
- `lib` - библиотека
- `dioxus` - веб-приложение на Dioxus

**Параметры:**
- `MODULE_STACK` - технологический стек (nodejs, php, python, rust)
- `MODULE_TYPE` - тип проекта (см. выше)
- `MODULE_NAME` - имя модуля (буквы, цифры, дефис, подчеркивание)
- `MODULE_TARGET` - директория для создания (по умолчанию `modules`)

**Примеры:**
```bash
# Создать Next.js приложение
make module MODULE_STACK=nodejs MODULE_TYPE=nextjs MODULE_NAME=frontend

# Создать Laravel API
make module MODULE_STACK=php MODULE_TYPE=laravel MODULE_NAME=api

# Создать Python библиотеку с Poetry
make module MODULE_STACK=python MODULE_TYPE=poetry MODULE_NAME=data-lib

# Создать Rust CLI инструмент
make module MODULE_STACK=rust MODULE_TYPE=bin MODULE_NAME=deploy-tool
```

## Команды модулей

### Автоопределение технологий

Система автоматически определяет технологии модуля по маркерным файлам:
- **Node.js** - наличие `package.json`
- **PHP** - наличие `composer.json`
- **Python** - наличие `pyproject.toml`, `requirements.txt` или `setup.py`
- **Rust** - наличие `Cargo.toml`
- **Makefile** - наличие `Makefile`
- **GitLab CI** - наличие `.gitlab-ci.yml`
- **GitHub Actions** - наличие `.github/workflows/`

### Синтаксис

```bash
make <модуль>                            # Показать справку по модулю с найденными технологиями
make <модуль> <пакетный-менеджер> <cmd>  # Выполнить команду пакетного менеджера
make <модуль> <makefile-команда>         # Выполнить Makefile команду (если есть Makefile)
```

### Поддерживаемые пакетные менеджеры

**Node.js:**
- `npm` - package-lock.json
- `yarn` - yarn.lock
- `pnpm` - pnpm-lock.yaml
- `bun` - bun.lockb (по умолчанию)

**Python:**
- `pip` - requirements.txt
- `poetry` - poetry.lock
- `pipenv` - Pipfile
- `uv` - uv.lock (по умолчанию)

**PHP:**
- `composer` - composer.json

**Rust:**
- `cargo` - Cargo.toml

**Автоопределение пакетного менеджера:**
Система определяет основной пакетный менеджер по наличию lock файлов. Если lock файл не найден, используется менеджер по умолчанию (bun для Node.js, uv для Python).

### Примеры с пакетными менеджерами

```bash
# Справка по модулю myservice (покажет найденные технологии)
make myservice

# Node.js проект
make myservice bun install         # Установить зависимости через bun
make myservice bun run dev         # Запустить dev сервер
make myservice npm test            # Запустить тесты через npm
make myservice pnpm build          # Собрать проект через pnpm

# PHP проект
make myservice composer install    # Установить зависимости
make myservice composer test       # Запустить тесты
make myservice composer require laravel/framework

# Python проект
make myservice uv pip install -r requirements.txt
make myservice poetry install      # Установить зависимости через poetry
make myservice pip install pytest  # Установить пакет через pip
make myservice uv run main.py      # Запустить скрипт через uv

# Rust проект
make myservice cargo build         # Собрать проект
make myservice cargo test          # Запустить тесты
make myservice cargo run           # Запустить приложение
```

### Примеры с Makefile

Если в модуле есть Makefile, можно вызывать его команды напрямую:

```bash
# Запустить тесты через Makefile модуля
make myservice test

# Собрать проект
make myservice build

# Запустить в dev режиме
make myservice dev

# Линтинг
make myservice lint

# Очистка артефактов
make myservice clean
```

**Примечание:** Все команды выполняются внутри контейнера. Система автоматически определяет контекст и делегирует команду в контейнер при необходимости.

## Создание модулей

### Модуль без Makefile (только пакетные менеджеры)

Для многих модулей не нужен Makefile - система автоматически определит технологию и предоставит доступ к пакетным менеджерам:

```bash
# Создать Node.js модуль
mkdir -p modules/myapp
cd modules/myapp
echo '{"name": "myapp"}' > package.json

# Теперь доступны команды:
make myapp                       # Показать справку
make myapp bun install           # Использовать bun
make myapp npm install           # Использовать npm
```

```bash
# Создать Python модуль
mkdir -p modules/ml-service
cd modules/ml-service
echo 'fastapi' > requirements.txt

# Теперь доступны команды:
make ml-service                              # Показать справку
make ml-service pip install -r requirements.txt
make ml-service uv pip install fastapi
```

### Создание Makefile модуля (для сложной автоматизации)

Если модулю нужны кастомные команды (например, составные операции), создайте Makefile:

#### Базовая структура

```makefile
# modules/myservice/Makefile

.DEFAULT_GOAL := help

## test: Запуск тестов
test:
	@echo "Запуск тестов myservice..."
	npm test

## build: Сборка проекта
build:
	@echo "Сборка myservice..."
	npm run build

## lint: Линтинг кода
lint:
	@echo "Линтинг myservice..."
	eslint src/

## dev: Запуск в dev режиме
dev:
	@echo "Dev режим myservice..."
	npm run dev

## help: Показать эту справку
help:
	@echo "Доступные команды myservice:"
	@grep -E '^## ' $(MAKEFILE_LIST) | sed 's/^## /  /' | \
		awk 'BEGIN {FS = ": "}; {printf "  %-12s %s\n", $$1, $$2}'
```

### Рекомендуемые команды

Для единообразия рекомендуется реализовывать следующие команды в модулях:

- `test` - запуск тестов
- `build` - сборка проекта
- `lint` - линтинг кода
- `format` - автоформатирование
- `dev` - запуск в dev режиме
- `clean` - очистка артефактов
- `help` - справка по командам модуля

Каждый модуль решает сам, какие команды ему нужны.

## Архитектура

> **Примечание:** Ранее workspace предоставлял переиспользуемые Make-функции (log-*, ask-*, check-command) через `.template/makefiles/functions.mk`. Эти функции были перенесены в shell-скрипты (`.template/scripts/lib/`) для лучшей модульности и поддерживаемости. См. [coding-style.md](coding-style.md) для правил оформления скриптов.

### Структура файлов

```
Makefile                               # Главный файл (include .template/makefiles/*.mk)
.template/
├── makefiles/                         # Модули системы автоматизации
│   ├── config.mk                      # Конфигурация, переменные, универсальная функция run-script
│   ├── core.mk                        # Базовые команды (делегируют в scripts)
│   ├── devenv.mk                      # Управление шаблоном (делегирует в scripts)
│   ├── modules.mk                     # Работа с модулями (делегирует в scripts)
│   └── help.mk                        # Система справки с секциями и приоритетами
└── scripts/                           # Вся бизнес-логика в shell-скриптах
    ├── lib/                           # Переиспользуемые библиотеки
    │   ├── ui.sh                      # Функции UI (логирование, интерактив, меню)
    │   ├── stack-runner.sh            # Запуск инструментов стеков (host-first + container-fallback)
    │   ├── shellcheck.sh              # Shell-утилиты (shellcheck, jq, yq)
    │   ├── git.sh                     # Git операции (версии, теги)
    │   ├── template.sh                # Операции с шаблоном
    │   ├── modules.sh                 # Операции с модулями (детектирование, версии)
    │   └── generator.sh               # Запуск генераторов модулей
    ├── module/                        # Команды управления модулями
    │   ├── command.sh                 # Выполнение команд модулей (система приоритетов)
    │   ├── create.sh                  # Создание новых модулей (wizard)
    │   ├── git.sh                     # Git операции с модулями
    │   ├── help.sh                    # Справка по командам модулей
    │   ├── import.sh                  # Импорт модулей из git
    │   └── generators/                # Генераторы для разных стеков
    │       ├── nodejs.sh              # Генератор Node.js модулей
    │       ├── php.sh                 # Генератор PHP модулей
    │       ├── python.sh              # Генератор Python модулей
    │       ├── rust.sh                # Генератор Rust модулей
    │       ├── c.sh                   # Генератор C модулей
    │       └── zig.sh                 # Генератор Zig модулей
    ├── template/                      # Команды управления шаблоном
    │   ├── help.sh                    # Справка по командам шаблона
    │   ├── test.sh                    # Автотесты шаблона (shellcheck + smoke tests)
    │   └── update.sh                  # Обновление шаблона из upstream
    ├── help.sh                        # Главная справка (make help)
    └── init.sh                        # Инициализация проекта из шаблона
```

### Принципы работы

**1. Автоопределение технологий**

Система сканирует модули и определяет технологии по маркерным файлам:
- Определяет основной пакетный менеджер по lock файлам
- Предоставляет доступ ко всем установленным пакетным менеджерам
- Показывает найденные технологии в справке модуля

**2. Делегирование на модули**

Команды модулей работают двумя способами:
- `make <модуль> <пакетный-менеджер> <cmd>` → выполняет команду через указанный менеджер
- `make <модуль> <команда>` → делегирует в Makefile модуля (если существует)

**3. Минимализм**

Система предоставляет только базовые команды управления средой и доступ к пакетным менеджерам. Модули не обязаны иметь Makefile - достаточно маркерных файлов технологии.

### Docker/Podman совместимость

Система автоматически определяет доступный container runtime (docker или podman) и использует его. Предупреждения podman-compose подавляются через переменную окружения `PODMAN_COMPOSE_WARNING_LOGS=0`.

### VS Code интеграция

Система совместима с VS Code Remote Containers:
- VS Code и docker compose используют один образ из GHCR
- Команды работают как внутри VS Code контейнера, так и снаружи
- Нет конфликтов между режимами работы

## Troubleshooting

### Команда модуля не работает

```bash
# Проверить найденные технологии
make mymodule

# Если модуль не обнаружен, проверить наличие маркерных файлов
ls -la modules/mymodule/
# Должен быть хотя бы один: package.json, composer.json, Cargo.toml, requirements.txt, pyproject.toml, Makefile

# Для команд пакетных менеджеров
make mymodule bun install  # Используйте полный синтаксис с менеджером

# Для Makefile команд
ls -la modules/mymodule/Makefile  # Проверить что Makefile существует
make mymodule help                # Проверить доступные команды
```

## Дополнительные ресурсы

- [generators.md](generators.md) - Децентрализованные генераторы модулей
- [file-tree.md](file-tree.md) - Структура проекта
