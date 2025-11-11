# Coding Style - Руководство по стилю кода

Правила оформления shell-скриптов в проекте Workspace Template.

## Общие принципы

### POSIX совместимость

**Все скрипты должны быть POSIX-совместимыми (`#!/bin/sh`)**

```sh
# ✅ Правильно
#!/bin/sh

# ❌ Неправильно
#!/bin/bash
```

**Причина:** максимальная портируемость между различными системами и shell'ами.

### Shellcheck compliance

Все скрипты должны проходить проверку `shellcheck` без ошибок. Допустимо отключение правил через директиву:

```sh
# shellcheck disable=SC2086
command $args
```

Запуск проверки: `make template test`

## Структура файлов

### Shebang и заголовок

```sh
#!/bin/sh
# ===================================
# Название модуля/скрипта
# ===================================
# Краткое описание назначения
# Использование: ./script.sh [параметры]
# shellcheck disable=SCXXXX

set -e  # Выход при ошибках (для основных скриптов)
```

### Секции

Используйте визуальные разделители секций:

```sh
# ===================================
# Название секции
# ===================================

# Код секции...
```

Основные секции в порядке следования:
1. Загрузка зависимостей (`. "$SCRIPT_DIR/lib/..."`)
2. Константы и переменные
3. Вспомогательные функции
4. Основная логика
5. CLI интерфейс (для библиотек)

### Загрузка библиотек

**Для основных скриптов используйте init.sh:**

```sh
# Инициализация через init.sh (рекомендуется)
. "$(dirname "$0")/lib/init.sh"

# init.sh автоматически определяет:
# - SCRIPT_DIR - директория скриптов
# - WORKSPACE_ROOT - корень workspace
# - CONTAINER_RUNTIME - docker или podman
# - HOST_UID, HOST_GID - для правильных прав доступа
# - Цвета для логирования (COLOR_*)

# Загружаем дополнительные библиотеки
. "$SCRIPT_DIR/lib/ui.sh"
. "$SCRIPT_DIR/lib/workspace.sh"
```

**Для библиотек можно определять SCRIPT_DIR напрямую:**

```sh
# Только для библиотек в lib/
SCRIPT_DIR="${SCRIPT_DIR:-$(cd "$(dirname "$0")" && pwd)}"

# Загружаем зависимости
. "$SCRIPT_DIR/workspace.sh"
```

## Именование

### Функции

**Формат:** `verb_noun()` - глагол + существительное, разделённые подчёркиванием

```sh
# ✅ Правильно
get_module_info() { ... }
check_command() { ... }
ensure_devenv_ready() { ... }
detect_nodejs_manager() { ... }

# ❌ Неправильно
moduleInfo() { ... }      # CamelCase
getinfo() { ... }         # без разделителя
module-info() { ... }     # дефис вместо подчёркивания
```

**Префиксы:**
- `get_*` - получить данные, вернуть через stdout
- `check_*` - проверить условие, вернуть 0/1
- `ensure_*` - гарантировать состояние (создать если нужно)
- `detect_*` - определить значение автоматически
- `show_*` - отобразить информацию пользователю

### Переменные

**Константы и экспортируемые:** UPPER_CASE

```sh
CONTAINER_NAME="my-container"
MODULE_PATH="/path/to/module"
export HOST_UID
export HOST_GID
```

**Локальные переменные:** lower_case

```sh
module_path="$1"
tech_info=""
found=0
```

**Переменные окружения цветов:**

```sh
COLOR_SUCCESS="\033[0;32m"
COLOR_ERROR="\033[0;31m"
COLOR_INFO="\033[0;36m"
COLOR_RESET="\033[0m"
```

## Документация функций

**Обязательный формат** (3 строки):

```sh
# Краткое описание что делает функция
# Параметры: $1 - описание, $2 - описание (если есть)
# Возвращает: описание возвращаемого значения / Использование: пример
function_name() {
	# Реализация...
}
```

**Примеры:**

