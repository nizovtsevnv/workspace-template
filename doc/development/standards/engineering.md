# Принципы инженерного проектирования

Архитектурные принципы для поддерживаемости и масштабируемости проекта.

---

## Философия простоты

| Принцип | Суть | Применение |
|---------|------|------------|
| **KISS** | Простота превыше всего | Очевидные решения вместо "умных" |
| **YAGNI** | Не добавлять "на будущее" | Код под текущие требования |
| **Бритва Оккама** | Простейшее решение обычно верное | Минимум технологий и абстракций |
| **DRY** | Не дублировать логику | Извлекать повторы в функции |

### Примеры

**KISS — простота:**
```typescript
// ✅ Простое решение
const isEven = (n: number) => n % 2 === 0;

// ❌ Излишне сложное
const isEven = (n: number) => /^-?\d*[02468]$/.test(String(n));
```

**YAGNI — только необходимое:**
```typescript
// ✅ Минимально достаточный интерфейс
interface User {
  id: string;
  email: string;
}

// ❌ "Вдруг понадобится"
interface User {
  id: string;
  email: string;
  phone?: string;
  address?: Address;
  preferences?: UserPreferences;
  // ... ещё 10 полей
}
```

**DRY — без дублирования:**
```typescript
// ✅ Извлечена общая логика
const formatCurrency = (amount: number, currency = 'USD') =>
  new Intl.NumberFormat('en-US', { style: 'currency', currency }).format(amount);

// ❌ Дублирование
const price1 = new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' }).format(100);
const price2 = new Intl.NumberFormat('en-US', { style: 'currency', currency: 'EUR' }).format(200);
```

**⚠️ Баланс DRY:** Дублирование лучше неправильной абстракции. Не абстрагировать случайные совпадения.

---

## SOLID принципы

### S — Single Responsibility

**Одна функция/класс = одна ответственность.**

```typescript
// ✅ Разделённые обязанности
const fetchUser = (id: string) => api.get(`/users/${id}`);
const validateUser = (user: User) => schema.validate(user);
const formatUserName = (user: User) => `${user.firstName} ${user.lastName}`;

// ❌ Всё в одном
async function processUser(id: string) {
  const user = await api.get(`/users/${id}`);
  const validation = schema.validate(user);
  if (!validation.valid) throw new Error('Invalid');
  return `${user.firstName} ${user.lastName}`;
}
```

---

### O — Open/Closed

**Открыт для расширения, закрыт для изменения.**

```typescript
// ✅ Расширение через интерфейсы
interface PaymentProcessor {
  process(amount: number): Promise<void>;
}

class StripeProcessor implements PaymentProcessor { /* ... */ }
class PayPalProcessor implements PaymentProcessor { /* ... */ }

// ❌ Изменение существующего кода
function processPayment(amount: number, method: string) {
  if (method === 'stripe') { /* ... */ }
  else if (method === 'paypal') { /* ... */ }
}
```

---

### L — Liskov Substitution

**Подтипы должны быть взаимозаменяемы.**

```typescript
interface Storage {
  save(key: string, value: string): Promise<void>;
  load(key: string): Promise<string | null>;
}

class LocalStorage implements Storage { /* ... */ }
class RemoteStorage implements Storage { /* ... */ }

// Оба типа взаимозаменяемы
const storage: Storage = Math.random() > 0.5 ? new LocalStorage() : new RemoteStorage();
```

---

### I — Interface Segregation

**Специфичные интерфейсы вместо универсальных.**

```typescript
// ✅ Разделённые интерфейсы
interface Readable { read(): Promise<string>; }
interface Writable { write(data: string): Promise<void>; }

class File implements Readable, Writable { /* ... */ }

// ❌ Монолитный интерфейс
interface Storage {
  read(): Promise<string>;
  write(data: string): Promise<void>;
  delete(): Promise<void>;
  compress(): Promise<void>;
  encrypt(): Promise<void>;
}
```

---

### D — Dependency Inversion

**Зависеть от абстракций, не от реализаций.**

```typescript
// ✅ Зависимость от интерфейса
interface Logger { log(message: string): void; }

class UserService {
  constructor(private logger: Logger) {}
  createUser(email: string) { this.logger.log(`Creating: ${email}`); }
}

// ❌ Жёсткая связь
class UserService {
  private logger = new ConsoleLogger();
  createUser(email: string) { this.logger.log(`Creating: ${email}`); }
}
```

---

## Дополнительные практики

| Практика | Рекомендация |
|----------|--------------|
| **Композиция vs Наследование** | Предпочитать композицию (`implements`) глубокому наследованию (`extends`) |
| **Явное vs Неявное** | Явные параметры и поведение, избегать "магии" |
| **Fail Fast** | Бросать исключения сразу, не скрывать ошибки |
| **Immutability** | Использовать `{ ...obj }`, `[...arr]` вместо мутаций |
| **Модульность** | Независимые модули со слабой связанностью |
| **Тестируемость** | Dependency injection, избегать глобального состояния |

### Примеры

**Композиция:**
```typescript
// ✅ Композиция
interface Flyable { fly(): void; }
interface Swimmable { swim(): void; }
class Duck implements Flyable, Swimmable { /* ... */ }

// ❌ Глубокое наследование
class Animal {}
class Bird extends Animal {}
class WaterBird extends Bird {}
class Duck extends WaterBird {}
```

**Fail Fast:**
```typescript
// ✅ Явная ошибка
function divide(a: number, b: number): number {
  if (b === 0) throw new Error('Division by zero');
  return a / b;
}

// ❌ Скрытие проблемы
function divide(a: number, b: number): number {
  return b === 0 ? 0 : a / b;
}
```

**Immutability:**
```typescript
// ✅ Иммутабельность
const updatedUser = { ...user, name: 'New Name' };
const newItems = [...items, newItem];

// ❌ Мутации
user.name = 'New Name';
items.push(newItem);
```

---

## Рефакторинг и производительность

### Когда рефакторить

- ✅ При появлении дублирования (правило трёх)
- ✅ При добавлении новой функциональности
- ❌ "На всякий случай" или "потому что можно"

### Оптимизация

> "Premature optimization is the root of all evil" — Donald Knuth

- Оптимизировать **только** измеренные bottleneck'и
- Профилировать перед оптимизацией
- Простота > производительность (пока не доказано обратное)

---

## Чеклист проектирования

При разработке новой функциональности:

- [ ] **Простота**: Это самое простое решение?
- [ ] **DRY**: Не дублирую ли я существующую логику?
- [ ] **YAGNI**: Действительно ли это нужно сейчас?
- [ ] **Single Responsibility**: Одна функция = одна задача?
- [ ] **Тестируемость**: Легко ли покрыть тестами?
- [ ] **Читаемость**: Понятно ли через 6 месяцев?
- [ ] **Масштабируемость**: Работает ли при росте нагрузки?

---

## Итеративный подход

**Избегать BDUF (Big Design Up Front):**

1. MVP — минимальная рабочая версия
2. Обратная связь от пользователей/команды
3. Итеративное улучшение
4. Рефакторинг при появлении паттернов

**❌ Не делать:**
- Месяцы проектирования без кода
- Архитектуры "на вырост"
- Документация на 100 страниц до первой строки

---

**Версия:** 1.0
**Обновлено:** 2025-10-18
