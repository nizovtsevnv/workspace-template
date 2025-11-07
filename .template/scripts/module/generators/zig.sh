#!/bin/sh
# ===================================
# Zig Module Generator
# ===================================
# Генератор модулей для Zig
# Использование: generate-zig.sh <type> <name> <target_dir>
# Типы: exe, lib

set -e

# Загрузка общих функций
# Используем относительный путь от текущего файла
. "$(dirname "$0")/../../lib/generator-common.sh"

# Параметры
MODULE_TYPE="$1"
MODULE_NAME="$2"
MODULE_TARGET="$3"

# Валидация параметров
validate_generator_params "$MODULE_TYPE" "$MODULE_NAME" "$MODULE_TARGET" "exe, lib" || exit 1

# Создать целевую директорию модуля
mkdir -p "$MODULE_TARGET/$MODULE_NAME"

# ===================================
# Генераторы по типам
# ===================================

case "$MODULE_TYPE" in
	exe|lib)
		cd "$MODULE_TARGET/$MODULE_NAME"
		zig init
		;;

	*)
		handle_unknown_type "$MODULE_TYPE" "exe, lib"
		;;
esac

# Копирование конфигураций из assets
copy_stack_assets "zig" "$MODULE_TARGET/$MODULE_NAME" "$MODULE_TYPE"

# Завершение
finish_generator "Zig" "$MODULE_TARGET/$MODULE_NAME"
