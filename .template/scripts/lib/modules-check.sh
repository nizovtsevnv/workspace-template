#!/bin/sh
# ===================================
# Modules Check - Проверка доступности команд модулей
# ===================================
# Функции проверки команд (система приоритетов)
# Использование: . lib/modules-check.sh
# shellcheck disable=SC1091,SC3043

# Загружаем modules-info для доступа к get_*_scripts функциям
# SCRIPT_DIR должен быть определён через init.sh перед загрузкой библиотек
. "${SCRIPT_DIR:?SCRIPT_DIR не определён}/lib/loader.sh"
load_lib "modules-info" "get_package_json_scripts"

# ===================================
# Функции проверки команд
# ===================================
# Функции только проверяют наличие команды, НЕ выполняют её
# Возвращают: 0 если команда найдена, 1 если не найдена

# Параметризованная функция проверки скрипта в конфиг-файле
# Использование: _check_script_in_config "$module_path" "$command" "$config_file" "$getter_func"
_check_script_in_config() {
	local module_path="$1"
	local command="$2"
	local config_file="$3"
	local getter_func="$4"

	[ ! -f "$module_path/$config_file" ] && return 1
	"$getter_func" "$module_path" | grep -q "^$command	"
}

# Параметризованная функция проверки бинарника в директории
# Использование: _check_bin_in_dir "$module_path" "$command" "$bin_dir"
_check_bin_in_dir() {
	local module_path="$1"
	local command="$2"
	local bin_dir="$3"

	[ -f "$module_path/$bin_dir/$command" ]
}

# Проверить наличие Makefile target
check_makefile_target() {
	module_path="$1"
	command="$2"

	[ ! -f "$module_path/Makefile" ] && return 1
	cd "$module_path" && make -n "$command" >/dev/null 2>&1
}

# Проверить наличие package.json script
check_package_json_script() {
	_check_script_in_config "$1" "$2" "package.json" "get_package_json_scripts"
}

# Проверить наличие composer.json script
check_composer_script() {
	_check_script_in_config "$1" "$2" "composer.json" "get_composer_json_scripts"
}

# Проверить наличие pyproject.toml script
check_pyproject_script() {
	_check_script_in_config "$1" "$2" "pyproject.toml" "get_pyproject_scripts"
}

# Проверить наличие команды в node_modules/.bin
check_nodejs_bin() {
	_check_bin_in_dir "$1" "$2" "node_modules/.bin"
}

# Проверить наличие команды в vendor/bin
check_php_bin() {
	_check_bin_in_dir "$1" "$2" "vendor/bin"
}

# Shell passthrough - всегда возвращает успех
check_shell_passthrough() {
	return 0
}
