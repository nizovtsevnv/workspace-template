#!/bin/sh
# ===================================
# Workspace Template - Создание модуля
# ===================================
set -e

# Инициализация общих переменных
. "$(dirname "$0")/../lib/init.sh"

# Загружаем библиотеки
. "$SCRIPT_DIR/lib/ui.sh"

# Загружаем библиотеку генераторов
. "$WORKSPACE_ROOT/.template/scripts/lib/generator.sh"

# Переменные (могут быть переданы из окружения)
MODULE_STACK="${MODULE_STACK:-}"
MODULE_TYPE="${MODULE_TYPE:-}"
MODULE_NAME="${MODULE_NAME:-}"
MODULE_TARGET="${MODULE_TARGET:-modules}"

# ===================================
# Wizard
# ===================================

log_section "Создание нового модуля"
printf "\n"

# Шаг 1/3: Выбор стека технологий
if [ -z "$MODULE_STACK" ]; then
	log_info "Шаг 1/3: Выберите стек технологий"
	display=$(select_menu "C" "Node.js" "PHP" "Python" "Rust" "Zig") || exit 1
	case "$display" in
		"C") stack="c" ;;
		"Node.js") stack="nodejs" ;;
		"PHP") stack="php" ;;
		"Python") stack="python" ;;
		"Rust") stack="rust" ;;
		"Zig") stack="zig" ;;
	esac
	printf "\n"
else
	stack="$MODULE_STACK"
fi

# Шаг 2/3: Выбор типа проекта
if [ -z "$MODULE_TYPE" ]; then
	log_info "Шаг 2/3: Выберите тип проекта"

	case "$stack" in
		c)
			sel=$(select_menu "Makefile (классический проект)" "CMake (современный проект)") || exit 1
			case "$sel" in
				"Makefile"*) type="makefile" ;;
				"CMake"*) type="cmake" ;;
			esac
			;;
		zig)
			sel=$(select_menu "Executable (исполняемый файл)" "Library (библиотека)") || exit 1
			case "$sel" in
				"Executable"*) type="exe" ;;
				"Library"*) type="lib" ;;
			esac
			;;
		nodejs)
			sel=$(select_menu "Bun (TypeScript)" "npm (TypeScript)" "pnpm (TypeScript)" "yarn (TypeScript)" "Next.js (TypeScript + Tailwind)" "Expo (TypeScript)" "SvelteKit (TypeScript)" "Supabase (Backend + Edge Functions)") || exit 1
			case "$sel" in
				"Bun"*) type="bun" ;;
				"npm"*) type="npm" ;;
				"pnpm"*) type="pnpm" ;;
				"yarn"*) type="yarn" ;;
				"Next.js"*) type="nextjs" ;;
				"Expo"*) type="expo" ;;
				"SvelteKit"*) type="svelte" ;;
				"Supabase"*) type="supabase" ;;
			esac
			;;
		php)
			sel=$(select_menu "Composer library" "Composer project" "Laravel") || exit 1
			case "$sel" in
				"Composer library") type="composer-lib" ;;
				"Composer project") type="composer-project" ;;
				"Laravel") type="laravel" ;;
			esac
			;;
		python)
			sel=$(select_menu "UV (быстрый, рекомендуется)" "Poetry") || exit 1
			case "$sel" in
				"UV"*) type="uv" ;;
				"Poetry") type="poetry" ;;
			esac
			;;
		rust)
			sel=$(select_menu "Binary (приложение)" "Library (библиотека)" "Dioxus (веб-приложение)") || exit 1
			case "$sel" in
				"Binary"*) type="bin" ;;
				"Library"*) type="lib" ;;
				"Dioxus"*) type="dioxus" ;;
			esac
			;;
	esac
	printf "\n"
else
	type="$MODULE_TYPE"
fi

