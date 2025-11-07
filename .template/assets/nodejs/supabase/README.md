# {{MODULE_NAME}}

Supabase Backend модуль для разработки миграций, Edge Functions и типов.

## Технологический стек

- **Стек**: Node.js / TypeScript
- **Тип**: Supabase Backend
- **Пакетный менеджер**: Bun
- **Backend**: Supabase (PostgreSQL + Auth + Storage + Edge Functions)

## Установка

Все зависимости уже установлены при создании модуля.

## Локальная разработка

### Запуск Supabase стека

```bash
# Из корня workspace
make {{MODULE_NAME}} bun run start

# Будут запущены все сервисы Supabase локально:
# - PostgreSQL (порт 54322)
# - API Server (порт 54321)
# - Studio (порт 54323)
# - Auth, Storage, Realtime и другие
```

### Остановка сервисов

```bash
make {{MODULE_NAME}} bun run stop
```

### Проверка статуса

```bash
make {{MODULE_NAME}} bun run status
```

После первого запуска вы получите credentials для доступа к локальным сервисам.

## Работа с базой данных

### Создание миграции

```bash
make {{MODULE_NAME}} bun run migration:new <имя_миграции>
```

Это создаст новый SQL файл в `supabase/migrations/`.

### Применение миграций на удалённый сервер

```bash
make {{MODULE_NAME}} bun run db:push
```

### Откат к чистой БД (применить все миграции заново)

```bash
make {{MODULE_NAME}} bun run db:reset
```

### Загрузка схемы из удалённой БД

```bash
make {{MODULE_NAME}} bun run db:pull
```

## Генерация TypeScript типов

```bash
make {{MODULE_NAME}} bun run types:gen
```

Типы сохраняются в `types/supabase.ts` и соответствуют схеме вашей локальной БД.

## Edge Functions

Edge Functions - это serverless функции на Deno, работающие близко к пользователям.

### Локальная разработка

```bash
make {{MODULE_NAME}} bun run functions:serve
```

### Деплой функций

```bash
make {{MODULE_NAME}} bun run functions:deploy
```

## Структура проекта

```
.
├── package.json         # Зависимости и скрипты
├── .gitignore          # Исключения для Git
├── .eslintrc.json      # Конфигурация ESLint
├── .prettierrc         # Конфигурация Prettier
├── tsconfig.json       # Конфигурация TypeScript
├── types/              # Сгенерированные типы (gitignored)
│   └── supabase.ts
└── supabase/           # Конфигурация Supabase
    ├── config.toml     # Основная конфигурация
    ├── migrations/     # SQL миграции
    ├── functions/      # Edge Functions (Deno)
    └── seed.sql        # Seed данные
```

## Доступные скрипты

| Скрипт | Описание |
|--------|----------|
| `start` | Запустить локальный Supabase стек |
| `stop` | Остановить локальный стек |
| `status` | Показать статус сервисов |
| `db:pull` | Загрузить схему из удалённой БД |
| `db:push` | Применить миграции на удалённый сервер |
| `db:reset` | Пересоздать локальную БД |
| `migration:new` | Создать новую миграцию |
| `types:gen` | Сгенерировать TypeScript типы |
| `functions:serve` | Запустить Edge Functions локально |
| `functions:deploy` | Задеплоить Edge Functions |

## Подключение к удалённому проекту

1. Создайте проект на [supabase.com](https://supabase.com)
2. Получите Project ID из дашборда
3. Выполните:

```bash
make {{MODULE_NAME}} bunx supabase login
make {{MODULE_NAME}} bunx supabase link --project-ref <PROJECT_ID>
```

## Переменные окружения

Создайте файл `.env.local` в корне модуля:

```env
SUPABASE_URL=http://localhost:54321
SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
```

⚠️ **Важно**: Никогда не коммитьте `.env` файлы с реальными credentials!

## Дополнительно

- [Документация Supabase](https://supabase.com/docs)
- [Supabase CLI](https://supabase.com/docs/reference/cli)
- [Edge Functions](https://supabase.com/docs/guides/functions)
- [Database Migrations](https://supabase.com/docs/guides/cli/local-development)
