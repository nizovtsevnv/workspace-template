#!/bin/sh
# ===================================
# PHP Module Generator
# ===================================
# Генератор модулей для PHP
# Использование: generate-php.sh <type> <name> <target_dir>
# Типы: composer-lib, composer-project, laravel

set -e

# Загрузка общих функций
# Используем относительный путь от текущего файла
. "$(dirname "$0")/../../lib/generator-common.sh"

# Параметры
MODULE_TYPE="$1"
MODULE_NAME="$2"
MODULE_TARGET="$3"

# Валидация параметров
validate_generator_params "$MODULE_TYPE" "$MODULE_NAME" "$MODULE_TARGET" "composer-lib, composer-project, laravel" || exit 1

# Создать целевую директорию
create_target_dir "$MODULE_TARGET"

# ===================================
# Генераторы по типам
# ===================================

case "$MODULE_TYPE" in
	composer-lib)
		mkdir -p "$MODULE_TARGET/$MODULE_NAME"
		cd "$MODULE_TARGET/$MODULE_NAME"
		composer init \
			--name="vendor/$MODULE_NAME" \
			--type=library \
			--no-interaction

		# Добавить test script
		composer config scripts.test "echo 'php test passed'"
		;;

	composer-project)
		mkdir -p "$MODULE_TARGET/$MODULE_NAME"
		cd "$MODULE_TARGET/$MODULE_NAME"
		composer init \
			--name="vendor/$MODULE_NAME" \
			--type=project \
			--no-interaction
		;;

	laravel)
		cd "$MODULE_TARGET"
		laravel new "$MODULE_NAME" --no-interaction
		;;

	*)
		handle_unknown_type "$MODULE_TYPE" "composer-lib, composer-project, laravel"
		;;
esac

# Копирование конфигураций из assets
copy_stack_assets "php" "$MODULE_TARGET/$MODULE_NAME"

# Завершение
finish_generator "PHP" "$MODULE_TARGET/$MODULE_NAME"
