#!/bin/sh
# ===================================
# Module Help библиотека для Workspace Template
# ===================================
# Функции отображения справки по командам модулей
# Использование: . lib/module-help.sh
# shellcheck disable=SC1091,SC3043

# Загружаем необходимые библиотеки
# SCRIPT_DIR должен быть определён через init.sh перед загрузкой библиотек
. "${SCRIPT_DIR:?SCRIPT_DIR не определён}/lib/loader.sh"
load_lib "ui" "log_info"
load_lib "modules" "detect_module_tech"
load_lib "modules-git" "is_git_submodule"

# Показать справку по модулю
# Параметры:
#   $1 - MODULE_NAME - имя модуля
#   $2 - MODULE_PATH - путь к модулю
#   $3 - MODULE_TECH - технологии модуля (через пробел)
# Использование: show_module_help "$MODULE_NAME" "$MODULE_PATH" "$MODULE_TECH"
show_module_help() {
	local MODULE_NAME="$1"
	local MODULE_PATH="$2"
	local MODULE_TECH="$3"

	log_section "Модуль $MODULE_NAME"

	# Версия и технический стек
	version=$(get_module_versions_compact "$MODULE_PATH")
	[ -z "$version" ] && version="(не определена)"

	tech_display=""
	for tech in $MODULE_TECH; do
		case "$tech" in
			nodejs) name="Node.js" ;;
			php) name="PHP" ;;
			python) name="Python" ;;
			rust) name="Rust" ;;
			*) name="$tech" ;;
		esac
		if [ -z "$tech_display" ]; then
			tech_display="$name"
		else
			tech_display="$tech_display, $name"
		fi
	done
	[ -z "$tech_display" ] && tech_display="(не определён)"

	# CI/CD системы
	cicd=$(get_module_cicd "$MODULE_PATH")

	# Git info
	module_type=$(get_module_type_display "$MODULE_PATH")

	# Формируем таблицу с git info
	if is_git_submodule "$MODULE_PATH"; then
		git_url=$(get_submodule_url "$MODULE_PATH")
		git_branch=$(get_submodule_branch "$MODULE_PATH")
		printf "Версия<COL>%s<ROW>Технический стек<COL>%s<ROW>CI/CD<COL>%s<ROW>Тип модуля<COL>%s<ROW>Git репозиторий<COL>%s (branch: %s)\n" \
			"$version" "$tech_display" "$cicd" "$module_type" "$git_url" "$git_branch" | print_table 30
	else
		printf "Версия<COL>%s<ROW>Технический стек<COL>%s<ROW>CI/CD<COL>%s<ROW>Тип модуля<COL>%s\n" \
			"$version" "$tech_display" "$cicd" "$module_type" | print_table 30
	fi
	printf "\n"

	# Использование
	log_info "Использование:"
	printf "make $MODULE_NAME КОМАНДА [АРГУМЕНТЫ]<COL>Выполнение любых команд в папке модуля\n" | print_table 30

	# Git команды (если модуль - git submodule)
	if is_git_submodule "$MODULE_PATH"; then
		printf "\n"
		log_info "Git команды:"
		printf "make %s pull<COL>Синхронизация с удаленным репозиторием\n" "$MODULE_NAME" | print_table 30
		printf "make %s push<COL>Отправка изменений\n" "$MODULE_NAME" | print_table 30
		printf "make %s git <cmd><COL>Выполнить git команду (status, log, checkout...)\n" "$MODULE_NAME" | print_table 30
		printf "make %s convert<COL>Конвертировать в локальный модуль\n" "$MODULE_NAME" | print_table 30
	else
		printf "\n"
		log_info "Конвертация:"
		printf "make %s convert URL=...<COL>Конвертировать в git submodule\n" "$MODULE_NAME" | print_table 30
	fi

	# Показать секции команд в зависимости от стека
	# Система приоритетов: Makefile > PM > Scripts > Bin commands
	used_commands=$(mktemp)
	# shellcheck disable=SC2064
	trap "rm -f $used_commands" EXIT INT TERM

	for tech in $MODULE_TECH; do
		case "$tech" in
			nodejs)
				# 1. Команды Makefile
				show_makefile_section "$MODULE_PATH" "$MODULE_NAME" "$used_commands"

				# 2. Пакетные менеджеры
				printf "\n"
				log_info "Пакетные менеджеры:"
				for pm in bun npm pnpm yarn; do
					if ! grep -q "^${pm}$" "$used_commands" 2>/dev/null; then
						printf "make $MODULE_NAME %s<COL>\n" "$pm"
						echo "$pm" >> "$used_commands"
					fi
				done | print_table 30

			# 3. Команды package.json
			pkg_scripts=$(get_package_json_scripts "$MODULE_PATH")
			if [ -n "$pkg_scripts" ]; then
				printf "\n"
				log_info "Команды package.json:"
				echo "$pkg_scripts" | sort | while IFS='	' read -r name command; do
					if ! grep -q "^${name}$" "$used_commands" 2>/dev/null; then
						printf "make $MODULE_NAME %s<COL>%s\n" "$name" "$command"
						echo "$name" >> "$used_commands"
					fi
				done | print_table 30
			fi

			# 4. Команды npx
			npx_cmds=$(get_nodejs_bin_commands "$MODULE_PATH")
			if [ -n "$npx_cmds" ]; then
				printf "\n"
				log_info "Команды npx:"
				echo "$npx_cmds" | while read -r cmd; do
					if ! grep -q "^${cmd}$" "$used_commands" 2>/dev/null; then
						printf "make $MODULE_NAME %s<COL>\n" "$cmd"
						echo "$cmd" >> "$used_commands"
					fi
				done | print_table 30
			fi
				;;

			php)
				# 1. Команды Makefile
				show_makefile_section "$MODULE_PATH" "$MODULE_NAME" "$used_commands"

				# 2. Пакетные менеджеры
				printf "\n"
				log_info "Пакетные менеджеры:"
				if ! grep -q "^composer$" "$used_commands" 2>/dev/null; then
					printf "make $MODULE_NAME composer<COL>\n"
					echo "composer" >> "$used_commands"
				fi | print_table 30

				# 3. Команды composer.json
				composer_scripts=$(get_composer_json_scripts "$MODULE_PATH")
				if [ -n "$composer_scripts" ]; then
					printf "\n"
					log_info "Команды composer.json:"
					echo "$composer_scripts" | sort | while IFS='	' read -r name command; do
						if ! grep -q "^${name}$" "$used_commands" 2>/dev/null; then
							printf "make $MODULE_NAME %s<COL>%s\n" "$name" "$command"
							echo "$name" >> "$used_commands"
						fi
					done | print_table 30
				fi

				# 4. Команды vendor/bin
				vendor_cmds=$(get_php_bin_commands "$MODULE_PATH")
				if [ -n "$vendor_cmds" ]; then
					printf "\n"
					log_info "Команды vendor/bin:"
					echo "$vendor_cmds" | while read -r cmd; do
						if ! grep -q "^${cmd}$" "$used_commands" 2>/dev/null; then
							printf "make $MODULE_NAME %s<COL>\n" "$cmd"
							echo "$cmd" >> "$used_commands"
						fi
					done | print_table 30
				fi
				;;

			python)
				# 1. Команды Makefile
				show_makefile_section "$MODULE_PATH" "$MODULE_NAME" "$used_commands"

				# 2. Пакетные менеджеры
				printf "\n"
				log_info "Пакетные менеджеры:"
				for pm in pip pipenv poetry uv; do
					if ! grep -q "^${pm}$" "$used_commands" 2>/dev/null; then
						printf "make $MODULE_NAME %s<COL>\n" "$pm"
						echo "$pm" >> "$used_commands"
					fi
				done | print_table 30

				# 3. Команды pyproject.toml
				pyproject_scripts=$(get_pyproject_scripts "$MODULE_PATH")
				if [ -n "$pyproject_scripts" ]; then
					printf "\n"
					log_info "Команды pyproject.toml:"
					echo "$pyproject_scripts" | sort | while IFS='	' read -r name command; do
						if ! grep -q "^${name}$" "$used_commands" 2>/dev/null; then
							printf "make $MODULE_NAME %s<COL>%s\n" "$name" "$command"
							echo "$name" >> "$used_commands"
						fi
					done | print_table 30
				fi
				;;

			rust)
				# 1. Команды Makefile
				show_makefile_section "$MODULE_PATH" "$MODULE_NAME" "$used_commands"

				# 2. Пакетные менеджеры
				printf "\n"
				log_info "Пакетные менеджеры:"
				if ! grep -q "^cargo$" "$used_commands" 2>/dev/null; then
					printf "make $MODULE_NAME cargo<COL>\n"
					echo "cargo" >> "$used_commands"
				fi | print_table 30

				# 3. Бинарные targets
				cargo_bins=$(get_cargo_bin_targets "$MODULE_PATH")
				if [ -n "$cargo_bins" ]; then
					printf "\n"
					log_info "Бинарные targets:"
					echo "$cargo_bins" | while read -r bin; do
						if ! grep -q "^${bin}$" "$used_commands" 2>/dev/null; then
							printf "make $MODULE_NAME %s<COL>\n" "$bin"
							echo "$bin" >> "$used_commands"
						fi
					done | print_table 30
				fi
				;;
		esac
	done

	rm -f "$used_commands"
	printf "\n"
}
