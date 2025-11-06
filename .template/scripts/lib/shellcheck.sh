#!/bin/sh
# ===================================
# Shell Tools библиотека для Workspace Template
# ===================================
# Функции для запуска shell-утилит с автоматическим определением окружения
# Использование: . lib/shellcheck.sh
#
# Доступные функции:
# - run_shellcheck: запуск shellcheck для проверки shell скриптов
# - run_jq: запуск jq для парсинга JSON
# - run_yq: запуск yq для парсинга YAML

# Имя образа для shell-утилит (включает shellcheck, jq, yq, bash, curl, git)
readonly SH_TOOLS_IMAGE="devcontainer-sh"
readonly SH_TOOLS_DOCKERFILE=".template/dockerfiles/sh.Dockerfile"

# Для обратной совместимости
readonly SHELLCHECK_IMAGE="$SH_TOOLS_IMAGE"
readonly SHELLCHECK_DOCKERFILE="$SH_TOOLS_DOCKERFILE"

# ===================================
# Функция запуска shellcheck
# ===================================
# Автоматически определяет где запустить shellcheck:
# 1. Если доступен на хосте - использует хостовый
# 2. Если нет - запускает в легковесном Alpine контейнере
#
# Параметры: все параметры передаются в shellcheck
# Возвращает: код завершения shellcheck
# Использование: run_shellcheck -x script.sh
run_shellcheck() {
	# Проверка наличия shellcheck на хосте
	if command -v shellcheck >/dev/null 2>&1; then
		# Используем хостовый shellcheck
		shellcheck "$@"
		return $?
	fi

	# На хосте shellcheck нет - используем контейнер

	# Проверка наличия container runtime
	if ! command -v "$CONTAINER_RUNTIME" >/dev/null 2>&1; then
		echo "❌ Ошибка: shellcheck не найден на хосте и $CONTAINER_RUNTIME недоступен" >&2
		return 1
	fi

	# Определение корня workspace
	# Сначала проверяем WORKSPACE_ROOT из окружения, затем ищем git root, затем используем pwd
	workspace_root=""
	if [ -n "$WORKSPACE_ROOT" ] && [ -f "$WORKSPACE_ROOT/Makefile" ]; then
		workspace_root="$WORKSPACE_ROOT"
	elif command -v git >/dev/null 2>&1 && git rev-parse --show-toplevel >/dev/null 2>&1; then
		workspace_root=$(git rev-parse --show-toplevel)
	elif [ -f "Makefile" ]; then
		workspace_root=$(pwd)
	else
		echo "❌ Ошибка: не удалось определить корень workspace" >&2
		return 1
	fi

	# Проверка наличия Dockerfile
	# Сначала ищем в workspace_root, затем в текущей директории (для тестов)
	dockerfile_path=""
	if [ -f "$workspace_root/$SHELLCHECK_DOCKERFILE" ]; then
		dockerfile_path="$workspace_root/$SHELLCHECK_DOCKERFILE"
	elif [ -f "$SHELLCHECK_DOCKERFILE" ]; then
		dockerfile_path="$SHELLCHECK_DOCKERFILE"
	else
		echo "❌ Ошибка: не найден $SHELLCHECK_DOCKERFILE" >&2
		return 1
	fi

	# Проверка и сборка образа если нужно
	if ! $CONTAINER_RUNTIME images -q "$SHELLCHECK_IMAGE" 2>/dev/null | grep -q .; then
		echo "🔨 Сборка образа $SHELLCHECK_IMAGE..." >&2
		dockerfile_dir=$(dirname "$dockerfile_path")
		if ! $CONTAINER_RUNTIME build \
			-t "$SHELLCHECK_IMAGE" \
			-f "$dockerfile_path" \
			"$dockerfile_dir" >/dev/null 2>&1; then
			echo "❌ Ошибка сборки образа $SHELLCHECK_IMAGE" >&2
			return 1
		fi
		echo "✅ Образ собран успешно" >&2
	fi

	# Запуск shellcheck в контейнере
	# --rm: автоматическое удаление контейнера после выполнения
	# -v: монтирование workspace (только чтение для shellcheck)
	# -w: рабочая директория
	# Формируем команду как строку для sh -c
	cmd="shellcheck"
	for arg in "$@"; do
		# Экранируем одинарные кавычки в аргументах
		escaped_arg=$(printf '%s' "$arg" | sed "s/'/'\\\\''/g")
		cmd="$cmd '$escaped_arg'"
	done

	$CONTAINER_RUNTIME run --rm \
		-v "$workspace_root:/workspace:ro" \
		-w /workspace \
		"$SHELLCHECK_IMAGE" \
		"$cmd"

	return $?
}