# Шаг 3/3: Запрос имени модуля
if [ -z "$MODULE_NAME" ]; then
	log_info "Шаг 3/3: Введите имя модуля (буквы, цифры, дефис, подчеркивание)"
	printf "\n"
	name=$(ask_input "Имя модуля" "example-module")
	if [ -z "$name" ]; then
		log_error "Имя не может быть пустым"
		exit 1
	fi
	printf "\n"
else
	name="$MODULE_NAME"
fi

# ===================================
# Валидация
# ===================================

# Валидация имени (только буквы, цифры, дефис, подчеркивание)
if ! echo "$name" | grep -qE '^[a-zA-Z0-9_-]+$'; then
	log_error "Имя может содержать только буквы цифры дефис и подчеркивание"
	exit 1
fi

# Проверка что модуль не существует
if [ -d "$MODULE_TARGET/$name" ]; then
	log_error "Модуль $name уже существует в $MODULE_TARGET/"
	exit 1
fi

# Создание директории если не существует
mkdir -p "$MODULE_TARGET" 2>/dev/null || true

# ===================================
# Генераторы модулей
# ===================================

# Маппинг стеков для вывода информации
get_stack_display_name() {
	case "$1" in
		c) echo "C" ;;
		nodejs) echo "Node.js" ;;
		php) echo "PHP" ;;
		python) echo "Python" ;;
		rust) echo "Rust" ;;
		zig) echo "Zig" ;;
		*) echo "$1" ;;
	esac
}

create_module() {
	stack_display=$(get_stack_display_name "$stack")

	# Определяем нужно ли использовать интерактивный режим
	use_interactive=0
	case "$stack-$type" in
		nodejs-nextjs|nodejs-expo|nodejs-svelte)
			use_interactive=1
			;;
	esac

	# Запуск генератора
	if [ $use_interactive -eq 1 ]; then
		log_info "Создание $stack_display модуля ($type): $name"
		printf "\n"

		run_generator_interactive "$stack" "$type" "$name" "$MODULE_TARGET"
		exit_code=$?

		printf "\n"

		if [ $exit_code -ne 0 ]; then
			log_error "Ошибка создания модуля"
			exit $exit_code
		fi
	else
		show_spinner "Создание $stack_display модуля ($type): $name" \
			run_generator "$stack" "$type" "$name" "$MODULE_TARGET"
	fi

	# Копирование assets на хосте (после генерации в контейнере)
	# Маппинг типов для Node.js (базовые типы используют 'base')
	asset_type="$type"
	case "$stack-$type" in
		nodejs-bun|nodejs-npm|nodejs-pnpm|nodejs-yarn)
			asset_type="base"
			;;
	esac

	# Копируем common assets
	if [ -d "$WORKSPACE_ROOT/.template/assets/$stack/common" ]; then
		cp -rf "$WORKSPACE_ROOT/.template/assets/$stack/common"/. "$MODULE_TARGET/$name/" 2>/dev/null || true
	fi

	# Копируем тип-специфичные assets
	if [ -d "$WORKSPACE_ROOT/.template/assets/$stack/$asset_type" ]; then
		cp -rf "$WORKSPACE_ROOT/.template/assets/$stack/$asset_type"/. "$MODULE_TARGET/$name/" 2>/dev/null || true
	fi

	# Подстановка переменных в README.md
	if [ -f "$MODULE_TARGET/$name/README.md" ]; then
		sed -i -e "s/{{MODULE_NAME}}/$name/g" \
			-e "s/{{STACK}}/$stack_display/g" \
			-e "s/{{TYPE}}/$type/g" \
			"$MODULE_TARGET/$name/README.md"
	fi

	# Git инициализация на хосте
	if command -v git >/dev/null 2>&1; then
		(
			cd "$MODULE_TARGET/$name" || exit 1
			git init >/dev/null 2>&1
			git add . >/dev/null 2>&1
			git commit -m "Initial commit from template" >/dev/null 2>&1
		) || log_warning "Git инициализация пропущена"
	fi

	log_success "$stack_display модуль создан: $MODULE_TARGET/$name"
}

# Запуск генератора
create_module