```sh
# Получить версию модуля для указанной технологии
# Параметры: $1 - путь к модулю, $2 - технология (nodejs, php, python, rust)
# Возвращает: строку вида "1.0.0" или пустую строку
get_tech_version() {
	# ...
}

# Проверка доступности команды
# Параметр: $1 - имя команды
# Использование: check_command "docker"
check_command() {
	# ...
}
```

## Условия и циклы

### Простые проверки

Используйте `[ ]` с `&&` для простых однострочных проверок:

```sh
# ✅ Правильно
[ -f "$file" ] && echo "File exists"
[ -z "$var" ] && return 1

# ❌ Избыточно
if [ -f "$file" ]; then
	echo "File exists"
fi
```

### Сложные условия

Используйте `if` для многострочных блоков:

```sh
if [ условие ]; then
	действие1
	действие2
	действие3
fi
```

### Ранний возврат

Предпочитайте ранний возврат вместо глубокой вложенности:

```sh
# ✅ Правильно
check_something() {
	[ ! -f "$file" ] && return 1
	[ -z "$var" ] && return 1

	# Основная логика...
	return 0
}

# ❌ Неправильно (глубокая вложенность)
check_something() {
	if [ -f "$file" ]; then
		if [ -n "$var" ]; then
			# Основная логика...
			return 0
		fi
	fi
	return 1
}
```

### Циклы

```sh
# for с маппингом данных
for item in "key1:value1" "key2:value2"; do
	key="${item%%:*}"
	value="${item#*:}"
	# Обработка...
done

# while для чтения построчно
while read -r line; do
	# Обработка строки...
done < "$file"

# while с условием
while [ $count -lt $max ]; do
	# Действия...
	count=$((count + 1))
done
```

## Обработка ошибок

### set -e

Используйте в основных скриптах (не в библиотеках):

```sh
#!/bin/sh
set -e  # Выход при любой ошибке
```

### Проверка кода возврата

```sh
# ✅ Правильно
if command; then
	log_success "Success"
else
	log_error "Failed"
	return 1
fi

# Или с ранним возвратом
command || { log_error "Failed"; return 1; }
```

### trap для cleanup

```sh
tmpfile=$(mktemp)
# shellcheck disable=SC2064
trap "rm -f $tmpfile" EXIT INT TERM

# Работа с файлом...
```

## Логирование

**Используйте функции из `ui.sh`:**

```sh
log_info "Информационное сообщение"      # ℹ синий
log_success "Успешное выполнение"       # ✓ зелёный
log_warning "Предупреждение"            # ⚠ жёлтый
log_error "Ошибка"                      # ✗ красный
log_section "Заголовок раздела"         # ▶ фиолетовый
```

**Никогда не используйте прямой `echo` или `printf` для сообщений пользователю.**

## Парсинг параметров

### Маппинг через разделители

```sh
# Формат: tech:file:display
for tech_data in "nodejs:package.json:Node.js" "php:composer.json:PHP"; do
	tech="${tech_data%%:*}"
	rest="${tech_data#*:}"
	file="${rest%%:*}"
	display="${rest#*:}"
	# Использование...
done
```

### Парсинг аргументов

```sh
command="$1"
shift
args="$*"  # Все остальные аргументы

# Или
param1="$1"
param2="$2"
shift 2
rest="$*"
```

## Строковые операции

### POSIX-совместимые подстановки

```sh
# Удаление префикса (самое короткое)
${var#pattern}

# Удаление префикса (самое длинное)
${var##pattern}

# Удаление суффикса (самое короткое)
${var%pattern}

# Удаление суффикса (самое длинное)
${var%%pattern}

# Значение по умолчанию
${var:-default}

# Присвоение по умолчанию
${var:=default}
```

### Примеры

```sh
# Парсинг "key:value"
key="${line%%:*}"
value="${line#*:}"

# Проверка на пустоту
[ -z "$var" ]   # пустая
[ -n "$var" ]   # непустая

# Конкатенация
result="${prefix}${value}${suffix}"
```

