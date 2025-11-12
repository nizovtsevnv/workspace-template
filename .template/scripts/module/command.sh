#!/bin/sh
# ===================================
# Workspace Template - Выполнение команд модулей
# ===================================
# shellcheck disable=SC2059
set -e

# Инициализация общих переменных
. "$(dirname "$0")/../lib/init.sh"

# Загружаем библиотеки
. "$SCRIPT_DIR/lib/ui.sh"
. "$SCRIPT_DIR/lib/modules.sh"
. "$SCRIPT_DIR/lib/module-help.sh"
. "$SCRIPT_DIR/lib/stack-runner.sh"

# ВАЖНО: Переходим в workspace root для корректной работы с относительными путями
cd "$WORKSPACE_ROOT"

# ===================================
# Константы: Система приоритетов выполнения команд
# ===================================
# Приоритеты обработки команд модулей (от высшего к низшему):
# 1. Makefile targets (универсально для всех технологий)
# 2. Package manager scripts (package.json, composer.json, pyproject.toml)
# 3. Binary commands в директориях bin (node_modules/.bin, vendor/bin)
# 4. Shell passthrough (выполнение как обычной shell команды)
#
# Формат: priority_name:tech_filter:check_function:exec_command
# - priority_name: имя приоритета (для понимания)
# - tech_filter: all (любая технология) или конкретная (nodejs, php, python)
# - check_function: функция проверки из lib/modules.sh (только проверяет наличие, не выполняет)
# - exec_command: команда для выполнения на хосте (содержит $MODULE_CMD, аргументы добавляются автоматически)
#   Для nodejs используется __NODEJS_PM__ как placeholder для автоопределения пакетного менеджера
readonly PRIORITY_CHECKS="
makefile:all:check_makefile_target:make \$MODULE_CMD
package_json:nodejs:check_package_json_script:__NODEJS_PM__ run \$MODULE_CMD
composer:php:check_composer_script:composer run-script \$MODULE_CMD
pyproject:python:check_pyproject_script:poetry run \$MODULE_CMD
nodejs_bin:nodejs:check_nodejs_bin:npx \$MODULE_CMD
php_bin:php:check_php_bin:./vendor/bin/\$MODULE_CMD
shell:all:check_shell_passthrough:\$MODULE_CMD
"

# ===================================
# Параметры
MODULE_NAME="$1"
MODULE_CMD="$2"
shift 2 2>/dev/null || true
# shellcheck disable=SC2034
MODULE_ARGS="$*"

MODULE_PATH="${MODULES_DIR:-modules}/$MODULE_NAME"

# Проверка существования модуля (теперь мы в WORKSPACE_ROOT, путь относительный)
if [ ! -d "$MODULE_PATH" ]; then
	log_error "Модуль '$MODULE_NAME' не найден в $MODULE_PATH"

	# Проверяем, является ли это git submodule
	if git config --file .gitmodules --get "submodule.$MODULE_PATH.path" >/dev/null 2>&1; then
		printf "\n"
		log_info "Это git submodule, который не инициализирован"
		printf "  Выполните: ${COLOR_SUCCESS}git submodule update --init $MODULE_PATH${COLOR_RESET}\n"
	fi
	exit 1
fi

# Определить технологии модуля
MODULE_TECH=$(detect_module_tech "$MODULE_PATH")

# Показать справку если команда не передана или help
if [ -z "$MODULE_CMD" ] || [ "$MODULE_CMD" = "help" ]; then
	set +e  # Временно отключаем -e для show_module_help
	show_module_help "$MODULE_NAME" "$MODULE_PATH" "$MODULE_TECH"
	exit 0
fi

# ===================================
# Специальная обработка команды sh
# ===================================
# Запуск интерактивного shell в контейнере стека

