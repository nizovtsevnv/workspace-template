# Стандарты исходного кода

Требования к синтаксису, стилю и организации исходного кода для Node.js
TypeScript (Next.js, Expo, Prisma).

---

## 1. TypeScript

### Конфигурация

- ✅ Strict mode: `strict: true`, `noImplicitAny: true`,
  `strictNullChecks: true`
- ✅ `noUnusedLocals`, `noUnusedParameters`, `noImplicitReturns`

### Типизация

- ✅ Явно типизировать параметры функций и return types
- ✅ Позволять TypeScript выводить типы локальных переменных
- ❌ Никогда `any` → использовать `unknown` + type guards
- ✅ `interface` для объектов, `type` для unions/intersections
- ❌ Избегать `enum` → предпочитать `const` objects с `as const`
- ✅ Использовать Utility Types: `Partial`, `Pick`, `Omit`, `Record`,
  `Required`, `Readonly`

### Именование

- **Types/Interfaces:** `PascalCase`
- **Variables/Functions:** `camelCase`
- **Constants (global):** `UPPER_SNAKE_CASE`
- **Constants (local):** `camelCase`
- **Components:** `PascalCase`
- **Private fields:** `_prefix` (optional)

---

## 2. Структура Файлов

### Именование файлов

- **Components:** `PascalCase.tsx` или `kebab-case.tsx` (консистентно)
- **Hooks:** `camelCase.ts` или `kebab-case.ts`
- **Utils:** `camelCase.ts` или `kebab-case.ts`
- **Types:** `types.ts`, `schema.ts`, `interfaces.ts`
- **Tests:** `*.test.ts` или `*.spec.ts`

### Порядок импортов

1. External packages (react, next, prisma)
2. Internal absolute (@/components, @/hooks)
3. Relative (./Component, ../utils)
4. Styles (\*.module.css)
5. Types (import type)

### Структура внутри файла

1. Imports
2. Types/Interfaces
3. Constants
4. Helper functions (private)
5. Main export (component/function)
6. Additional exports

### Правила организации

- ✅ Один главный export на файл
- ✅ Barrel exports (`index.ts`) допустимы, но осторожно
- ✅ Types экспортировать рядом с компонентом

---

## 3. React/React Native Компоненты

### Структура

- ✅ Только functional components с hooks
- ❌ Никаких class components
- ✅ Props interface с суффиксом `Props` перед компонентом
- ✅ Деструктуризация props в параметрах с default values

```typescript
interface ButtonProps {
  label: string;
  onClick: () => void;
  disabled?: boolean;
}

export const Button: FC<ButtonProps> = ({
  label,
  onClick,
  disabled = false,
}) => {
  // ...
};
```

### Порядок внутри компонента

1. State hooks (`useState`, `useReducer`)
2. Refs (`useRef`)
3. Context (`useContext`, `useTheme`)
4. Custom hooks (`useUser`, `useAuth`)
5. Effects (`useEffect`, `useLayoutEffect`)
6. Event handlers (`handleClick`, `handleChange`)
7. Render/return

### Event handlers

- ✅ Внутри компонента: `handle*` (`handleClick`, `handleSubmit`)
- ✅ В props: `on*` (`onClick`, `onSubmit`)

### JSX

- ✅ Самозакрывающиеся теги без children
- ✅ Props на новых строках если > 3
- ✅ Условный рендеринг: `&&` или тернарный оператор
- ❌ Избегать сложной логики в JSX → выносить в переменные

### React Native

- ✅ `StyleSheet.create` для стилей
- ✅ Styles объект в конце файла

---

## 4. Функции

### Стиль

- ✅ Arrow functions по умолчанию
- ✅ Function declarations для hoisted функций
- ✅ Однострочные arrow без `{}`
- ✅ Явные типы параметров и return value
- ✅ `async/await` вместо `.then()` chains
- ✅ Стремиться к pure functions

```typescript
const calculate = (a: number, b: number): number => a + b;

async function fetchData(id: string): Promise<Data> {
  const response = await fetch(`/api/${id}`);
  return response.json();
}
```

### Типы возвращаемых значений

- ✅ `:void` для функций без возврата
- ✅ `:never` для функций которые всегда throw
- ✅ `:Promise<T>` для async функций

---

## 5. Константы и Переменные

### Объявление

- ✅ `const` по умолчанию
- ✅ `let` только если переназначается
- ❌ Никогда `var`

### Именование

- ✅ `UPPER_SNAKE_CASE` для глобальных констант
- ✅ `camelCase` для локальных констант
- ❌ Не использовать magic numbers/strings → именованные константы

```typescript
const MAX_RETRY_ATTEMPTS = 3;
const DEBOUNCE_DELAY_MS = 500;
const apiUrl = process.env.API_URL;
```

---

## 6. Комментарии

**Язык комментариев: русский**

Все комментарии в коде пишутся на русском языке (JSDoc, inline, TODO, FIXME).

### JSDoc

- ✅ Для публичных API функций и сложной логики
- ✅ Формат: `@param`, `@returns`, `@example`
- ✅ Описания на русском языке

```typescript
/**
 * Вычисляет итоговую цену с налогом
 * @param price - Базовая цена
 * @param taxRate - Налог (0-1)
 * @returns Цена с налогом
 */
export function calculateTotal(price: number, taxRate: number): number {
  return price * (1 + taxRate);
}
```

### Inline комментарии

