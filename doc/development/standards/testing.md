# Стандарты автоматического тестирования

Требования к автотестам для поддержания качества кода.

---

## Принципы FIRST

| Принцип | Описание |
|---------|----------|
| **Fast** | Unit < 100ms, Integration < 1s |
| **Isolated** | Независимые, порядок не важен |
| **Repeatable** | Одинаковый результат при повторах |
| **Self-Validating** | Явный pass/fail без ручной проверки |
| **Timely** | Писать до кода (TDD) или одновременно |

---

## Пирамида тестов

```
      /\
     /  \    E2E (5-10%)
    /────\   Критичные user flows
   /      \
  /────────\  Integration (20-30%)
 /          \ Компоненты + API
/────────────\
   Unit (60-70%)
   Функции, утилиты, хуки
```

**Распределение усилий:** 60-70% Unit / 20-30% Integration / 5-10% E2E

---

## Типы тестов

| Тип | Что тестировать | Инструменты | Пример |
|-----|-----------------|-------------|--------|
| **Unit** | Функции, утилиты, хуки, валидаторы | Jest | Чистые функции без зависимостей |
| **Integration** | Компоненты с API, модули | Jest + RTL + MSW | React компонент с API вызовами |
| **E2E** | Критичные user flows | Playwright | Регистрация, оплата, checkout |

### Примеры

**Unit тест:**
```typescript
describe('formatCurrency', () => {
  it('форматирует USD по умолчанию', () => {
    expect(formatCurrency(100)).toBe('$100.00');
  });

  it('поддерживает разные валюты', () => {
    expect(formatCurrency(100, 'EUR')).toBe('€100.00');
  });
});
```

**Integration тест:**
```typescript
import { render, screen, waitFor } from '@testing-library/react';

it('загружает и отображает пользователя', async () => {
  render(<UserProfile userId="123" />);

  await waitFor(() => {
    expect(screen.getByText('John Doe')).toBeInTheDocument();
  });
});
```

**E2E тест:**
```typescript
import { test, expect } from '@playwright/test';

test('регистрация пользователя', async ({ page }) => {
  await page.goto('/signup');
  await page.fill('[name="email"]', 'test@example.com');
  await page.click('button[type="submit"]');

  await expect(page).toHaveURL('/dashboard');
});
```

---

## Структура и именование

### Организация файлов

```
apps/site/
├── app/                          # Next.js код
├── components/                   # React компоненты
├── lib/                          # Утилиты
└── tests/
    ├── unit/                     # Unit тесты
    │   └── example.test.tsx
    ├── integration/              # Integration тесты
    └── e2e/                      # E2E тесты (Playwright)
        └── homepage.spec.ts

apps/application/
├── app/                          # Expo код
├── src/                          # Компоненты и утилиты
└── tests/
    ├── unit/                     # Unit тесты
    ├── integration/              # Integration тесты
    └── e2e/                      # E2E тесты (опционально)
```

**Правила:**
- Unit/Integration: `tests/unit/`, `tests/integration/` в каждом app
- E2E: `tests/e2e/` в каждом app (Playwright ищет через glob)

### Именование

| Элемент | Формат | Пример |
|---------|--------|--------|
| Unit/Integration файл | `[name].test.ts` в `tests/unit/` или `tests/integration/` | `example.test.tsx` |
| E2E файл | `[name].spec.ts` в `tests/e2e/` | `homepage.spec.ts` |
| Describe | Имя тестируемой сущности | `describe('formatCurrency')` |
| It | Поведение в настоящем времени | `it('бросает ошибку при делении на 0')` |

**✅ Хорошо:**
- `it('бросает ошибку при невалидном email')`
- `it('отключается при loading состоянии')`

**❌ Плохо:**
- `it('работает')` / `it('test 1')` / `it('should work')`

---

## Паттерны тестирования

### AAA (Arrange-Act-Assert)

