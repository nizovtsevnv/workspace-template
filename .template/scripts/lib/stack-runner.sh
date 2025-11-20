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

# Загружаем UI библиотеку для is_tty и логирования
if [ -n "$WORKSPACE_ROOT" ] && [ -f "$WORKSPACE_ROOT/.template/scripts/lib/ui.sh" ]; then
	. "$WORKSPACE_ROOT/.template/scripts/lib/ui.sh"
elif [ -n "$SCRIPT_DIR" ] && [ -f "$SCRIPT_DIR/lib/ui.sh" ]; then
	. "$SCRIPT_DIR/lib/ui.sh"
elif [ -n "$LIB_DIR" ] && [ -f "$LIB_DIR/ui.sh" ]; then
	. "$LIB_DIR/ui.sh"
fi

# CONTAINER_RUNTIME должен быть определён через init.sh
# Не устанавливаем значение по умолчанию здесь, чтобы не блокировать автоопределение в init.sh

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

	# Определяем команду для проверки на хосте
	check_command=""
	if [ "$stack_name" = "nodejs" ] && [ -n "$NODEJS_PM" ]; then
		# Для nodejs проверяем пакетный менеджер (bun, npm, yarn, pnpm)
		check_command="$NODEJS_PM"
	else
		# Для других стеков - первое слово команды
		check_command=$(echo "$cmd" | awk '{print $1}')
	fi

	# Пытаемся выполнить на хосте
	if [ -n "$check_command" ] && command -v "$check_command" >/dev/null 2>&1; then
		# Выполняем на хосте без subshell для правильного TTY
		cd "$workdir" || return 1
		eval "$cmd"
		exit_code=$?
		cd "$WORKSPACE_ROOT" || true
		return $exit_code
	fi

	# Fallback: запуск через Alpine контейнер
	workspace_root=$(get_workspace_root)
	workdir_abs=$(cd "$workdir" 2>/dev/null && pwd || echo "$workdir")

	# Убедиться что образ существует (автосборка)
	_ensure_stack_image "$stack_name" || return 1

	# Определяем путь внутри контейнера и дополнительные монтирования
	container_workdir=""
	extra_mounts=""
	case "$workdir_abs" in
		"$workspace_root"*)
			# Внутри workspace - преобразуем в путь контейнера
			container_workdir="/workspace${workdir_abs#$workspace_root}"
			;;
		*)
			# Вне workspace - монтируем отдельно и используем host путь
			extra_mounts="-v $workdir_abs:$workdir_abs"
			container_workdir="$workdir_abs"
			;;
	esac

	# Определяем нужны ли TTY флаги для интерактивных команд
	tty_flags=""
	if is_tty && _is_interactive_command "$cmd"; then
		tty_flags="-it"
	fi

	# Выполняем команду в контейнере
	# shellcheck disable=SC2086,SC2046
	$CONTAINER_RUNTIME run --rm $tty_flags \
		--network host \
		--user "$(id -u):$(id -g)" \
		-v "$workspace_root:/workspace" \
		$extra_mounts \
		-w "$container_workdir" \
		-e "HOST_UID=$(id -u)" \
		-e "HOST_GID=$(id -g)" \
		-e "HOME=/tmp" \
		-e "npm_config_cache=/tmp/.npm" \
		-e "YARN_CACHE_FOLDER=/tmp/.yarn-cache" \
		-e "BUN_INSTALL_CACHE_DIR=/tmp/.bun-cache" \
		"$container_image" \
		sh -c "$cmd"
}

# Проверить требуется ли TTY для команды
# Параметры: $1 - команда
# Возвращает: 0 если интерактивная, 1 если нет
_is_interactive_command() {
	cmd="$1"

	# Паттерны интерактивных команд (dev серверы, watch режимы, REPL)
	case "$cmd" in
		*" start"*|*" dev"*|*" serve"*|*" watch"*) return 0 ;;
		*"expo start"*|*"vite"*|*"webpack-dev-server"*) return 0 ;;
		*" repl"*|*" console"*|*" shell"*) return 0 ;;
		*) return 1 ;;
	esac
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
# Функция интерактивного shell
# ===================================

# Запустить интерактивный shell в контейнере стека
# Параметры:
#   $1 - стек (nodejs, php, python, rust, c, zig)
#   $2 - рабочая директория (абсолютный путь)
# Использование: run_interactive_shell "nodejs" "/path/to/module"
run_interactive_shell() {
	stack="$1"
	workdir_abs="$2"

	# Проверка TTY
	if ! is_tty; then
		log_error "Интерактивный shell требует TTY"
		log_info "Используйте: make <module> sh < /dev/tty"
		return 1
	fi

	# Определяем образ контейнера
	container_image="workspace-stack-$stack"

	# Получаем workspace root
	workspace_root=$(get_workspace_root) || return 1

	# Убедиться что образ существует (автосборка)
	_ensure_stack_image "$stack" || return 1

	# Определяем путь внутри контейнера и дополнительные монтирования
	container_workdir=""
	extra_mounts=""
	case "$workdir_abs" in
		"$workspace_root"*)
			# Внутри workspace - преобразуем в путь контейнера
			container_workdir="/workspace${workdir_abs#$workspace_root}"
			;;
		*)
			# Вне workspace - монтируем отдельно
			extra_mounts="-v $workdir_abs:$workdir_abs"
			container_workdir="$workdir_abs"
			;;
	esac

	log_section "Shell в контейнере $container_image"
	log_info "Рабочая директория: $container_workdir"
	printf "\n"

	# Запускаем интерактивный shell с флагами -it
	# shellcheck disable=SC2086
	$CONTAINER_RUNTIME run --rm -it \
		--network host \
		--user "$(id -u):$(id -g)" \
		-v "$workspace_root:/workspace" \
		$extra_mounts \
		-w "$container_workdir" \
		-e "HOST_UID=$(id -u)" \
		-e "HOST_GID=$(id -g)" \
		-e "HOME=/tmp" \
		-e "npm_config_cache=/tmp/.npm" \
		-e "YARN_CACHE_FOLDER=/tmp/.yarn-cache" \
		-e "BUN_INSTALL_CACHE_DIR=/tmp/.bun-cache" \
		"$container_image" \
		sh
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
