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
load_lib "modules-detect" "detect_module_stack"
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

	# Получаем только стеки (без CI/CD и makefile)
	module_stacks=$(detect_module_stack "$MODULE_PATH")

	tech_display=""
	for stack in $module_stacks; do
		# Форматируем имена стеков
		case "$stack" in
			nodejs) name="Node.js" ;;
			php) name="PHP" ;;
			python) name="Python" ;;
			rust) name="Rust" ;;
			*) name="$stack" ;;
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
			"$version" "$tech_display" "$cicd" "$module_type" "$git_url" "$git_branch" | print_table 40
	else
		printf "Версия<COL>%s<ROW>Технический стек<COL>%s<ROW>CI/CD<COL>%s<ROW>Тип модуля<COL>%s\n" \
			"$version" "$tech_display" "$cicd" "$module_type" | print_table 40
	fi
	printf "\n"

	# Git команды / Обслуживание модуля (в зависимости от типа)
	if is_git_submodule "$MODULE_PATH"; then
		log_info "Обслуживание модуля:"
		printf "make %s pull<COL>Синхронизация с удаленным репозиторием\n" "$MODULE_NAME" | print_table 40
		printf "make %s push<COL>Отправка изменений\n" "$MODULE_NAME" | print_table 40
		printf "make %s convert<COL>Конвертировать в локальный модуль\n" "$MODULE_NAME" | print_table 40
	else
		log_info "Обслуживание модуля:"
		printf "make %s convert<COL>Конвертировать в git submodule\n" "$MODULE_NAME" | print_table 40
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


			# 2. Команды package.json
			pkg_scripts=$(get_package_json_scripts "$MODULE_PATH")
			if [ -n "$pkg_scripts" ]; then
				printf "\n"
				log_info "Команды package.json:"
				echo "$pkg_scripts" | sort | while IFS='	' read -r name command; do
					if ! grep -q "^${name}$" "$used_commands" 2>/dev/null; then
						printf "make $MODULE_NAME %s<COL>%s\n" "$name" "$command"
						echo "$name" >> "$used_commands"
					fi
				done | print_table 40
			fi

			# 3. Команды npx
			npx_cmds=$(get_nodejs_bin_commands "$MODULE_PATH")
			if [ -n "$npx_cmds" ]; then
				printf "\n"
				log_info "Команды npx:"
				echo "$npx_cmds" | while read -r cmd; do
					if ! grep -q "^${cmd}$" "$used_commands" 2>/dev/null; then
						printf "make $MODULE_NAME %s<COL>\n" "$cmd"
						echo "$cmd" >> "$used_commands"
					fi
				done | print_table 40
			fi
				;;

			php)
				# 1. Команды Makefile
				show_makefile_section "$MODULE_PATH" "$MODULE_NAME" "$used_commands"


				# 2. Команды vendor/bin
				vendor_cmds=$(get_php_bin_commands "$MODULE_PATH")
				if [ -n "$vendor_cmds" ]; then
					printf "\n"
					log_info "Команды vendor/bin:"
					echo "$vendor_cmds" | while read -r cmd; do
						if ! grep -q "^${cmd}$" "$used_commands" 2>/dev/null; then
							printf "make $MODULE_NAME %s<COL>\n" "$cmd"
							echo "$cmd" >> "$used_commands"
						fi
					done | print_table 40
				fi
				;;

			python)
				# 1. Команды Makefile
				show_makefile_section "$MODULE_PATH" "$MODULE_NAME" "$used_commands"


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
					done | print_table 40
				fi
				;;

			rust)
				# 1. Команды Makefile
				show_makefile_section "$MODULE_PATH" "$MODULE_NAME" "$used_commands"

				;;
		esac
	done

	rm -f "$used_commands"
	printf "\n"
}
