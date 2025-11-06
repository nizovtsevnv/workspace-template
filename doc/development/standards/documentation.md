# Стандарты документирования

Требования к документированию кода и API в проекте.

---

## Принципы

**Первичный источник правды** — документация в каталоге `docs/`.

1. **Документация прежде кода** — критичные решения фиксируются в `docs/` до реализации
2. **Актуальность** — документация обновляется вместе с кодом в одном PR
3. **Лаконичность** — краткость важнее полноты, избегать дублирования
4. **Примеры кода** — предпочитать работающий код длинным описаниям
5. **Единый стиль** — следовать формату существующих документов

---

## Что документировать

### ✅ Обязательно

| Что | Пример |
|-----|--------|
| **Публичные функции** | Все экспортируемые функции с `@param`, `@returns`, `@throws` |
| **React компоненты** | Все экспортируемые компоненты с `@example` |
| **API endpoints** | HTTP методы, body, response, коды ошибок |
| **Сложные типы** | Интерфейсы и типы с неочевидным назначением |
| **Утилиты** | Хелперы с описанием параметров и возвращаемых значений |

### ❌ Допустимо не документировать

- Приватные функции (если логика очевидна из названия и типов)
- Тривиальные геттеры/сеттеры
- Тесты (названия должны быть самодокументируемыми)
- Простые алиасы типов (`type UserId = string`)

---

## JSDoc: основы

**Язык документации: русский**

Вся документация в проекте пишется на русском языке:
- JSDoc комментарии
- Markdown документация в `docs/`
- Описания в `@param`, `@returns`, `@throws`
- Примеры в `@example`

### Базовый шаблон

```typescript
/**
 * Краткое описание (одна строка)
 *
 * Подробное описание (опционально).
 *
 * @param paramName - Описание
 * @returns Описание результата
 * @throws {ErrorType} Условие
 * @example
 * const result = myFunction('value');
 */
```

### Основные теги

| Тег | Назначение |
|-----|-----------|
| `@param` | Параметр функции |
| `@returns` | Возвращаемое значение |
| `@throws` | Выбрасываемые ошибки |
| `@example` | Пример использования |
| `@deprecated` | Устаревший код |
| `@see` | Ссылка на связанную документацию |
| `@internal` | Внутренний API |

### Примеры по типам

**Функция:**
```typescript
/**
 * Создаёт пользователя в БД
 * @param email - Email пользователя
 * @param password - Пароль (будет захеширован)
 * @returns ID созданного пользователя
 * @throws {ValidationError} Если email невалиден
 */
export async function createUser(email: string, password: string): Promise<string>
```

**React компонент:**
```typescript
/**
 * Кнопка с поддержкой loading состояния
 * @example
 * <Button onClick={handleSubmit} loading={isSubmitting}>
 *   Отправить
 * </Button>
 */
export const Button: FC<ButtonProps> = ({ children, loading, ...props }) => { /* ... */ }
```

**API endpoint:**
```typescript
/**
 * POST /api/auth/signup
 * Регистрация нового пользователя
 *
 * @body { email: string, password: string }
 * @returns { userId: string, token: string }
 * @throws 400 - Невалидные данные
 * @throws 409 - Email уже занят
 */
export async function POST(request: Request) { /* ... */ }
```

**Deprecated:**
```typescript
/**
 * @deprecated Используйте {@link createUserV2}
 */
export function createUser(data: UserData) { /* ... */ }
```

---

## Структура документации

```
docs/
├── development/           # Процесс разработки
│   ├── environment.md
│   ├── source-code.md
│   ├── project-structure.md
│   └── documentation.md   # Этот файл
├── prd/                   # Product Requirements
├── generated/             # Автогенерируемая документация
│   ├── packages/          # TypeDoc пакетов
│   │   └── [name]-storybook/  # Storybook статика
│   └── apps/              # TypeDoc приложений
│       └── [name]-storybook/  # Storybook статика
└── architecture/          # ADR (опционально)
```

**⚠️ Важно:** `docs/generated/` — автогенерация, в `.gitignore`

### Шаблон markdown документа

```markdown
# Название

Краткое описание (1-2 предложения).

---

## Раздел

Содержание с примерами кода.

---

## См. также

- [Связанный документ](./related.md)
```

---

## Make команды

| Команда | Описание |
|---------|----------|
| `make doc-typedoc` | Генерация TypeDoc для всех packages/apps |
| `make doc-storybook` | Сборка Storybook статики для всех packages/apps |
| `make doc-serve` | HTTP сервер для просмотра (порт 8080) |
| `make doc-clean` | Очистка сгенерированной документации |

**Workflow:**
```bash
make doc-clean       # Очистка
make doc-typedoc     # TypeDoc
make doc-storybook   # Storybook
make doc-serve       # Просмотр на http://localhost:8080
```

---

## Автогенерация документации

### TypeDoc (API документация)

**Установка:**
```bash
cd packages/my-package && pnpm add -D typedoc
```

**Конфигурация `typedoc.json`:**
```json
{
  "entryPoints": ["src/index.ts"],
  "out": "../../docs/generated/packages/my-package",
  "exclude": ["**/*.test.ts", "**/*.spec.ts"],
  "cleanOutputDir": true,
  "name": "my-package"
}
```

**package.json:**
```json
{
  "scripts": {
    "docs:generate": "typedoc"
  }
}
```

**Пути вывода:**
- Packages: `docs/generated/packages/[package-name]/`
- Apps: `docs/generated/apps/[app-name]/`

**Генерация:**
```bash
make doc-typedoc  # Для всех packages и apps
```

### Storybook (UI компоненты)

**Установка:**
```bash
cd packages/my-ui-package && pnpm dlx storybook@latest init
```

**package.json:**
```json
{
  "scripts": {
    "storybook": "storybook dev -p 6006",
    "storybook:build": "storybook build -o ../../docs/generated/packages/my-ui-package-storybook"
  }
}
```

**Story пример:**
```typescript
// Button.stories.tsx
import type { Meta, StoryObj } from '@storybook/react';
import { Button } from './Button';

const meta: Meta<typeof Button> = {
  title: 'UI/Button',
  component: Button,
  tags: ['autodocs'],
};

export default meta;
type Story = StoryObj<typeof Button>;

export const Primary: Story = {
  args: { label: 'Нажми меня', variant: 'primary' },
};
```

**Пути вывода:**
- Packages: `docs/generated/packages/[package-name]-storybook/`
- Apps: `docs/generated/apps/[app-name]-storybook/`

**Генерация:**
```bash
make doc-storybook  # Для всех packages и apps
```

---

## Чеклист перед коммитом

- [ ] Публичные функции имеют JSDoc комментарии
- [ ] Компоненты документированы с `@example`
- [ ] API endpoints описывают body/response/errors
- [ ] Изменения в `docs/` синхронизированы с кодом
- [ ] README.md актуален (если менялся публичный API)
- [ ] `make doc-typedoc` проходит без ошибок (опционально)

---

**Версия:** 1.0
**Обновлено:** 2025-10-18
