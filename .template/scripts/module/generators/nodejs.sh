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
validate_generator_params "$MODULE_TYPE" "$MODULE_NAME" "$MODULE_TARGET" "bun, npm, pnpm, yarn, nextjs, expo, svelte" || exit 1

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

	*)
		handle_unknown_type "$MODULE_TYPE" "bun, npm, pnpm, yarn, nextjs, expo, svelte"
		;;
esac

# Копирование конфигураций из assets
copy_stack_assets "nodejs" "$MODULE_TARGET/$MODULE_NAME"

# Завершение
finish_generator "Node.js" "$MODULE_TARGET/$MODULE_NAME"
