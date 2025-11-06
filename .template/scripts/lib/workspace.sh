#!/bin/sh
# ===================================
# Workspace библиотека
# ===================================
# Общие функции для работы с workspace
# Использование: . lib/workspace.sh

# ===================================
# Функция получения workspace root
# ===================================
# Определяет корень workspace через:
# 1. Переменную окружения WORKSPACE_ROOT (если есть Makefile)
# 2. Git корень (git rev-parse --show-toplevel)
# 3. Текущая директория (если есть Makefile)
# 4. Текущая директория (fallback)
# Возвращает: путь к workspace root
get_workspace_root() {
	workspace_root=""

	# Сначала проверяем WORKSPACE_ROOT из окружения
	if [ -n "$WORKSPACE_ROOT" ] && [ -f "$WORKSPACE_ROOT/Makefile" ]; then
		workspace_root="$WORKSPACE_ROOT"
	# Затем ищем git root
	elif command -v git >/dev/null 2>&1 && git rev-parse --show-toplevel >/dev/null 2>&1; then
		workspace_root=$(git rev-parse --show-toplevel)
	# Затем используем pwd если есть Makefile
	elif [ -f "Makefile" ]; then
		workspace_root=$(pwd)
	else
		# Fallback на текущую директорию
		workspace_root=$(pwd)
	fi

	echo "$workspace_root"
}
