#!/bin/sh
# ===================================
# Modules Detection - Определение технологий модулей
# ===================================
# Функции детектирования технологий и пакетных менеджеров
# Использование: . lib/modules-detect.sh

# ===================================
# Функции определения технологий
# ===================================

# Определить технологии в модуле по наличию маркерных файлов
# Параметр: $1 - путь к модулю
# Возвращает: список технологий (nodejs php python rust makefile)
# Примечание: CI/CD системы определяются отдельно через detect_module_cicd
detect_module_tech() {
	module_path="$1"
	techs=""

	[ -f "$module_path/package.json" ] && techs="$techs nodejs"
	[ -f "$module_path/composer.json" ] && techs="$techs php"
	[ -f "$module_path/pyproject.toml" ] || [ -f "$module_path/requirements.txt" ] || [ -f "$module_path/setup.py" ] && techs="$techs python"
	[ -f "$module_path/Cargo.toml" ] && techs="$techs rust"
	[ -f "$module_path/Makefile" ] && techs="$techs makefile"

	echo "$techs" | sed 's/^ //'
}

# Определить технологические стеки модуля (без CI/CD)
# Параметр: $1 - путь к модулю
# Возвращает: список стеков (nodejs php python rust)
detect_module_stack() {
	module_path="$1"
	stacks=""

	[ -f "$module_path/package.json" ] && stacks="$stacks nodejs"
	[ -f "$module_path/composer.json" ] && stacks="$stacks php"
	[ -f "$module_path/pyproject.toml" ] || [ -f "$module_path/requirements.txt" ] || [ -f "$module_path/setup.py" ] && stacks="$stacks python"
	[ -f "$module_path/Cargo.toml" ] && stacks="$stacks rust"

	echo "$stacks" | sed 's/^ //'
}

# Определить CI/CD системы модуля
# Параметр: $1 - путь к модулю
# Возвращает: список CI/CD (gitlab github gitea)
detect_module_cicd() {
	module_path="$1"
	cicd=""

	[ -f "$module_path/.gitlab-ci.yml" ] && cicd="$cicd gitlab"
	[ -d "$module_path/.github/workflows" ] && cicd="$cicd github"
	[ -d "$module_path/.gitea/workflows" ] && cicd="$cicd gitea"

	echo "$cicd" | sed 's/^ //'
}

# ===================================
# Функции определения пакетных менеджеров
# ===================================

# Определить Node.js пакетный менеджер по lock файлам
# Параметр: $1 - путь к модулю
# Логика: выбирается менеджер с самым свежим lock-файлом (по mtime)
# Поддерживаемые: bun (bun.lockb/bun.lock), pnpm, yarn, npm
# Default: bun
detect_nodejs_manager() {
	module_path="$1"

	# Выбираем пакетный менеджер по самому свежему lock-файлу
	# Список: файл:менеджер
	newest_time=0
	detected_manager=""

	# Проверяем bun.lockb
	if [ -f "$module_path/bun.lockb" ]; then
		mtime=$(stat -c %Y "$module_path/bun.lockb" 2>/dev/null || stat -f %m "$module_path/bun.lockb" 2>/dev/null || echo 0)
		if [ "$mtime" -gt "$newest_time" ]; then
			newest_time=$mtime
			detected_manager="bun"
		fi
	fi

	# Проверяем bun.lock
	if [ -f "$module_path/bun.lock" ]; then
		mtime=$(stat -c %Y "$module_path/bun.lock" 2>/dev/null || stat -f %m "$module_path/bun.lock" 2>/dev/null || echo 0)
		if [ "$mtime" -gt "$newest_time" ]; then
			newest_time=$mtime
			detected_manager="bun"
		fi
	fi

	# Проверяем pnpm-lock.yaml
	if [ -f "$module_path/pnpm-lock.yaml" ]; then
		mtime=$(stat -c %Y "$module_path/pnpm-lock.yaml" 2>/dev/null || stat -f %m "$module_path/pnpm-lock.yaml" 2>/dev/null || echo 0)
		if [ "$mtime" -gt "$newest_time" ]; then
			newest_time=$mtime
			detected_manager="pnpm"
		fi
	fi

	# Проверяем yarn.lock
	if [ -f "$module_path/yarn.lock" ]; then
		mtime=$(stat -c %Y "$module_path/yarn.lock" 2>/dev/null || stat -f %m "$module_path/yarn.lock" 2>/dev/null || echo 0)
		if [ "$mtime" -gt "$newest_time" ]; then
			newest_time=$mtime
			detected_manager="yarn"
		fi
	fi

	# Проверяем package-lock.json
	if [ -f "$module_path/package-lock.json" ]; then
		mtime=$(stat -c %Y "$module_path/package-lock.json" 2>/dev/null || stat -f %m "$module_path/package-lock.json" 2>/dev/null || echo 0)
		if [ "$mtime" -gt "$newest_time" ]; then
			newest_time=$mtime
			detected_manager="npm"
		fi
	fi

	# Возвращаем найденный менеджер или default
	if [ -n "$detected_manager" ]; then
		echo "$detected_manager"
	else
		echo "bun"
	fi
}

# Определить Python пакетный менеджер по lock файлам
# Параметр: $1 - путь к модулю
# Приоритет: uv.lock > poetry.lock > Pipfile > requirements.txt > uv (default)
detect_python_manager() {
	module_path="$1"

	[ -f "$module_path/uv.lock" ] && echo "uv" && return
	[ -f "$module_path/poetry.lock" ] && echo "poetry" && return
	[ -f "$module_path/Pipfile" ] && echo "pipenv" && return
	[ -f "$module_path/requirements.txt" ] && echo "pip" && return

	echo "uv"  # default
}

# PHP всегда использует composer
detect_php_manager() {
	echo "composer"
}

# Rust всегда использует cargo
detect_rust_manager() {
	echo "cargo"
}

# ===================================
# Функции получения имен lock-файлов
# ===================================

# Получить имя lock-файла для Node.js пакетного менеджера
# Параметр: $1 - имя пакетного менеджера (bun, pnpm, yarn, npm)
# Возвращает: имя lock-файла
get_nodejs_lock_name() {
	case "$1" in
		bun) echo "bun.lock" ;;
		pnpm) echo "pnpm-lock.yaml" ;;
		yarn) echo "yarn.lock" ;;
		npm) echo "package-lock.json" ;;
		*) echo "lock file" ;;
	esac
}

# Получить имя lock-файла для Python пакетного менеджера
# Параметр: $1 - имя пакетного менеджера (uv, poetry, pipenv, pip)
# Возвращает: имя lock-файла
get_python_lock_name() {
	case "$1" in
		uv) echo "uv.lock" ;;
		poetry) echo "poetry.lock" ;;
		pipenv) echo "Pipfile.lock" ;;
		pip) echo "requirements.txt" ;;
		*) echo "lock file" ;;
	esac
}
