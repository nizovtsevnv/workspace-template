#!/bin/sh
# ===================================
# Modules Info - Получение информации о модулях
# ===================================
# Функции получения версий, команд и информации о модулях
# Использование: . lib/modules-info.sh
# shellcheck disable=SC1091

# Загружаем необходимые библиотеки
# SCRIPT_DIR должен быть определён через init.sh перед загрузкой библиотек
. "${SCRIPT_DIR:?SCRIPT_DIR не определён}/lib/loader.sh"
load_lib "modules-detect" "detect_module_tech detect_module_stack detect_module_cicd"

# ===================================
# Функции получения информации о версиях
# ===================================

# Получить версию модуля для указанной технологии
# Параметры: $1 - путь к модулю, $2 - технология (nodejs, php, python, rust)
# Возвращает: строку вида "1.0.0" или пустую строку
# Использование: version=$(get_tech_version "$module_path" "nodejs")
get_tech_version() {
	module_path="$1"
	tech="$2"

	case "$tech" in
		nodejs)
			[ -f "$module_path/package.json" ] || { echo ""; return; }
			grep -m1 '"version"' "$module_path/package.json" | \
				sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' || echo ""
			;;
		php)
			[ -f "$module_path/composer.json" ] || { echo ""; return; }
			grep -m1 '"version"' "$module_path/composer.json" | \
				sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' || echo ""
			;;
		python)
			[ -f "$module_path/pyproject.toml" ] || { echo ""; return; }
			grep -m1 '^version' "$module_path/pyproject.toml" | \
				sed -n 's/^version[[:space:]]*=[[:space:]]*"\([^"]*\)".*/\1/p' || echo ""
			;;
		rust)
			[ -f "$module_path/Cargo.toml" ] || { echo ""; return; }
			grep -m1 '^version' "$module_path/Cargo.toml" | \
				sed -n 's/^version[[:space:]]*=[[:space:]]*"\([^"]*\)".*/\1/p' || echo ""
			;;
		*)
			echo ""
			;;
	esac
}

# Получить информацию о версиях модуля
# Параметр: $1 - путь к модулю
# Возвращает: строку вида "1.0.0 Node.js, 2.0.0 PHP"
# Для каждой технологии читает версию из соответствующего файла
get_module_info() {
	module_path="$1"
	tech_info=""

	# Маппинг технологий: tech:marker_file:display_name:check_files
	for tech_data in \
		"nodejs:package.json:Node.js" \
		"php:composer.json:PHP" \
		"python:pyproject.toml:Python:pyproject.toml requirements.txt setup.py" \
		"rust:Cargo.toml:Rust"; do

		tech="${tech_data%%:*}"
		rest="${tech_data#*:}"
		marker="${rest%%:*}"
		rest="${rest#*:}"
		display="${rest%%:*}"
		check_files="${rest#*:}"

		# Если не указаны альтернативные файлы, используем маркер
		[ "$check_files" = "$display" ] && check_files="$marker"

		# Проверка наличия хотя бы одного файла технологии
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
			if [ -n "$version" ]; then
				tech_info="${tech_info}$version $display"
			else
				tech_info="${tech_info}$display"
			fi
		fi
	done

	echo "$tech_info"
}

# Получить информацию о CI/CD системах модуля
# Параметр: $1 - путь к модулю
# Возвращает: строку вида "GitHub Actions, GitLab CI" или "нет"
get_module_cicd() {
	module_path="$1"
	cicd_systems=$(detect_module_cicd "$module_path")
	cicd=""

	# Таблица маппинга (DRY подход)
	for system in "github:GitHub Actions" "gitlab:GitLab CI" "gitea:Gitea Actions"; do
		key="${system%%:*}"
		name="${system#*:}"
		if echo "$cicd_systems" | grep -q "$key"; then
			[ -n "$cicd" ] && cicd="$cicd, "
			cicd="$cicd$name"
		fi
	done

	[ -z "$cicd" ] && cicd="нет"
	echo "$cicd"
}

# Получить только версии модуля (компактный вывод)
# Параметр: $1 - путь к модулю
# Возвращает: строку вида "1.0.0" или "1.0.0, 2.0.0" или пустую строку
get_module_versions_compact() {
	module_path="$1"
	versions=""

	# Маппинг технологий: tech:marker_file:check_files
	for tech_data in \
		"nodejs:package.json" \
		"php:composer.json" \
		"python:pyproject.toml:pyproject.toml requirements.txt setup.py" \
		"rust:Cargo.toml"; do

		tech="${tech_data%%:*}"
		rest="${tech_data#*:}"
		marker="${rest%%:*}"
		check_files="${rest#*:}"

		# Если не указаны альтернативные файлы, используем маркер
		[ "$check_files" = "$marker" ] && check_files="$marker"

		# Проверка наличия хотя бы одного файла технологии
		found=0
		for check_file in $check_files; do
			if [ -f "$module_path/$check_file" ]; then
				found=1
				break
			fi
		done

		if [ $found -eq 1 ]; then
			v=$(get_tech_version "$module_path" "$tech")
			if [ -n "$v" ]; then
				[ -n "$versions" ] && versions="$versions, "
				versions="${versions}$v"
			fi
		fi
	done

	# Выводим версии
	echo "$versions"
}

