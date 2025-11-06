#!/bin/sh
# ===================================
# Stack Runner - Выполнение команд технологических стеков
# ===================================
# Функции запуска инструментов с fallback в Alpine контейнеры
# Использование: run_nodejs "npm install"

# Загружаем библиотеки
# Определяем путь к workspace.sh
# Если WORKSPACE_ROOT определён - используем его, иначе через SCRIPT_DIR
if [ -n "$WORKSPACE_ROOT" ] && [ -f "$WORKSPACE_ROOT/.template/scripts/lib/workspace.sh" ]; then
	. "$WORKSPACE_ROOT/.template/scripts/lib/workspace.sh"
elif [ -n "$SCRIPT_DIR" ] && [ -f "$SCRIPT_DIR/lib/workspace.sh" ]; then
	. "$SCRIPT_DIR/lib/workspace.sh"
else
	# Fallback: определяем через dirname текущего файла
	LIB_DIR="$(cd "$(dirname "$0")" 2>/dev/null && pwd)" || LIB_DIR="."
	. "$LIB_DIR/workspace.sh"
fi

# Определяем container runtime из окружения или используем podman по умолчанию
# CONTAINER_RUNTIME должен быть определён через init.sh
CONTAINER_RUNTIME="${CONTAINER_RUNTIME:-podman}"
readonly CONTAINER_RUNTIME

# ===================================
# Универсальная функция выполнения
# ===================================
# Проверяет наличие инструмента на хосте, иначе запускает в контейнере
# Параметры:
#   $1 - имя стека (для логирования)
#   $2 - команда для проверки на хосте
#   $3 - имя контейнера для fallback
#   $4 - рабочая директория
#   $5+ - команда для выполнения
# Возвращает: exit code команды
_run_stack_generic() {
	# shellcheck disable=SC2034  # stack_name зарезервирован для будущего использования в диагностике
	stack_name="$1"
	host_command="$2"
	container_image="$3"
	workdir="${4:-.}"
	shift 4
	cmd="$*"

	# Проверяем наличие инструмента на хосте
	if command -v "$host_command" >/dev/null 2>&1; then
		(cd "$workdir" && eval "$cmd")
		return $?
	fi

	# Fallback: запуск через Alpine контейнер
	workspace_root=$(get_workspace_root)
	workdir_abs=$(cd "$workdir" 2>/dev/null && pwd || echo "$workdir")

	# Определяем нужны ли дополнительные монтирования
	extra_mounts=""
	case "$workdir_abs" in
		"$workspace_root"*) ;;  # Внутри workspace
		*)
			# Вне workspace - монтируем отдельно
			extra_mounts="-v $workdir_abs:$workdir_abs"
			;;
	esac

	$CONTAINER_RUNTIME run --rm \
		-v "$workspace_root:/workspace" \
		$extra_mounts \
		-w "$workdir_abs" \
		-e "HOST_UID=$(id -u)" \
		-e "HOST_GID=$(id -g)" \
		"$container_image" \
		/bin/sh -c "$cmd"
}

# ===================================
# Публичные функции для каждого стека
# ===================================
# Тонкие обертки над _run_stack_generic для удобства использования

# Node.js stack
# Использование: run_nodejs "." "npm install"
run_nodejs() {
	_run_stack_generic "nodejs" "node" "devcontainer-nodejs" "$@"
}

# PHP stack
# Использование: run_php "." "composer install"
run_php() {
	_run_stack_generic "php" "php" "devcontainer-php" "$@"
}

# Python stack
# Использование: run_python "." "pip install -r requirements.txt"
run_python() {
	_run_stack_generic "python" "python3" "devcontainer-python" "$@"
}

# Rust stack
# Использование: run_rust "." "cargo build"
run_rust() {
	_run_stack_generic "rust" "cargo" "devcontainer-rust" "$@"
}

# C stack
# Использование: run_c "." "make"
run_c() {
	_run_stack_generic "c" "gcc" "devcontainer-c" "$@"
}

# Zig stack
# Использование: run_zig "." "zig build"
run_zig() {
	_run_stack_generic "zig" "zig" "devcontainer-zig" "$@"
}

# ===================================
# Универсальная функция-маршрутизатор
# ===================================
# Автоопределение стека по технологии модуля
# Параметры:
#   $1 - технология (nodejs, php, python, rust, c, zig)
#   $2 - рабочая директория
#   $3+ - команда для выполнения
# Использование: run_stack_command "nodejs" "." "npm install"
run_stack_command() {
	tech="$1"
	workdir="$2"
	shift 2
	cmd="$*"

	case "$tech" in
		nodejs) run_nodejs "$workdir" "$cmd" ;;
		php) run_php "$workdir" "$cmd" ;;
		python) run_python "$workdir" "$cmd" ;;
		rust) run_rust "$workdir" "$cmd" ;;
		c) run_c "$workdir" "$cmd" ;;
		zig) run_zig "$workdir" "$cmd" ;;
		*)
			# Fallback: выполнение на хосте
			(cd "$workdir" && eval "$cmd")
			;;
	esac
}
