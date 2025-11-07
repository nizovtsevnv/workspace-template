#!/bin/sh
# ===================================
# Workspace Template - Справка
# ===================================
set -e

# Инициализация общих переменных
. "$(dirname "$0")/lib/init.sh"

# Загружаем библиотеки
. "$SCRIPT_DIR/lib/ui.sh"
. "$SCRIPT_DIR/lib/modules.sh"
. "$SCRIPT_DIR/lib/template.sh"

# ===================================
# Основная логика
# ===================================

# Получить название текущего каталога (имя проекта)
project_name=$(basename "$WORKSPACE_ROOT")
log_section "$project_name"
printf "\n"

# ===================================
# Секция: Среда разработки
# ===================================

log_info "Среда разработки"

# Проверяем статус инициализации
check_project_init_status

# Формируем данные для таблицы в зависимости от статуса инициализации
if [ "$STATUS" = "не инициализирован" ]; then
	commands_data="make init<COL>Инициализация проекта из шаблона<ROW>make module create<COL>Создать новый модуль (Node.js, PHP, Python, Rust)<ROW>make module import<COL>Импортировать модуль из git репозитория<ROW>make module pull<COL>Инициализация и обновление всех субмодулей<ROW>make module status<COL>Статус всех субмодулей<ROW>make template test<COL>Запустить автотесты шаблона<ROW>make template update<COL>Обновить версию шаблона"
else
	commands_data="make module create<COL>Создать новый модуль (Node.js, PHP, Python, Rust)<ROW>make module import<COL>Импортировать модуль из git репозитория<ROW>make module pull<COL>Инициализация и обновление всех субмодулей<ROW>make module status<COL>Статус всех субмодулей<ROW>make template test<COL>Запустить автотесты шаблона<ROW>make template update<COL>Обновить версию шаблона"
fi

printf "%s\n" "$commands_data" | print_table 24

printf "\n"

# ===================================
# Секция: Модули проекта
# ===================================

log_info "Модули проекта"

MODULES_DIR="${MODULES_DIR:-modules}"

# Проверяем наличие модулей (директорий, не считая .gitkeep и скрытые файлы)
modules_data=""
has_modules=false

if [ -d "$MODULES_DIR" ]; then
	for module_path in "$MODULES_DIR"/*; do
		[ -d "$module_path" ] || continue
		module=$(basename "$module_path")

		# Пропускаем скрытые директории
		case "$module" in
			.*) continue ;;
		esac

		has_modules=true
		tech_info=$(get_module_info "$module_path")

		if [ -z "$modules_data" ]; then
			modules_data="make ${module}<COL>${tech_info}"
		else
			modules_data="${modules_data}<ROW>make ${module}<COL>${tech_info}"
		fi
	done
fi

if [ "$has_modules" = true ] && [ -n "$modules_data" ]; then
	printf "%s\n" "$modules_data" | print_table 24
	printf "\n"
	log_info "Используйте: make <модуль> для просмотра доступных команд"
	printf "  Пример: make hello install, make hello test, make hello build\n"
else
	printf "  ${COLOR_DIM}Модули не найдены${COLOR_RESET}\n"
fi

printf "\n"

# ===================================
# Подсказка для неинициализированного проекта
# ===================================

if [ "$STATUS" = "не инициализирован" ]; then
	log_info "Начало работы с проектом"
	printf "  1. Инициализируйте проект: ${COLOR_SUCCESS}make init${COLOR_RESET}\n"
	printf "  2. Создайте первый модуль: ${COLOR_SUCCESS}make module create${COLOR_RESET}\n"
	printf "  3. Начните разработку в выбранном модуле\n"
	printf "\n"
fi
