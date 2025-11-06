# {{MODULE_NAME}}

Python модуль workspace, созданный автоматически.

## Технологический стек

- **Стек**: Python
- **Тип**: {{TYPE}}
- **Пакетный менеджер**: Определяется автоматически (uv, poetry, pip)

## Установка зависимостей

```bash
# Из корня workspace
make {{MODULE_NAME}} uv sync           # Используя UV (рекомендуется)
make {{MODULE_NAME}} poetry install    # Используя Poetry
make {{MODULE_NAME}} pip install -r requirements.txt  # Используя pip
```

## Разработка

Этот модуль является частью polyglot workspace и разрабатывается с использованием host-first подхода (инструменты запускаются на хосте, если доступны, иначе в Alpine контейнере).

### Запуск скриптов

```bash
# Используя UV
make {{MODULE_NAME}} uv run python main.py
make {{MODULE_NAME}} uv run <script-name>

# Используя Poetry
make {{MODULE_NAME}} poetry run python main.py
make {{MODULE_NAME}} poetry run <script-name>
```

### Тестирование

```bash
# pytest
make {{MODULE_NAME}} uv run pytest
make {{MODULE_NAME}} poetry run pytest
```

### Линтинг и форматирование

```bash
# Ruff (быстрый линтер и форматтер)
make {{MODULE_NAME}} uv run ruff check .
make {{MODULE_NAME}} uv run ruff format .

# Flake8
make {{MODULE_NAME}} uv run flake8 src/

# Black (форматтер)
make {{MODULE_NAME}} uv run black src/

# mypy (проверка типов)
make {{MODULE_NAME}} uv run mypy src/
```

## Структура

```
.
├── src/              # Исходный код Python
│   └── {{MODULE_NAME}}/
├── tests/            # Тесты (pytest)
├── pyproject.toml    # Конфигурация проекта (PEP 621 или Poetry)
├── uv.lock           # Lockfile (UV)
├── poetry.lock       # Lockfile (Poetry)
├── requirements.txt  # Зависимости (pip)
├── .flake8           # Конфигурация Flake8
├── ruff.toml         # Конфигурация Ruff
└── README.md         # Документация
```

## Доступные скрипты

### UV проекты

См. секцию `[project.scripts]` в `pyproject.toml` для console_scripts entry points.

### Poetry проекты

См. секцию `[tool.poetry.scripts]` в `pyproject.toml` для доступных команд.

## Дополнительные команды

```bash
# Добавить зависимость (UV)
make {{MODULE_NAME}} uv add <package>
make {{MODULE_NAME}} uv add --dev <package>

# Добавить зависимость (Poetry)
make {{MODULE_NAME}} poetry add <package>
make {{MODULE_NAME}} poetry add --group dev <package>

# Обновить зависимости
make {{MODULE_NAME}} uv sync --upgrade
make {{MODULE_NAME}} poetry update

# Информация об окружении
make {{MODULE_NAME}} uv pip list
make {{MODULE_NAME}} poetry show
```
