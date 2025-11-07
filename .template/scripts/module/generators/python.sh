#!/bin/sh
# ===================================
# Python Module Generator
# ===================================
# Генератор модулей для Python
# Использование: generate-python.sh <type> <name> <target_dir>
# Типы: uv, poetry

set -e

# Загрузка общих функций
# Используем относительный путь от текущего файла
. "$(dirname "$0")/../../lib/generator-common.sh"

# Параметры
MODULE_TYPE="$1"
MODULE_NAME="$2"
MODULE_TARGET="$3"

# Валидация параметров
validate_generator_params "$MODULE_TYPE" "$MODULE_NAME" "$MODULE_TARGET" "uv, poetry" || exit 1

# Создать целевую директорию
create_target_dir "$MODULE_TARGET"

# ===================================
# Генераторы по типам
# ===================================

case "$MODULE_TYPE" in
	uv)
		cd "$MODULE_TARGET"
		uv init "$MODULE_NAME"
		;;

	poetry)
		cd "$MODULE_TARGET"
		poetry new "$MODULE_NAME"

		# Создать test_main.py
		mkdir -p "$MODULE_NAME/tests"
		cat > "$MODULE_NAME/tests/test_main.py" <<'EOF'
def test_main():
    print("python test passed")
    assert True
EOF
		;;

	*)
		handle_unknown_type "$MODULE_TYPE" "uv, poetry"
		;;
esac

# Копирование конфигураций из assets
copy_stack_assets "python" "$MODULE_TARGET/$MODULE_NAME" "$MODULE_TYPE"

# Завершение
finish_generator "Python" "$MODULE_TARGET/$MODULE_NAME"
