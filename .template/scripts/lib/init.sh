#!/bin/sh
# ===================================
# Единая инициализация для всех скриптов Workspace Template
# ===================================
# Использование: . "$(dirname "$0")/lib/init.sh"

# Определение SCRIPT_DIR (всегда указывает на .template/scripts/)
# Скрипты могут быть в подкаталогах (module/, template/), но SCRIPT_DIR должен указывать на корень scripts/
if [ -z "$SCRIPT_DIR" ]; then
	# Определяем директорию текущего скрипта
	current_dir="$(cd "$(dirname "$0")" && pwd)"
	# Если скрипт в подкаталоге (module/, template/), поднимаемся на уровень выше
	case "$current_dir" in
		*/module|*/template)
			SCRIPT_DIR="$(cd "$current_dir/.." && pwd)"
			export SCRIPT_DIR
			;;
		*)
			SCRIPT_DIR="$current_dir"
			export SCRIPT_DIR
			;;
	esac
fi

# Переменные читаются из окружения (экспортируются из Makefile через run-script)
# Если их нет - определяем самостоятельно (для прямого вызова скриптов без Makefile)

# Определение корня workspace
export WORKSPACE_ROOT="${WORKSPACE_ROOT:-$(cd "$SCRIPT_DIR/../.." && pwd)}"

# Определение: внутри или снаружи контейнера
# Возвращает 0 если внутри, 1 если снаружи (для совместимости с Makefile)
if [ -z "$IS_INSIDE_CONTAINER" ]; then
	if [ -f /.dockerenv ] || [ -n "$INSIDE_DEVCONTAINER" ]; then
		export IS_INSIDE_CONTAINER=0
	else
		export IS_INSIDE_CONTAINER=1
	fi
fi

# Автоопределение container runtime (docker или podman)
if [ -z "$CONTAINER_RUNTIME" ]; then
	if command -v podman >/dev/null 2>&1; then
		# Проверяем, что podman - это действительно podman, а не symlink на docker
		if podman --version 2>/dev/null | grep -q podman; then
			export CONTAINER_RUNTIME=podman
		elif command -v docker >/dev/null 2>&1 && docker --version 2>/dev/null | grep -qi podman; then
			export CONTAINER_RUNTIME=podman
		elif command -v docker >/dev/null 2>&1; then
			export CONTAINER_RUNTIME=docker
		else
			export CONTAINER_RUNTIME=podman
		fi
	elif command -v docker >/dev/null 2>&1; then
		export CONTAINER_RUNTIME=docker
	else
		# По умолчанию podman
		export CONTAINER_RUNTIME=podman
	fi
fi

# UID и GID хоста для правильных прав доступа
export HOST_UID="${HOST_UID:-$(id -u)}"
export HOST_GID="${HOST_GID:-$(id -g)}"

# Версия образа (если не определена из Makefile)
if [ -z "$CONTAINER_IMAGE_VERSION" ]; then
	if [ -f "$WORKSPACE_ROOT/.template-version" ]; then
		# Читаем из файла .template-version
		CONTAINER_IMAGE_VERSION=$(cat "$WORKSPACE_ROOT/.template-version" 2>/dev/null | sed 's/^v//' | sed 's/-[0-9]*-g.*//' || echo "latest")
	else
		# Пытаемся получить из git
		if command -v git >/dev/null 2>&1 && [ -d "$WORKSPACE_ROOT/.git" ]; then
			VERSION=$(cd "$WORKSPACE_ROOT" && (git describe --tags --exact-match HEAD 2>/dev/null || git describe --tags 2>/dev/null || echo ""))
			if [ -n "$VERSION" ]; then
				CONTAINER_IMAGE_VERSION=$(echo "$VERSION" | sed 's/^v//' | sed 's/-[0-9]*-g.*//')
			else
				CONTAINER_IMAGE_VERSION="latest"
			fi
		else
			CONTAINER_IMAGE_VERSION="latest"
		fi
	fi
	export CONTAINER_IMAGE_VERSION
fi

# Образ контейнера
export CONTAINER_IMAGE="${CONTAINER_IMAGE:-ghcr.io/nizovtsevnv/devcontainer-workspace:${CONTAINER_IMAGE_VERSION}}"

# Директория модулей
export MODULES_DIR="${MODULES_DIR:-modules}"

# Цвета для вывода (используются в ui.sh)
# Если не определены из Makefile - устанавливаем по умолчанию
export COLOR_RESET="${COLOR_RESET:-\033[0m}"
export COLOR_INFO="${COLOR_INFO:-\033[0;36m}"
export COLOR_SUCCESS="${COLOR_SUCCESS:-\033[0;32m}"
export COLOR_WARNING="${COLOR_WARNING:-\033[0;33m}"
export COLOR_ERROR="${COLOR_ERROR:-\033[0;31m}"
export COLOR_SECTION="${COLOR_SECTION:-\033[1;35m}"
export COLOR_DIM="${COLOR_DIM:-\033[2m}"
