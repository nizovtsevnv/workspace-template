# Версионирование и релизы

Стандарты создания коммитов, версий и релизов в monorepo.

---

## Язык: русский

Используется для комментариев, JSDoc, коммитов, CHANGELOG, документации.

**Исключение:** Ключевые слова Conventional Commits (`feat`, `fix`, `chore`) —
на английском.

---

## Чеклист перед коммитом

- [ ] `make check` проходит (lint + typecheck + test)
- [ ] Документация обновлена (если менялся публичный API)
- [ ] Нет `console.log`, `debugger`, `it.only`, `it.skip`
- [ ] `.env.example` актуален (если добавлялись переменные)

---

## Conventional Commits

Формат: `<type>(<scope>): <subject на русском>`

### Типы

| Тип        | Описание                          | Версия |
| ---------- | --------------------------------- | ------ |
| `feat`     | Новая функциональность            | MINOR  |
| `fix`      | Исправление бага                  | PATCH  |
| `perf`     | Улучшение производительности      | PATCH  |
| `docs`     | Только документация               | —      |
| `style`    | Форматирование кода               | —      |
| `refactor` | Рефакторинг                       | —      |
| `test`     | Тесты                             | —      |
| `chore`    | Сборка, зависимости, конфигурация | —      |
| `ci`       | CI/CD                             | —      |

**Breaking Changes:** `!` после type/scope или `BREAKING CHANGE` в footer →
MAJOR версия.

### Примеры

```bash
# Минимальный
git commit -m "feat: добавлена функция форматирования даты"

# Со scope
git commit -m "fix(auth): исправлена проверка email"

# Breaking change
git commit -m "feat(api)!: изменён формат /api/users

BREAKING CHANGE: поле 'name' разделено на 'firstName' и 'lastName'"
```

**Pre-commit автоматизация:**

При каждом `git commit` через Husky автоматически выполняются:

- `make pre-commit` — для staged файлов:
  - ESLint с автофиксом
  - Prettier с автоформатированием
  - TypeScript typecheck (для apps с изменениями)
- `commitlint` — проверка формата commit message

Ручной запуск: `make pre-commit`

**Важно:** Pre-commit проверки соответствуют GitLab CI проверкам (lint +
typecheck), поэтому если коммит прошел локально, он пройдет и в CI.

Обход хука (только в исключительных случаях): `git commit --no-verify`

---

## Версионирование: Independent

Каждый пакет имеет независимую версию (инструмент: **changesets**):

```
packages/ui/package.json:      "version": "2.3.1"
packages/api/package.json:     "version": "1.8.0"
apps/web/package.json:         "version": "1.2.0"
```

**Преимущества:** Релизы по отдельности, выборочное обновление, меньше breaking
changes.

### Make команды

| Команда                  | Описание                    |
| ------------------------ | --------------------------- |
| `make release-changeset` | Создать changeset           |
| `make release-version`   | Обновить версии + CHANGELOG |
| `make release-publish`   | Опубликовать пакеты         |
| `make release-status`    | Показать статус changesets  |

---

## Workflow

### 1. Feature разработка

```bash
git checkout -b feat/button-component

# Разработка, тесты...

git add .
git commit -m "feat(ui): добавлен компонент Button"

# Создать changeset
make release-changeset
# → Выбрать пакеты: @sigma/ui
# → Выбрать тип: minor
# → Описание: "Добавлен компонент Button с вариантами primary, secondary, ghost"

git add .changeset/
git commit -m "chore: changeset для Button"
git push origin feat/button-component
```

Создаётся `.changeset/random-name.md`:

```markdown
---
'@sigma/ui': minor
---

Добавлен компонент Button с вариантами primary, secondary, ghost
```

### 2. Release на main

```bash
git checkout main && git pull
make check && make build

# Обновить версии и CHANGELOG
make release-version

git add .
git commit -m "chore: release версий"
git push --follow-tags
```

**Результат `release-version`:**

- Обновляет `package.json` в изменённых пакетах
- Генерирует `CHANGELOG.md` (на русском)
- Создаёт git теги (`@sigma/ui@2.4.0`)
- Удаляет использованные changesets

---

## Semantic Versioning

Следуем [Semver 2.0.0](https://semver.org/): `MAJOR.MINOR.PATCH`

| Версия    | Когда                  | Пример          |
| --------- | ---------------------- | --------------- |
| **MAJOR** | Breaking changes       | `1.5.3 → 2.0.0` |
| **MINOR** | Новая функциональность | `1.5.3 → 1.6.0` |
| **PATCH** | Исправления багов      | `1.5.3 → 1.5.4` |

**Pre-release:** `1.0.0-alpha.1`, `1.0.0-beta.1`, `1.0.0-rc.1` **Начальная
разработка:** `0.x.x` (API нестабилен) → `1.0.0` (стабильный)

---

## Автогенерация

Changesets создаёт для каждого пакета:

**CHANGELOG.md:**

```markdown
# @sigma/ui

## 2.4.0

### Minor Changes

- Добавлен компонент Button с вариантами primary, secondary, ghost

### Patch Changes

- Исправлена проблема с фокусом в Input
```

**Git теги:** `@sigma/ui@2.4.0`, `@sigma/api@1.8.0`

**Команды:**

```bash
git tag -l                    # Все теги
git tag -l "@sigma/ui@*"     # Теги пакета
```

CHANGELOG можно дополнить миграционными инструкциями или важными замечаниями.

---

## Публикация

```bash
git push --follow-tags
make release-publish
```

**Приватный registry** (`.npmrc`):

```
registry=https://npm.your-domain.com
//npm.your-domain.com/:_authToken=${NPM_TOKEN}
```

---

## Чеклист релиза

- [ ] Все PR смёржены в main
- [ ] `make check` + `make build` проходят
- [ ] Все changesets созданы
- [ ] `make release-version` выполнен
- [ ] CHANGELOG проверен и при необходимости дополнен
- [ ] `git push --follow-tags` выполнен
- [ ] Пакеты опубликованы (если нужно): `make release-publish`

---

## Troubleshooting

**Забыли changeset:** Создайте в feature-ветке и допушьте **Изменить тип
версии:** Отредактируйте `.changeset/*.md` (`minor` → `major`) **Удалить
changeset:** `rm .changeset/wrong-changeset.md && git commit`

---

**Версия:** 1.0 **Обновлено:** 2025-10-18
