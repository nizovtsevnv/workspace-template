#!/bin/sh
# ===================================
# Rust Module Generator
# ===================================
# Генератор модулей для Rust
# Использование: generate-rust.sh <type> <name> <target_dir>
# Типы: bin, lib, dioxus

set -e

# Загрузка общих функций
# Используем относительный путь от текущего файла
. "$(dirname "$0")/../../lib/generator-common.sh"

# Параметры
MODULE_TYPE="$1"
MODULE_NAME="$2"
MODULE_TARGET="$3"

# Валидация параметров
validate_generator_params "$MODULE_TYPE" "$MODULE_NAME" "$MODULE_TARGET" "bin, lib, dioxus" || exit 1

# Создать целевую директорию
create_target_dir "$MODULE_TARGET"

# ===================================
# Генераторы по типам
# ===================================

case "$MODULE_TYPE" in
	bin)
		cd "$MODULE_TARGET"
		cargo new "$MODULE_NAME"
		;;

	lib)
		cd "$MODULE_TARGET"
		cargo new "$MODULE_NAME" --lib
		;;

	dioxus)
		cd "$MODULE_TARGET"
		cargo new "$MODULE_NAME"
		cd "$MODULE_NAME"
		cargo add dioxus
		cargo add --build dioxus-cli
		;;

	*)
		handle_unknown_type "$MODULE_TYPE" "bin, lib, dioxus"
		;;
esac

# Копирование конфигураций из assets
copy_stack_assets "rust" "$MODULE_TARGET/$MODULE_NAME"

# Завершение
finish_generator "Rust" "$MODULE_TARGET/$MODULE_NAME"