## Примеры хороших практик

### Функция с маппингом технологий

```sh
get_module_info() {
	module_path="$1"
	tech_info=""

	# Маппинг: tech:marker:display:check_files
	for tech_data in \
		"nodejs:package.json:Node.js" \
		"php:composer.json:PHP" \
		"python:pyproject.toml:Python:pyproject.toml requirements.txt setup.py"; do

		tech="${tech_data%%:*}"
		rest="${tech_data#*:}"
		marker="${rest%%:*}"
		rest="${rest#*:}"
		display="${rest%%:*}"
		check_files="${rest#*:}"

		# Если альтернативные файлы не указаны
		[ "$check_files" = "$display" ] && check_files="$marker"

		# Проверка наличия файла
		found=0
		for check_file in $check_files; do
			if [ -f "$module_path/$check_file" ]; then
				found=1
				break
			fi
		done

		if [ $found -eq 1 ]; then
			[ -n "$tech_info" ] && tech_info="$tech_info, "
			version=$(get_tech_version "$module_path" "$tech")
			tech_info="${tech_info}${version:+$version }$display"
		fi
	done

	echo "$tech_info"
}
```

### Проверка с ранним возвратом

```sh
check_makefile_target() {
	module_path="$1"
	command="$2"

	[ ! -f "$module_path/Makefile" ] && return 1
	cd "$module_path" && make -n "$command" >/dev/null 2>&1
}
```

### Табличный подход для приоритетов

```sh
CHECKS="
check1:tech1:action1
check2:tech2:action2
check3:all:action3
"

for line in $CHECKS; do
	check="${line%%:*}"
	rest="${line#*:}"
	tech="${rest%%:*}"
	action="${rest#*:}"

	[ "$tech" != "all" ] && ! echo "$MODULE_TECH" | grep -q "$tech" && continue

	if $check "$MODULE_PATH" "$MODULE_CMD"; then
		eval "$action"
		break
	fi
done
```

## Антипаттерны (чего избегать)

### ❌ Bash-измы

```sh
# ❌ Плохо
[[ condition ]]     # bash-specific
array=()            # массивы - bash
function name() {}  # keyword 'function'

# ✅ Хорошо
[ condition ]       # POSIX
list="item1 item2"  # строки вместо массивов
name() {}           # без keyword
```

### ❌ Неявные зависимости

```sh
# ❌ Плохо
log_info "Message"  # функция не загружена

# ✅ Хорошо
if ! command -v log_info >/dev/null 2>&1; then
	SCRIPT_DIR="${SCRIPT_DIR:-$(cd "$(dirname "$0")" && pwd)}"
	. "$SCRIPT_DIR/ui.sh"
fi
```

### ❌ Прямой вывод вместо функций

```sh
# ❌ Плохо
echo "✓ Success"
printf "\033[32m✓\033[0m Success\n"

# ✅ Хорошо
log_success "Success"
```

### ❌ Использование echo для команд

```sh
# ❌ Плохо (echo в bash-скрипте)
Bash: echo "explaining something to user"

# ✅ Хорошо (прямой текст в ответе)
Output: "explaining something to user"
```

## Тестирование

### Запуск shellcheck

```bash
make template test
```

Автоматически определяет окружение:
- Если `shellcheck` установлен на хосте - использует хостовый
- Если нет - запускает в легковесном Alpine контейнере (~10MB)

Или вручную на хосте:

```bash
shellcheck .template/scripts/*.sh
shellcheck .template/scripts/lib/*.sh
```

**Примечание:** При первом запуске без хостового shellcheck будет собран Alpine образ `workspace-stack-sh` (включает shellcheck, jq, yq, bash, curl, git). Образ кешируется и переиспользуется при последующих запусках.

### Smoke tests

Основные smoke tests запускаются через `.template/scripts/devenv-test.sh`.

## Дополнительные ресурсы

- [POSIX Shell Command Language](https://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html)
- [ShellCheck Wiki](https://www.shellcheck.net/wiki/)
- [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html)
