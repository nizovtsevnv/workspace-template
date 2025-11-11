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
# Функция сборки образа стека
# ===================================
# Проверяет наличие образа и собирает если нужно
# Параметры: $1 - имя стека (nodejs, python, rust, c, zig, php)
# Возвращает: 0 если успешно, 1 если ошибка
_ensure_stack_image() {
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

	# Извлекаем первое слово команды для проверки
	# Это реальная команда которая будет выполняться (npm, bun, composer, etc.)
	actual_command=$(echo "$cmd" | awk '{print $1}')

	# Проверяем наличие реальной команды на хосте
	if command -v "$actual_command" >/dev/null 2>&1; then
		(cd "$workdir" && eval "$cmd")
		return $?
	fi

	# Fallback: запуск через Alpine контейнер
	workspace_root=$(get_workspace_root)
	workdir_abs=$(cd "$workdir" 2>/dev/null && pwd || echo "$workdir")

	# Убедиться что образ существует (автосборка)
	_ensure_stack_image "$stack_name" || return 1

	# Определяем нужны ли дополнительные монтирования
	extra_mounts=""
	case "$workdir_abs" in
		"$workspace_root"*) ;;  # Внутри workspace
		*)
			# Вне workspace - монтируем отдельно
			extra_mounts="-v $workdir_abs:$workdir_abs"
			;;
	esac

	# Выполняем команду в контейнере
	# shellcheck disable=SC2086,SC2046
	$CONTAINER_RUNTIME run --rm \
		-v "$workspace_root:/workspace" \
		$extra_mounts \
		-w "$workdir_abs" \
		-e "HOST_UID=$(id -u)" \
		-e "HOST_GID=$(id -g)" \
		"$container_image" \
		sh -c "$cmd"
}

# ===================================
# Публичные функции для каждого стека
# ===================================
# Тонкие обертки над _run_stack_generic для удобства использования

# Node.js stack
# Использование: run_nodejs "." "npm install"
run_nodejs() {
	_run_stack_generic "nodejs" "node" "workspace-stack-nodejs" "$@"
}

# PHP stack
# Использование: run_php "." "composer install"
run_php() {
	_run_stack_generic "php" "php" "workspace-stack-php" "$@"
}

# Python stack
# Использование: run_python "." "pip install -r requirements.txt"
run_python() {
	_run_stack_generic "python" "python3" "workspace-stack-python" "$@"
}

# Rust stack
# Использование: run_rust "." "cargo build"
run_rust() {
	_run_stack_generic "rust" "cargo" "workspace-stack-rust" "$@"
}

# C stack
# Использование: run_c "." "make"
run_c() {
	_run_stack_generic "c" "gcc" "workspace-stack-c" "$@"
}

# Zig stack
# Использование: run_zig "." "zig build"
run_zig() {
	_run_stack_generic "zig" "zig" "workspace-stack-zig" "$@"
}

# ===================================
# Функция проверки версий инструментов
# ===================================
# Показывает информацию о доступных версиях инструментов (хост и контейнер)
# Параметры: нет
# Использование: check_stack_versions
check_stack_versions() {
	printf "\n${COLOR_SECTION}▶ Версии инструментов технологических стеков${COLOR_RESET}\n\n"

	# Определяем стеки для проверки
	stacks="nodejs:node php:php python:python3 rust:cargo c:gcc zig:zig"

	for stack_info in $stacks; do
		stack="${stack_info%%:*}"
		command="${stack_info##*:}"

		printf "${COLOR_DIM}%-12s${COLOR_RESET} " "$stack"

		# Проверяем хост
		if command -v "$command" >/dev/null 2>&1; then
			version=$("$command" --version 2>&1 | head -n1 | cut -c1-60)
			printf "${COLOR_SUCCESS}✓ хост:${COLOR_RESET} %s\n" "$version"
		else
			printf "${COLOR_WARNING}- хост: не установлен${COLOR_RESET}\n"
		fi

		# Проверяем контейнер
		image_name="workspace-stack-$stack"
		printf "%-12s " ""
		if $CONTAINER_RUNTIME images -q "$image_name" 2>/dev/null | grep -q .; then
			printf "${COLOR_SUCCESS}✓ контейнер: $image_name${COLOR_RESET}\n"
		else
			printf "${COLOR_DIM}- контейнер: образ не собран${COLOR_RESET}\n"
		fi
	done

	printf "\n"
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