- ✅ Объяснять "почему", не "что"
- ✅ Только для неочевидных решений
- ❌ Избегать избыточных комментариев
- ✅ Предпочитать самодокументируемый код

### TODO/FIXME

- ✅ Формат: `TODO(username, YYYY-MM-DD): описание`
- ✅ `FIXME`, `HACK`, `NOTE` аналогично

---

## 7. HTML/CSS

### HTML

- ✅ Semantic теги: `<header>`, `<nav>`, `<main>`, `<article>`, `<footer>`
- ❌ Избегать div soup

### CSS Naming

- ✅ CSS Modules: `styles.button`, `styles.container`
- ✅ Tailwind: `className="px-4 py-2 bg-blue-500"`
- ✅ BEM (если без modules): `block__element--modifier`

### Inline Styles

- ❌ Избегать статичные inline styles
- ✅ Только для dynamic значений: `style={{ width: \`${progress}%\` }}`

### CSS-in-JS

- ✅ Styled components в отдельном файле `*.styles.ts`
- ✅ Или в конце основного файла

---

## 8. Prisma Types

### Generated Types

- ✅ Генерировать через Prisma CLI: `make site db generate` или
  `npx prisma generate`
- ✅ Типы автоматически обновляются после изменений схемы

### Model Types

```typescript
import { User, Post } from '@prisma/client';

// Использование сгенерированных типов
const user: User = await prisma.user.findUnique({ where: { id: '1' } });

// Partial типы для updates
type UserUpdate = Partial<User>;

// Omit для создания без автогенерируемых полей
type UserCreate = Omit<User, 'id' | 'createdAt' | 'updatedAt'>;
```

### Query Types

- ✅ Типизировать Prisma client: `const prisma = new PrismaClient()`
- ✅ Использовать сгенерированные типы для include/select
- ✅ Validator types для runtime validation с Prisma

---

## 9. Автотесты

### Файлы

- ✅ `*.test.ts` или `*.spec.ts` рядом с тестируемым файлом
- ✅ `tests/` для интеграционных тестов

### Структура

- ✅ `describe()` для группировки, `it()` или `test()` для тест-кейсов
- ✅ Вложенные `describe()` для подгрупп

```typescript
describe('ComponentName', () => {
  it('should render correctly', () => {
    // test
  });

  describe('edge cases', () => {
    it('should handle empty data', () => {
      // test
    });
  });
});
```

### Test Data

- ✅ Fixtures: префикс `fixture` (`fixtureUser`, `fixtureData`)
- ✅ Mocks: префикс `mock` (`mockFetchUser`, `mockOnClick`)
- ✅ Spies: префикс `spy` (`spyConsoleError`)
- ✅ Test data в начале файла или `mocks/` директория

### Assertions

- ✅ Один главный assertion на тест
- ✅ Связанные assertions допустимы
- ❌ Избегать множество несвязанных assertions

---

## 10. Примеры: ❌ vs ✅

### TypeScript

```typescript
// ❌ any типы
function process(data: any) {}

// ✅ Правильная типизация
interface ProcessData {
  id: string;
  value: number;
}
function process(data: ProcessData) {}
```

### Переменные

```typescript
// ❌ var
var count = 0;

// ✅ const/let
const count = 0;
let mutableCount = 0;
```

### React

```typescript
// ❌ Не типизированный useState
const [data, setData] = useState(null);

// ✅ Типизированный state
const [data, setData] = useState<User | null>(null);

// ❌ Inline callbacks в render
<button onClick={() => handleClick(id)}>

// ✅ useCallback для callbacks
const handleClick = useCallback(() => {}, [deps]);
<button onClick={handleClick}>

// ❌ Мутация props
items.push('new');

// ✅ Immutability
const newItems = [...items, 'new'];
```

### Imports

```typescript
// ❌ Неправильный порядок
import { Button } from './Button';
import { useState } from 'react';

// ✅ Правильный порядок
import { useState } from 'react';
import { Button } from '@/components';
```

### JSX

```typescript
// ❌ Сложная логика в JSX
{users.filter(...).map(...).filter(...) ? <X /> : null}

// ✅ Вынести логику
const filtered = users.filter(u => u.active);
return <div>{filtered.map(u => <Card key={u.id} />)}</div>;
```

### Константы

```typescript
// ❌ Magic numbers
setTimeout(fn, 5000);

// ✅ Именованные константы
const DELAY_MS = 5000;
setTimeout(fn, DELAY_MS);
```

### Комментарии

```typescript
// ❌ Избыточные комментарии
// This adds two numbers
function add(a, b) {
  return a + b;
}

// ✅ Самодокументируемый код
function add(a: number, b: number): number {
  return a + b;
}
```

---

## 11. Code Review Checklist

**Перед commit:**

- [ ] TypeScript strict без ошибок
- [ ] Нет `any` типов
- [ ] Функции типизированы (params + return)
- [ ] Imports упорядочены
- [ ] Naming conventions соблюдены
- [ ] Props деструктурированы
- [ ] Hooks в правильном порядке
- [ ] Event handlers: `handle*`/`on*`
- [ ] Нет magic numbers/strings
- [ ] JSDoc для публичных API
- [ ] Комментарии объясняют "почему"
- [ ] CSS Modules/Tailwind (не inline)
- [ ] Prisma generated types актуальны

---

**Версия:** 1.0 **Обновлено:** 2025-10-17
