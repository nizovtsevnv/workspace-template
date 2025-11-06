#!/bin/sh
# ===================================
# Workspace Template - Git команды для модулей
# ===================================
# Обработка команд: pull, push, convert
set -e

# Инициализация общих переменных
. "$(dirname "$0")/../lib/init.sh"

# Загружаем библиотеки
. "$SCRIPT_DIR/lib/ui.sh"
. "$SCRIPT_DIR/lib/modules-git.sh"

# ===================================
# Параметры
# ===================================

MODULE_NAME="$1"
MODULE_GIT_CMD="$2"
shift 2 2>/dev/null || true

# Остальные аргументы
MODULE_GIT_ARGS="$*"

MODULE_PATH="${MODULES_DIR:-modules}/$MODULE_NAME"

# Проверка существования модуля
if [ ! -d "$MODULE_PATH" ]; then
	log_error "Модуль '$MODULE_NAME' не найден в $MODULE_PATH"
	exit 1
fi

# Проверка что команда передана
if [ -z "$MODULE_GIT_CMD" ]; then
	log_error "Не указана git команда"
	log_info "Использование:"
	printf "make %s pull<COL>Синхронизация с удаленным репозиторием\n" "$MODULE_NAME" | print_table 30
	printf "make %s push<COL>Отправка изменений\n" "$MODULE_NAME" | print_table 30
	printf "make %s convert [URL]<COL>Конвертация Local ↔ Git\n" "$MODULE_NAME" | print_table 30
	exit 1
fi

# ===================================
# Обработка команд
# ===================================

case "$MODULE_GIT_CMD" in
	pull)
		# Умная синхронизация: pull + обновление workspace
		module_smart_pull "$MODULE_NAME" "$MODULE_PATH"
		;;

	push)
		# Умная синхронизация: commit + push + обновление workspace
		module_smart_push "$MODULE_NAME" "$MODULE_PATH"
		;;

	convert)
		# Умная конвертация: автоопределение направления
		# URL может быть передан как аргумент: make <module> convert URL=...
		# или как переменная окружения MODULE_GIT_URL
		git_url=""

		# Проверяем MODULE_GIT_URL из окружения
		if [ -n "$MODULE_GIT_URL" ]; then
			git_url="$MODULE_GIT_URL"
		fi

		# Если URL передан как аргумент, извлекаем его
		for arg in $MODULE_GIT_ARGS; do
			case "$arg" in
				URL=*)
					git_url="${arg#URL=}"
					;;
			esac
		done

		module_convert "$MODULE_NAME" "$MODULE_PATH" "$git_url"
		;;

	*)
		log_error "Неизвестная git команда: $MODULE_GIT_CMD"
		log_info "Доступные команды:"
		printf "pull<COL>Синхронизация с удаленным репозиторием<ROW>push<COL>Отправка изменений<ROW>convert<COL>Конвертация Local ↔ Git\n" | print_table 12
		printf "\n"
		log_info "Для выполнения обычных git команд используйте:"
		printf "make %s git <команда><COL>Например: make %s git status\n" "$MODULE_NAME" "$MODULE_NAME" | print_table 30
		exit 1
		;;
esac
