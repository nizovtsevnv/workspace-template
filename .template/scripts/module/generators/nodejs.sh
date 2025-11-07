#!/bin/sh
# ===================================
# Node.js Module Generator
# ===================================
# Генератор модулей для Node.js экосистемы
# Использование: generate-nodejs.sh <type> <name> <target_dir>
# Типы: bun, npm, pnpm, yarn, nextjs, expo, svelte

set -e

# Загрузка общих функций
# Используем относительный путь от текущего файла
. "$(dirname "$0")/../../lib/generator-common.sh"

# Параметры
MODULE_TYPE="$1"
MODULE_NAME="$2"
MODULE_TARGET="$3"

# Валидация параметров
validate_generator_params "$MODULE_TYPE" "$MODULE_NAME" "$MODULE_TARGET" "bun, npm, pnpm, yarn, nextjs, expo, svelte, supabase" || exit 1

# Создать целевую директорию
create_target_dir "$MODULE_TARGET"

# ===================================
# Генераторы по типам
# ===================================

case "$MODULE_TYPE" in
	bun)
		cd "$MODULE_TARGET"
		bun init -y "$MODULE_NAME"
		cd "$MODULE_NAME"
		# Добавить scripts для тестов и сборки
		npm pkg set scripts.test="echo 'nodejs test passed'"
		npm pkg set scripts.build="echo 'nodejs build passed'"
		;;

	npm)
		mkdir -p "$MODULE_TARGET/$MODULE_NAME"
		cd "$MODULE_TARGET/$MODULE_NAME"
		npm init -y
		npm pkg set type=module
		npm pkg set scripts.test="echo 'nodejs test passed'"
		npm pkg set scripts.build="echo 'nodejs build passed'"
		;;

	pnpm)
		mkdir -p "$MODULE_TARGET/$MODULE_NAME"
		cd "$MODULE_TARGET/$MODULE_NAME"
		pnpm init
		npm pkg set type=module
		npm pkg set scripts.test="echo 'nodejs test passed'"
		npm pkg set scripts.build="echo 'nodejs build passed'"
		;;

	yarn)
		mkdir -p "$MODULE_TARGET/$MODULE_NAME"
		cd "$MODULE_TARGET/$MODULE_NAME"
		yarn init -y
		npm pkg set type=module
		npm pkg set scripts.test="echo 'nodejs test passed'"
		npm pkg set scripts.build="echo 'nodejs build passed'"
		;;

	nextjs)
		cd "$MODULE_TARGET"
		# Next.js интерактивный генератор с предопределенными опциями
		bunx create-next-app@latest "$MODULE_NAME" \
			--typescript \
			--tailwind \
			--app \
			--no-src-dir \
			--import-alias "@/*" \
			--turbopack \
			--skip-install
		cd "$MODULE_NAME"
		bun install
		;;

	expo)
		cd "$MODULE_TARGET"
		bunx create-expo-app@latest "$MODULE_NAME" --template blank-typescript
		;;

	svelte)
		cd "$MODULE_TARGET"
		bunx sv create "$MODULE_NAME" \
			--template minimal \
			--types ts \
			--no-add-ons \
			--no-install
		cd "$MODULE_NAME"
		bun install
		;;

	supabase)
		mkdir -p "$MODULE_TARGET/$MODULE_NAME"
		cd "$MODULE_TARGET/$MODULE_NAME"

		# Инициализация bun проекта (используем официальный инициализатор)
		bun init -y
		npm pkg set type=module

		# Установка Supabase CLI как dev зависимость
		bun add -d supabase

		# Инициализация Supabase проекта
		bunx supabase init

		# Добавление npm scripts для работы с Supabase
		npm pkg set scripts.start="supabase start"
		npm pkg set scripts.stop="supabase stop"
		npm pkg set scripts.status="supabase status"
		npm pkg set scripts.db:pull="supabase db pull"
		npm pkg set scripts.db:push="supabase db push"
		npm pkg set scripts.db:reset="supabase db reset"
		npm pkg set scripts.migration:new="supabase migration new"
		npm pkg set scripts.types:gen="supabase gen types typescript --local > types/supabase.ts"
		npm pkg set scripts.functions:serve="supabase functions serve"
		npm pkg set scripts.functions:deploy="supabase functions deploy"

		# Создать директорию для типов
		mkdir -p types
		;;

	*)
		handle_unknown_type "$MODULE_TYPE" "bun, npm, pnpm, yarn, nextjs, expo, svelte, supabase"
		;;
esac

# Маппинг типов на соответствующие директории в assets
# Базовые типы (bun, npm, pnpm, yarn) используют assets из 'base'
case "$MODULE_TYPE" in
	bun|npm|pnpm|yarn)
		asset_type="base"
		;;
	*)
		asset_type="$MODULE_TYPE"
		;;
esac

# Копирование конфигураций из assets
copy_stack_assets "nodejs" "$MODULE_TARGET/$MODULE_NAME" "$asset_type"

# Завершение
finish_generator "Node.js" "$MODULE_TARGET/$MODULE_NAME"
