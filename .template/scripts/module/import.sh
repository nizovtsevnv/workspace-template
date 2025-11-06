#!/bin/sh
# ===================================
# Workspace Template - Импорт модуля из git
# ===================================
set -e

# Инициализация общих переменных
. "$(dirname "$0")/../lib/init.sh"

# Загружаем библиотеки
. "$SCRIPT_DIR/lib/ui.sh"
. "$SCRIPT_DIR/lib/modules-git.sh"

# Переменные (могут быть переданы из окружения)
MODULE_GIT_URL="${MODULE_GIT_URL:-}"
MODULE_NAME="${MODULE_NAME:-}"
MODULE_GIT_BRANCH="${MODULE_GIT_BRANCH:-main}"
MODULE_TARGET="${MODULE_TARGET:-modules}"

# ===================================
# Wizard
# ===================================

log_section "Импорт модуля из Git репозитория"
printf "\n"

# Шаг 1/3: Запрос URL репозитория
if [ -z "$MODULE_GIT_URL" ]; then
	log_info "Шаг 1/3: Введите URL git репозитория"
	printf "\n"

	git_url=$(ask_input "Git URL (ssh или https)")

	if [ -z "$git_url" ]; then
		log_error "URL не может быть пустым"
		exit 1
	fi

	# Базовая валидация URL
	case "$git_url" in
		git@*|https://*)
			# Валидный URL
			;;
		*)
			log_warning "URL должен начинаться с git@ или https://"
			;;
	esac

	printf "\n"
else
	git_url="$MODULE_GIT_URL"
fi

# Шаг 2/3: Запрос имени модуля
if [ -z "$MODULE_NAME" ]; then
	log_info "Шаг 2/3: Введите имя модуля"
	printf "\n"

	# Предлагаем имя из URL (последняя часть пути без .git)
	suggested_name=$(basename "$git_url" .git)

	name=$(ask_input_with_default "$suggested_name" "Имя модуля")

	if [ -z "$name" ]; then
		log_error "Имя не может быть пустым"
		exit 1
	fi

	printf "\n"
else
	name="$MODULE_NAME"
fi

# Шаг 3/3: Запрос ветки
if [ -z "$MODULE_GIT_BRANCH" ] || [ "$MODULE_GIT_BRANCH" = "main" ]; then
	log_info "Шаг 3/3: Выберите ветку"
	printf "\n"

	branch=$(ask_input_with_default "main" "Ветка")

	if [ -z "$branch" ]; then
		branch="main"
	fi

	printf "\n"
else
	branch="$MODULE_GIT_BRANCH"
fi

# ===================================
# Валидация
# ===================================

# Валидация имени (только буквы, цифры, дефис, подчеркивание)
if ! echo "$name" | grep -qE '^[a-zA-Z0-9_-]+$'; then
	log_error "Имя может содержать только буквы, цифры, дефис и подчеркивание"
	exit 1
fi

# Проверка что модуль не существует
module_full_path="$MODULE_TARGET/$name"

if [ -d "$module_full_path" ]; then
	log_error "Модуль $name уже существует в $MODULE_TARGET/"
	exit 1
fi

# ===================================
# Импорт
# ===================================

log_info "Импорт модуля $name из $git_url (ветка: $branch)"
printf "\n"

# Выполняем импорт через git submodule add
if show_spinner "Добавление git submodule" \
	git submodule add -b "$branch" "$git_url" "$module_full_path"; then

	# Инициализируем submodule
	show_spinner "Инициализация submodule" \
		git submodule update --init "$module_full_path"

	printf "\n"
	log_success "Модуль '$name' успешно импортирован"
	printf "\n"

	# Показываем информацию о модуле
	log_info "Информация о модуле:"
	printf "Имя<COL>%s<ROW>Путь<COL>%s<ROW>URL<COL>%s<ROW>Ветка<COL>%s\n" "$name" "$module_full_path" "$git_url" "$branch" | print_table 12
	printf "\n"

	log_info "Доступные команды:"
	printf "make %s<COL>Показать справку по модулю<ROW>make %s pull<COL>Обновить из удаленного репозитория<ROW>make %s push<COL>Отправить изменения<ROW>make %s git status<COL>Проверить статус\n" "$name" "$name" "$name" "$name" | print_table 30
	printf "\n"

	log_info "Не забудьте закоммитить изменения в workspace:"
	printf "git add .gitmodules %s<COL>\n" "$module_full_path" | print_table 50
	printf "git commit -m \"feat: add %s module\"<COL>\n" "$name" | print_table 50

else
	printf "\n"
	log_error "Не удалось импортировать модуль"
	log_info "Проверьте:"
	log_info "  - Доступность URL: $git_url"
	log_info "  - Существование ветки: $branch"
	log_info "  - Права доступа к репозиторию"
	exit 1
fi
