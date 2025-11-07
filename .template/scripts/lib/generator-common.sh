#!/bin/sh
# ===================================
# Generator Common - Общие функции для генераторов модулей
# ===================================
# Переиспользуемые функции для всех генераторов стеков
# Использование: . lib/generator-common.sh

# ===================================
# Валидация параметров генератора
# ===================================
# Проверяет наличие всех обязательных параметров
# Параметры:
#   $1 - тип модуля
#   $2 - имя модуля
#   $3 - целевая директория
#   $4 - строка доступных типов для справки (например: "bun, npm, pnpm, yarn")
# Возвращает: 0 если параметры валидны, 1 если нет
# Использование: validate_generator_params "$MODULE_TYPE" "$MODULE_NAME" "$MODULE_TARGET" "bun, npm, pnpm, yarn"
validate_generator_params() {
	module_type="$1"
	module_name="$2"
	module_target="$3"
	available_types="$4"

	if [ -z "$module_type" ] || [ -z "$module_name" ] || [ -z "$module_target" ]; then
		echo "Использование: $0 <type> <name> <target_dir>" >&2
		echo "Типы: $available_types" >&2
		return 1
	fi

	return 0
}

# ===================================
# Создание целевой директории
# ===================================
# Создает директорию для модуля если не существует
# Параметр: $1 - путь к целевой директории
# Использование: create_target_dir "$MODULE_TARGET"
create_target_dir() {
	target_dir="$1"
	mkdir -p "$target_dir"
}

# ===================================
# Копирование assets стека
# ===================================
# Копирует конфигурационные файлы из .template/assets/<stack>/
# Поддерживает декомпозицию: common/ и тип-специфичные директории
# Параметры:
#   $1 - имя стека (nodejs, php, python, rust, c, zig)
#   $2 - целевая директория модуля
#   $3 - тип модуля (опционально, если не указан - копирует только common)
# Возвращает: 0 всегда (игнорирует ошибки копирования)
# Использование: copy_stack_assets "nodejs" "$MODULE_TARGET/$MODULE_NAME" "$MODULE_TYPE"
copy_stack_assets() {
	stack_name="$1"
	module_path="$2"
	module_type="${3:-base}"  # По умолчанию 'base' если не указано

	assets_base="/workspace/.template/assets/$stack_name"

	# Копируем common/ (если есть)
	# -f: принудительная перезапись существующих файлов
	if [ -d "$assets_base/common" ]; then
		cp -rf "$assets_base/common"/. "$module_path/" 2>/dev/null || true
	fi

	# Копируем тип-специфичные файлы (если есть)
	# Тип-специфичные файлы перезаписывают файлы из common
	if [ -d "$assets_base/$module_type" ]; then
		cp -rf "$assets_base/$module_type"/. "$module_path/" 2>/dev/null || true
	fi
}

# ===================================
# Завершение генерации модуля
# ===================================
# Выводит сообщение об успешном создании модуля
# Параметры:
#   $1 - имя стека (для отображения, например "Node.js", "PHP")
#   $2 - путь к созданному модулю
# Использование: finish_generator "Node.js" "$MODULE_TARGET/$MODULE_NAME"
finish_generator() {
	stack_display="$1"
	module_path="$2"

	echo "✅ $stack_display модуль создан: $module_path"
}

# ===================================
# Обработчик неизвестного типа
# ===================================
# Выводит ошибку о неизвестном типе модуля и завершает выполнение
# Параметры:
#   $1 - переданный тип модуля
#   $2 - строка доступных типов (например: "bun, npm, pnpm, yarn")
# Использование: handle_unknown_type "$MODULE_TYPE" "bun, npm, pnpm, yarn"
handle_unknown_type() {
	module_type="$1"
	available_types="$2"

	echo "Неизвестный тип: $module_type" >&2
	echo "Доступные типы: $available_types" >&2
	exit 1
}
