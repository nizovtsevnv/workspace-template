#!/bin/sh
# ===================================
# Generator библиотека для Workspace Template
# ===================================
# Функции для запуска генераторов модулей в специализированных контейнерах
# Использование: . .template/scripts/lib/generator.sh

# Загружаем библиотеки
# Определяем путь к workspace.sh
# Если WORKSPACE_ROOT определён - используем его, иначе через SCRIPT_DIR
if [ -n "$WORKSPACE_ROOT" ] && [ -f "$WORKSPACE_ROOT/.template/scripts/lib/workspace.sh" ]; then
	. "$WORKSPACE_ROOT/.template/scripts/lib/workspace.sh"
elif [ -n "$SCRIPT_DIR" ] && [ -f "$SCRIPT_DIR/lib/workspace.sh" ]; then
	. "$SCRIPT_DIR/lib/workspace.sh"
else
	# Fallback: определяем через dirname текущего файла
	# Работает только при прямом вызове скрипта, не через source
	LIB_DIR="$(cd "$(dirname "$0")" 2>/dev/null && pwd)" || LIB_DIR="."
	. "$LIB_DIR/workspace.sh"
fi

# ===================================
# Функция сборки образа генератора
# ===================================
# Проверяет наличие образа и собирает если нужно
# Параметры: $1 - стек (nodejs, python, rust, c, zig, php)
# Возвращает: 0 если успешно, 1 если ошибка
ensure_generator_image() {
	stack="$1"
	image_name="workspace-stack-$stack"
	dockerfile_path=".template/dockerfiles/$stack.Dockerfile"

	# Получить workspace root
	workspace_root=$(get_workspace_root) || return 1

	# Проверка наличия Dockerfile
	if [ ! -f "$workspace_root/$dockerfile_path" ]; then
		echo "❌ Ошибка: не найден $dockerfile_path" >&2
		return 1
	fi

	# Проверка и сборка образа если нужно
	if ! $CONTAINER_RUNTIME images -q "$image_name" 2>/dev/null | grep -q .; then
		echo "🔨 Сборка образа $image_name..." >&2
		dockerfile_dir=$(dirname "$workspace_root/$dockerfile_path")
		if ! $CONTAINER_RUNTIME build \
			-t "$image_name" \
			-f "$workspace_root/$dockerfile_path" \
			"$dockerfile_dir" >/dev/null 2>&1; then
			echo "❌ Ошибка сборки образа $image_name" >&2
			return 1
		fi
		echo "✅ Образ $image_name собран успешно" >&2
	fi

	return 0
}

# ===================================
# Функция запуска генератора
# ===================================
# Запускает генератор модуля в специализированном контейнере
# Параметры: $1 - стек (nodejs, python, rust, c, zig, php), остальные - параметры генератора
# Возвращает: код завершения генератора
# Использование: run_generator nodejs npm my-module /workspace/modules
run_generator() {
	stack="$1"
	shift

	# Проверка наличия container runtime
	if ! command -v "$CONTAINER_RUNTIME" >/dev/null 2>&1; then
		echo "❌ Ошибка: $CONTAINER_RUNTIME недоступен" >&2
		return 1
	fi

	# Получить workspace root
	workspace_root=$(get_workspace_root) || return 1

	# Убедиться что образ существует
	ensure_generator_image "$stack" || return 1

	# Путь к генератору
	generator_script="/workspace/.template/scripts/module/generators/$stack.sh"

	# Определяем целевую директорию (четвертый параметр генератора)
	# Нужно смонтировать её отдельно если она находится вне workspace
	module_target=""
	if [ $# -ge 3 ]; then
		# Третий параметр это MODULE_TARGET
		eval "module_target=\${$#}"  # Получаем последний аргумент
	fi

	# Определяем дополнительные монтирования
	extra_mounts=""
	if [ -n "$module_target" ]; then
		# Преобразуем в абсолютный путь
		module_target_abs=$(cd "$(dirname "$module_target")" 2>/dev/null && pwd)/$(basename "$module_target") || module_target_abs="$module_target"

		# Если целевая директория вне workspace - монтируем её отдельно
		case "$module_target_abs" in
			"$workspace_root"*) ;;  # Внутри workspace, дополнительное монтирование не нужно
			*)
				# Вне workspace, монтируем отдельно
				mkdir -p "$module_target_abs" 2>/dev/null || true
				extra_mounts="-v $module_target_abs:$module_target_abs"
				;;
		esac
	fi

	# Запуск генератора в контейнере
	# --rm: автоматическое удаление контейнера после выполнения
	# -v: монтирование workspace и опционально целевой директории
	# -w: рабочая директория
	# -e: передача переменных окружения
	# shellcheck disable=SC2086
	$CONTAINER_RUNTIME run --rm \
		--user "$(id -u):$(id -g)" \
		-v "$workspace_root:/workspace" \
		$extra_mounts \
		-w /workspace \
		-e "HOST_UID=$(id -u)" \
		-e "HOST_GID=$(id -g)" \
		"workspace-stack-$stack" \
		"$generator_script" "$@"

	return $?
}

# ===================================
# Функция запуска интерактивного генератора
# ===================================
# Запускает генератор в интерактивном режиме (для create-next-app, create-expo-app и т.д.)
# Параметры: $1 - стек, остальные - параметры генератора
# Возвращает: код завершения генератора
# Использование: run_generator_interactive nodejs nextjs my-app /workspace/modules
run_generator_interactive() {
	stack="$1"
	shift

	# Проверка наличия container runtime
	if ! command -v "$CONTAINER_RUNTIME" >/dev/null 2>&1; then
		echo "❌ Ошибка: $CONTAINER_RUNTIME недоступен" >&2
		return 1
	fi

	# Получить workspace root
	workspace_root=$(get_workspace_root) || return 1

	# Убедиться что образ существует
	ensure_generator_image "$stack" || return 1

	# Путь к генератору
	generator_script="/workspace/.template/scripts/module/generators/$stack.sh"

	# Определяем целевую директорию (четвертый параметр генератора)
	module_target=""
	if [ $# -ge 3 ]; then
		eval "module_target=\${$#}"
	fi

	# Определяем дополнительные монтирования
	extra_mounts=""
	if [ -n "$module_target" ]; then
		module_target_abs=$(cd "$(dirname "$module_target")" 2>/dev/null && pwd)/$(basename "$module_target") || module_target_abs="$module_target"

		case "$module_target_abs" in
			"$workspace_root"*) ;;
			*)
				mkdir -p "$module_target_abs" 2>/dev/null || true
				extra_mounts="-v $module_target_abs:$module_target_abs"
				;;
		esac
	fi

	# Запуск генератора в интерактивном режиме
	# -it: интерактивный режим с TTY
	# --rm: автоматическое удаление контейнера после выполнения
	# -v: монтирование workspace и опционально целевой директории
	# -w: рабочая директория
	# -e: передача переменных окружения
	# shellcheck disable=SC2086
	$CONTAINER_RUNTIME run -it --rm \
		--user "$(id -u):$(id -g)" \
		-v "$workspace_root:/workspace" \
		$extra_mounts \
		-w /workspace \
		-e "HOST_UID=$(id -u)" \
		-e "HOST_GID=$(id -g)" \
		"workspace-stack-$stack" \
		"$generator_script" "$@"

	return $?
}
