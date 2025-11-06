#!/bin/sh
# ===================================
# Ленивая загрузка библиотек для Workspace Template
# ===================================
# Использование: . lib/loader.sh && load_lib "ui" "log_info"
# Загружает библиотеку только если указанная функция ещё не доступна
# shellcheck disable=SC3043

# Загрузка библиотеки если функция ещё не определена
# Параметры:
#   $1 - имя библиотеки (без расширения .sh и без пути lib/)
#   $2 - имя функции для проверки наличия
# Использование:
#   load_lib "ui" "log_info"
#   load_lib "container" "ensure_template_ready"
load_lib() {
	local lib_name="$1"
	local check_func="$2"

	# Проверяем, определена ли функция
	if ! command -v "$check_func" >/dev/null 2>&1; then
		# Определяем SCRIPT_DIR если ещё не определён
		# Это нужно для случаев, когда библиотеки загружаются напрямую
		SCRIPT_DIR="${SCRIPT_DIR:-$(cd "$(dirname "$0")" && pwd)}"

		# Загружаем библиотеку из lib/ директории
		# shellcheck disable=SC1090
		. "$SCRIPT_DIR/lib/$lib_name.sh"
	fi
}
