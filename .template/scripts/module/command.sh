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
readonly PRIORITY_CHECKS="
makefile:all:check_makefile_target:make \$MODULE_CMD
package_json:nodejs:check_package_json_script:npm run \$MODULE_CMD
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

# Проверка существования модуля
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

		# Раскрываем переменные в команде для отображения
		eval "display_cmd=\"$(eval echo \"$exec_cmd\")\""
		# shellcheck disable=SC2154
		log_section "Модуль $MODULE_NAME: $display_cmd"

		# Раскрываем переменные для выполнения
		eval "full_cmd=\"$(eval echo \"$exec_cmd\")\""

		# Определяем основную технологию (берем первую из списка)
		primary_tech=$(echo "$MODULE_TECH" | awk '{print $1}')

		# Выполняем команду через stack runner с fallback в контейнер
		# shellcheck disable=SC2086,SC2154
		run_stack_command "$primary_tech" "$MODULE_PATH" "$full_cmd $MODULE_ARGS"
		exit_code=$?
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

# Если дошли сюда - ни одна проверка не сработала (не должно случиться, т.к. shell passthrough всегда успешен)
log_error "Не удалось выполнить команду $MODULE_CMD"
exit 1
