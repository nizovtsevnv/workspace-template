# {{MODULE_NAME}}

Node.js модуль workspace, созданный автоматически.

## Технологический стек

- **Стек**: Node.js / TypeScript
- **Тип**: {{TYPE}}
- **Пакетный менеджер**: Определяется автоматически (bun, npm, pnpm, yarn)

## Установка зависимостей

```bash
# Из корня workspace
make {{MODULE_NAME}} bun install    # Используя Bun
make {{MODULE_NAME}} npm install    # Используя npm
make {{MODULE_NAME}} pnpm install   # Используя pnpm
make {{MODULE_NAME}} yarn install   # Используя Yarn
```

## Разработка

Этот модуль является частью polyglot workspace и разрабатывается с использованием host-first подхода (инструменты запускаются на хосте, если доступны, иначе в Alpine контейнере).

### Запуск в dev режиме

```bash
make {{MODULE_NAME}} bun run dev
# или
make {{MODULE_NAME}} npm run dev
```

### Сборка

```bash
make {{MODULE_NAME}} bun run build
# или
make {{MODULE_NAME}} npm run build
```

### Тестирование

```bash
make {{MODULE_NAME}} bun test
# или
make {{MODULE_NAME}} npm test
```

### Линтинг

```bash
make {{MODULE_NAME}} bun run lint
# или
make {{MODULE_NAME}} npm run lint
```

## Структура

```
.
├── src/              # Исходный код TypeScript
├── tests/            # Тесты
├── package.json      # Зависимости и скрипты
├── tsconfig.json     # Конфигурация TypeScript
├── .eslintrc.json    # Конфигурация ESLint
├── .prettierrc       # Конфигурация Prettier
└── README.md         # Документация
```

## Доступные скрипты

См. секцию `scripts` в `package.json` для полного списка доступных команд.

## Дополнительные команды

```bash
# Добавить зависимость
make {{MODULE_NAME}} bun add <package>

# Добавить dev зависимость
make {{MODULE_NAME}} bun add -d <package>

# Обновить зависимости
make {{MODULE_NAME}} bun update

# Запустить произвольный скрипт
make {{MODULE_NAME}} bun run <script-name>
```