# ===================================
# Функции получения команд по секциям
# ===================================

# Получить Makefile targets
get_makefile_commands() {
	module_path="$1"
	if [ -f "$module_path/Makefile" ]; then
		cd "$module_path" && make -qp 2>/dev/null | \
		awk -F: '/^[a-zA-Z0-9][^$#\/\t=]*:([^=]|$)/ {split($1,A,/ /);for(i in A)print A[i]}' | \
		grep -v '^\.PHONY$\|^Makefile$' | sort -u
	fi
}

# Показать секцию Makefile команд в справке модуля
# Параметры: $1 - путь к модулю, $2 - имя модуля, $3 - файл используемых команд
# Использование: show_makefile_section "$MODULE_PATH" "$MODULE_NAME" "$used_commands"
# Примечание: Требует загрузки ui.sh для print_table
show_makefile_section() {
	module_path="$1"
	module_name="$2"
	used_commands="$3"

	makefile_cmds=$(get_makefile_commands "$module_path")
	[ -z "$makefile_cmds" ] && return

	printf "\n"
	log_info "Команды Makefile:"
	echo "$makefile_cmds" | while read -r cmd; do
		printf "make $module_name %s<COL>\n" "$cmd"
		echo "$cmd" >> "$used_commands"
	done | print_table 30
}

# Получить package.json scripts
get_package_json_scripts() {
	module_path="$1"
	[ -f "$module_path/package.json" ] || return

	# Парсинг через jq (если доступен)
	if command -v jq >/dev/null 2>&1; then
		jq -r '.scripts // {} | to_entries[] | "\(.key)\t\(.value)"' "$module_path/package.json" 2>/dev/null
		return
	fi

	# Fallback: простой парсинг через grep/sed (может быть неточным для сложных JSON)
	# Извлекаем только секцию scripts (до первой закрывающей скобки)
	grep -A 100 '"scripts"' "$module_path/package.json" 2>/dev/null | \
		sed -n '/"scripts"/,/^[[:space:]]*\}/p' | \
		grep -E '^\s*"[^"]+"\s*:' | \
		grep -v '"scripts"' | \
		sed -n 's/^\s*"\([^"]*\)"\s*:\s*"\(.*\)"\s*,\?$/\1\t\2/p'
}

# Получить node_modules/.bin команды
get_nodejs_bin_commands() {
	module_path="$1"
	if [ -d "$module_path/node_modules/.bin" ]; then
		ls "$module_path/node_modules/.bin" 2>/dev/null | sort
	fi
}

# Получить composer.json scripts
get_composer_json_scripts() {
	module_path="$1"
	[ -f "$module_path/composer.json" ] || return

	# Парсинг через jq (если доступен)
	if command -v jq >/dev/null 2>&1; then
		# Обрабатываем случай когда script это массив (join с " && ")
		jq -r '.scripts // {} | to_entries[] | "\(.key)\t\(if (.value | type) == "array" then (.value | join(" && ")) else .value end)"' "$module_path/composer.json" 2>/dev/null
		return
	fi

	# Fallback: простой парсинг через grep/sed
	# Извлекаем только секцию scripts (до первой закрывающей скобки)
	grep -A 100 '"scripts"' "$module_path/composer.json" 2>/dev/null | \
		sed -n '/"scripts"/,/^[[:space:]]*\}/p' | \
		grep -E '^\s*"[^"]+"\s*:' | \
		grep -v '"scripts"' | \
		sed -n 's/^\s*"\([^"]*\)"\s*:\s*"\(.*\)"\s*,\?$/\1\t\2/p'
}

# Получить vendor/bin команды
get_php_bin_commands() {
	module_path="$1"
	if [ -d "$module_path/vendor/bin" ]; then
		ls "$module_path/vendor/bin" 2>/dev/null | sort
	fi
}

# Получить pyproject.toml scripts
get_pyproject_scripts() {
	module_path="$1"
	[ -f "$module_path/pyproject.toml" ] || return

	# Поддержка [project.scripts] (PEP 621) и [tool.poetry.scripts]
	{
		grep -A 100 '^\[project\.scripts\]' "$module_path/pyproject.toml" 2>/dev/null | \
			grep -E '^[a-z]' | sed 's/ = /\t/' | head -20
		grep -A 100 '^\[tool\.poetry\.scripts\]' "$module_path/pyproject.toml" 2>/dev/null | \
			grep -E '^[a-z]' | sed 's/ = /\t/' | head -20
	} | sort -u
}

# Получить Cargo.toml binary targets
get_cargo_bin_targets() {
	module_path="$1"
	if [ -f "$module_path/Cargo.toml" ]; then
		cd "$module_path" && grep -A 2 '^\[\[bin\]\]' Cargo.toml 2>/dev/null | \
		grep '^name =' | cut -d'"' -f2 | sort
	fi
}