if [ "$MODULE_CMD" = "sh" ] || echo "$MODULE_CMD" | grep -q "^sh:"; then
	# Проверяем наличие стеков в модуле
	module_stacks=$(detect_module_stack "$MODULE_PATH")
	if [ -z "$module_stacks" ]; then
		log_error "Не найдены технологические стеки в модуле '$MODULE_NAME'"
		log_info "Команда sh доступна только для модулей с определёнными стеками"
		exit 1
	fi

	# Определяем целевой стек
	if echo "$MODULE_CMD" | grep -q "^sh:"; then
		# Явно указан стек: sh:nodejs, sh:python и т.д.
		requested_stack=$(echo "$MODULE_CMD" | sed 's/^sh://')

		# Проверка что стек доступен в модуле
		if ! echo "$module_stacks" | grep -q "$requested_stack"; then
			log_error "Стек '$requested_stack' не найден в модуле '$MODULE_NAME'"
			# Форматируем список стеков для отображения
			stack_list=$(echo "$module_stacks" | sed 's/ /, /g')
			log_info "Доступные стеки: $stack_list"
			exit 1
		fi
		target_stack="$requested_stack"
	else
		# Автоматическое определение: берём первую технологию (primary_tech)
		target_stack=$(echo "$module_stacks" | awk '{print $1}')
	fi

	# Получаем абсолютный путь к модулю
	MODULE_PATH_ABS="$WORKSPACE_ROOT/$MODULE_PATH"

	# Запуск интерактивного shell
	set +e  # Отключаем -e для корректной обработки выхода из shell
	run_interactive_shell "$target_stack" "$MODULE_PATH_ABS"
	exit $?
fi

# ===================================
# Выполнение команды
# ===================================
# Система приоритетов: Makefile > PM scripts > Bin commands > Shell

# Цикл проверки по приоритетам (используется константа PRIORITY_CHECKS из начала файла)
# Используем временный файл для выхода из subshell
exit_file=$(mktemp)
# shellcheck disable=SC2064
trap "rm -f $exit_file" EXIT INT TERM

echo "$PRIORITY_CHECKS" | while read -r check_line; do
	[ -z "$check_line" ] && continue

	# Парсинг строки: priority:tech:func:exec_cmd
	rest="${check_line#*:}"
	tech="${rest%%:*}"
	rest="${rest#*:}"
	func="${rest%%:*}"
	exec_cmd="${rest#*:}"

	# Проверка технологии
	if [ "$tech" != "all" ] && ! echo "$MODULE_TECH" | grep -q "$tech"; then
		continue
	fi

	# Проверка наличия команды
	if $func "$MODULE_PATH" "$MODULE_CMD" 2>/dev/null; then
		# Команда найдена - выполняем через stack runner

		# Замена placeholder для nodejs пакетного менеджера
		nodejs_pm_detected=""
		if echo "$exec_cmd" | grep -q "__NODEJS_PM__"; then
			nodejs_pm_detected=$(detect_nodejs_manager "$MODULE_PATH")
			exec_cmd=$(echo "$exec_cmd" | sed "s/__NODEJS_PM__/$nodejs_pm_detected/g")
		fi

		# Раскрываем переменные в команде для отображения
		eval "display_cmd=\"$(eval echo \"$exec_cmd\")\""
		# shellcheck disable=SC2154
		log_section "Модуль $MODULE_NAME: $display_cmd"

		# Раскрываем переменные для выполнения
		eval "full_cmd=\"$(eval echo \"$exec_cmd\")\""

		# Для npm нужно добавить -- перед аргументами для правильной передачи в скрипт
		# Для bun, pnpm, yarn аргументы передаются напрямую
		args_with_separator="$MODULE_ARGS"
		if [ "$nodejs_pm_detected" = "npm" ] && [ -n "$MODULE_ARGS" ]; then
			args_with_separator="-- $MODULE_ARGS"
		fi

		# Определяем основную технологию (берем первую из списка)
		primary_tech=$(echo "$MODULE_TECH" | awk '{print $1}')

		# Получаем абсолютный путь к модулю для stack runner
		# (так как subshell в stack runner не наследует cd из родительского процесса)
		MODULE_PATH_ABS="$WORKSPACE_ROOT/$MODULE_PATH"

		# Выполняем команду через stack runner с fallback в контейнер
		# shellcheck disable=SC2086,SC2154
		run_stack_command "$primary_tech" "$MODULE_PATH_ABS" "$full_cmd $args_with_separator"
		exit_code=$?

		# Записываем exit code в файл для передачи из subshell
		# Это работает для любого кода, включая 0 (успех/прерывание)
		echo "$exit_code" > "$exit_file"
		exit $exit_code
	fi
done

# Проверяем, была ли выполнена команда
if [ -f "$exit_file" ] && [ -s "$exit_file" ]; then
	exit_code=$(cat "$exit_file")
	rm -f "$exit_file"
	exit $exit_code
fi

# Если дошли сюда - команда была прервана (Ctrl+C) или не найдена
# При Ctrl+C subshell прерывается до записи в exit_file, это нормальное завершение
# Выходим тихо без сообщения об ошибке (Ctrl+C это не ошибка выполнения команды)
exit 0