# ===================================
# Универсальная функция запуска инструмента из sh образа
# ===================================
# Запускает любой инструмент из образа devcontainer-sh
# Параметры:
#   $1 - имя инструмента (jq, yq, bash, git, curl, etc.)
#   $@ - остальные параметры передаются инструменту
# Использование: _run_sh_tool jq '.' file.json
_run_sh_tool() {
	tool_name="$1"
	shift

	# Проверка наличия инструмента на хосте
	if command -v "$tool_name" >/dev/null 2>&1; then
		# Используем хостовый инструмент
		"$tool_name" "$@"
		return $?
	fi

	# На хосте инструмента нет - используем контейнер

	# Проверка наличия container runtime
	if ! command -v "$CONTAINER_RUNTIME" >/dev/null 2>&1; then
		echo "❌ Ошибка: $tool_name не найден на хосте и $CONTAINER_RUNTIME недоступен" >&2
		return 1
	fi

	# Определение корня workspace (повторяем логику из run_shellcheck)
	workspace_root=""
	if [ -n "$WORKSPACE_ROOT" ] && [ -f "$WORKSPACE_ROOT/Makefile" ]; then
		workspace_root="$WORKSPACE_ROOT"
	elif command -v git >/dev/null 2>&1 && git rev-parse --show-toplevel >/dev/null 2>&1; then
		workspace_root=$(git rev-parse --show-toplevel)
	elif [ -f "Makefile" ]; then
		workspace_root=$(pwd)
	else
		echo "❌ Ошибка: не удалось определить корень workspace" >&2
		return 1
	fi

	# Проверка наличия Dockerfile
	dockerfile_path=""
	if [ -f "$workspace_root/$SH_TOOLS_DOCKERFILE" ]; then
		dockerfile_path="$workspace_root/$SH_TOOLS_DOCKERFILE"
	elif [ -f "$SH_TOOLS_DOCKERFILE" ]; then
		dockerfile_path="$SH_TOOLS_DOCKERFILE"
	else
		echo "❌ Ошибка: не найден $SH_TOOLS_DOCKERFILE" >&2
		return 1
	fi

	# Проверка и сборка образа если нужно
	if ! $CONTAINER_RUNTIME images -q "$SH_TOOLS_IMAGE" 2>/dev/null | grep -q .; then
		echo "🔨 Сборка образа $SH_TOOLS_IMAGE..." >&2
		dockerfile_dir=$(dirname "$dockerfile_path")
		if ! $CONTAINER_RUNTIME build \
			-t "$SH_TOOLS_IMAGE" \
			-f "$dockerfile_path" \
			"$dockerfile_dir" >/dev/null 2>&1; then
			echo "❌ Ошибка сборки образа $SH_TOOLS_IMAGE" >&2
			return 1
		fi
		echo "✅ Образ собран успешно" >&2
	fi

	# Запуск инструмента в контейнере
	# Формируем команду как строку для sh -c
	cmd="$tool_name"
	for arg in "$@"; do
		# Экранируем одинарные кавычки в аргументах
		escaped_arg=$(printf '%s' "$arg" | sed "s/'/'\\\\''/g")
		cmd="$cmd '$escaped_arg'"
	done

	$CONTAINER_RUNTIME run --rm \
		-v "$workspace_root:/workspace" \
		-w /workspace \
		"$SH_TOOLS_IMAGE" \
		"$cmd"

	return $?
}

# ===================================
# Функция запуска jq
# ===================================
# Запускает jq для парсинга JSON
# Параметры: все параметры передаются в jq
# Использование: run_jq '.' file.json
run_jq() {
	_run_sh_tool jq "$@"
}

# ===================================
# Функция запуска yq
# ===================================
# Запускает yq для парсинга YAML
# Параметры: все параметры передаются в yq
# Использование: run_yq '.key' file.yaml
run_yq() {
	_run_sh_tool yq "$@"
}