```typescript
it('добавляет товар в корзину', () => {
  // Arrange
  const cart = new ShoppingCart();
  const item = { id: '1', price: 10 };

  // Act
  cart.addItem(item);

  // Assert
  expect(cart.items).toHaveLength(1);
  expect(cart.total).toBe(10);
});
```

---

## Моки и стабы

### Мокирование модулей (Jest)

```typescript
jest.mock('./api', () => ({
  fetchUser: jest.fn().mockResolvedValue({ id: '1', name: 'John' }),
}));

it('использует мок', async () => {
  const user = await api.fetchUser('1');
  expect(api.fetchUser).toHaveBeenCalledWith('1');
});
```

### MSW для HTTP моков

```typescript
// mocks/handlers.ts
import { http, HttpResponse } from 'msw';

export const handlers = [
  http.get('/api/users/:id', ({ params }) => {
    return HttpResponse.json({ id: params.id, name: 'John' });
  }),
];

// setupTests.ts
import { setupServer } from 'msw/node';
const server = setupServer(...handlers);

beforeAll(() => server.listen());
afterEach(() => server.resetHandlers());
afterAll(() => server.close());
```

---

## Best Practices

| Практика | Рекомендация |
|----------|--------------|
| **DRY в тестах** | ⚠️ Дублирование допустимо для читаемости |
| **Assert'ы** | ✅ Несколько логически связанных assert'ов в одном тесте |
| **Test fixtures** | ✅ Выносить данные в `tests/fixtures/` или `mocks/` |
| **Cleanup** | ✅ `afterEach` для очистки моков |
| **Async** | ✅ Всегда `async/await`, не колбеки |
| **Snapshots** | ⚠️ С осторожностью (хрупкие, сложно review) |

---

## Coverage требования

| Метрика | Минимум | Рекомендуемый |
|---------|---------|---------------|
| Statements | 80% | 90% |
| Branches | 75% | 85% |
| Functions | 80% | 90% |
| Lines | 80% | 90% |

**Исключения (не требуют 100%):**
- UI компоненты (критичные сценарии достаточно)
- Типы и интерфейсы
- Конфигурационные файлы
- Trivial getters/setters

**Команды:**
```bash
# Запуск всех тестов в workspace
make test                  # Все unit/integration тесты
pnpm test                  # То же самое

# Запуск тестов для конкретного приложения
make site test             # Тесты для apps/site
make application test      # Тесты для apps/application

# Watch mode
make site test:watch
make application test:watch

# Coverage
make site test:ci          # С coverage для CI
make application test:ci

# E2E тесты (Playwright)
pnpm test:e2e              # Запуск всех E2E тестов
pnpm test:e2e:ui           # Playwright UI mode
pnpm test:e2e:headed       # С видимым браузером
pnpm test:e2e:debug        # Debug mode
```

---

## Конфигурация

### Структура проекта

```
/
├── jest.config.base.js          # Базовая конфигурация Jest для monorepo
├── playwright.config.ts         # Конфигурация Playwright (ищет apps/*/tests/e2e)
├── apps/site/
│   ├── jest.config.js           # Jest конфиг (использует next/jest preset)
│   ├── jest.setup.js            # Setup файл для @testing-library/jest-dom
│   └── tests/
│       ├── unit/                # Unit тесты
│       │   └── example.test.tsx
│       ├── integration/         # Integration тесты (пока пусто)
│       └── e2e/                 # E2E тесты (Playwright)
│           └── homepage.spec.ts
└── apps/application/
    ├── jest.config.js           # Jest конфиг (использует jest-expo preset)
    ├── jest.setup.js            # Setup файл для @testing-library/jest-native
    └── tests/
        ├── unit/                # Unit тесты
        │   └── example.test.tsx
        └── integration/         # Integration тесты (пока пусто)
```

### Jest для Next.js (apps/site)

