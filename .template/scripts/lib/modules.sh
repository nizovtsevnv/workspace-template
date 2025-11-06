#!/bin/sh
# ===================================
# Библиотека для работы с модулями
# ===================================
# Объединяет функции детектирования, получения информации и проверки команд
# Использование: . lib/modules.sh
#
# Для оптимизации производительности рекомендуется загружать
# только нужные подмодули напрямую:
# - . lib/modules-detect.sh - только детектирование технологий
# - . lib/modules-info.sh - только получение информации
# - . lib/modules-check.sh - только проверка команд
# shellcheck disable=SC1091

# Инициализация SCRIPT_DIR для случаев прямого вызова скрипта
# При вызове через source SCRIPT_DIR должен быть определён через init.sh
if [ -z "$SCRIPT_DIR" ]; then
	SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
fi

# Загружаем loader для правильной инициализации
. "$SCRIPT_DIR/lib/loader.sh"

# Загружаем все подмодули для полной совместимости
. "$SCRIPT_DIR/lib/modules-detect.sh"
. "$SCRIPT_DIR/lib/modules-info.sh"
. "$SCRIPT_DIR/lib/modules-check.sh"

# ===================================
# CLI интерфейс (если скрипт вызван напрямую)
# ===================================
# Оставлено для совместимости, если кто-то вызывает modules.sh напрямую
# Проверяем, что скрипт выполнен напрямую (не через source)
# $0 будет содержать имя скрипта только при прямом выполнении
case "$0" in
	*modules.sh)
		# Скрипт вызван напрямую - обрабатываем CLI аргументы
		if [ -n "$1" ]; then
			case "$1" in
				detect)
					detect_module_tech "$2"
					;;
				info|get-info)
					get_module_info "$2"
					;;
				version)
					get_module_versions_compact "$2"
					;;
				cicd)
					get_module_cicd "$2"
					;;
				*)
					echo "Использование: $0 {detect|info|get-info|version|cicd} <module_path>"
					exit 1
					;;
			esac
		fi
		;;
esac