```javascript
const nextJest = require('@next/jest');

const createJestConfig = nextJest({
  dir: './',
});

const customJestConfig = {
  ...require('../../jest.config.base.js').default,
  setupFilesAfterEnv: ['<rootDir>/jest.setup.js'],
  testEnvironment: 'jest-environment-jsdom',
  moduleNameMapper: {
    '^@/(.*)$': '<rootDir>/$1',
  },
};

module.exports = createJestConfig(customJestConfig);
```

### Jest для Expo (apps/application)

```javascript
module.exports = {
  preset: 'jest-expo',
  setupFilesAfterEnv: ['<rootDir>/jest.setup.js'],
  transformIgnorePatterns: [
    'node_modules/(?!((jest-)?react-native|@react-native(-community)?)|expo(nent)?|@expo(nent)?/.*)',
  ],
  moduleNameMapper: {
    '^@/(.*)$': '<rootDir>/$1',
  },
};
```

### Playwright для E2E

```typescript
import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  // E2E тесты распределены по приложениям
  testMatch: '**/apps/*/tests/e2e/**/*.spec.ts',

  timeout: 30 * 1000,
  use: {
    baseURL: process.env.BASE_URL || 'http://localhost:3000',
    trace: 'on-first-retry',
  },
  projects: [
    { name: 'chromium', use: { ...devices['Desktop Chrome'] } },
    { name: 'firefox', use: { ...devices['Desktop Firefox'] } },
    { name: 'Mobile Chrome', use: { ...devices['Pixel 5'] } },
  ],
  webServer: {
    command: 'pnpm site:dev',
    url: 'http://localhost:3000',
    reuseExistingServer: !process.env.CI,
  },
});
```

---

## Что тестировать

| ✅ Тестировать | ❌ Не тестировать |
|---------------|------------------|
| Бизнес-логика и алгоритмы | Тривиальные геттеры/сеттеры |
| Валидация и обработка ошибок | Внешние библиотеки |
| Утилиты и хелперы | UI стили и CSS |
| Критичные user flows | Автогенерированный код |
| Граничные случаи | Прототипы и эксперименты |
| API эндпоинты | — |

---

## Чеклист перед коммитом

- [ ] Новые функции покрыты unit тестами
- [ ] Критичная логика имеет граничные случаи
- [ ] `pnpm test` проходит локально
- [ ] Coverage не упал ниже порога
- [ ] Нет `it.skip` или `it.only`
- [ ] Моки очищаются в `afterEach`
- [ ] Тесты независимы друг от друга

---

## Полезные паттерны

### Тестирование ошибок

```typescript
it('бросает ошибку при делении на 0', () => {
  expect(() => divide(10, 0)).toThrow('Division by zero');
});

// Для async функций
it('бросает ошибку при невалидных данных', async () => {
  await expect(processData(null)).rejects.toThrow('Invalid data');
});
```

### Тестирование async кода

```typescript
it('загружает данные', async () => {
  const data = await fetchData();
  expect(data).toBeDefined();
});
```

### Тестирование событий

```typescript
import { fireEvent } from '@testing-library/react';

it('вызывает onClick', () => {
  const handleClick = jest.fn();
  render(<Button onClick={handleClick} />);

  fireEvent.click(screen.getByRole('button'));

  expect(handleClick).toHaveBeenCalledTimes(1);
});
```

---

## См. также

- [Стандарты исходного кода](./source-code.md)
- [Принципы проектирования](./engineering.md)
- [Jest Documentation](https://jestjs.io/)
- [React Testing Library](https://testing-library.com/react)
- [React Native Testing Library](https://callstack.github.io/react-native-testing-library/)
- [Playwright Documentation](https://playwright.dev/)
- [Testing with Next.js](https://nextjs.org/docs/testing#setting-up-jest)
- [Testing with Expo](https://docs.expo.dev/guides/testing-with-jest/)

---

**Версия:** 1.2
**Обновлено:** 2025-10-20
