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
# Возвращает: список технологий (nodejs php python rust makefile gitlab github gitea)
detect_module_tech() {
	module_path="$1"
	techs=""

	[ -f "$module_path/package.json" ] && techs="$techs nodejs"
	[ -f "$module_path/composer.json" ] && techs="$techs php"
	[ -f "$module_path/pyproject.toml" ] || [ -f "$module_path/requirements.txt" ] || [ -f "$module_path/setup.py" ] && techs="$techs python"
	[ -f "$module_path/Cargo.toml" ] && techs="$techs rust"
	[ -f "$module_path/Makefile" ] && techs="$techs makefile"
	[ -f "$module_path/.gitlab-ci.yml" ] && techs="$techs gitlab"
	[ -d "$module_path/.github/workflows" ] && techs="$techs github"
	[ -d "$module_path/.gitea/workflows" ] && techs="$techs gitea"

	echo "$techs" | sed 's/^ //'
}

# ===================================
# Функции определения пакетных менеджеров
# ===================================

# Определить Node.js пакетный менеджер по lock файлам
# Параметр: $1 - путь к модулю
# Приоритет: bun.lockb > pnpm-lock.yaml > yarn.lock > package-lock.json > bun (default)
detect_nodejs_manager() {
	module_path="$1"

	[ -f "$module_path/bun.lockb" ] && echo "bun" && return
	[ -f "$module_path/pnpm-lock.yaml" ] && echo "pnpm" && return
	[ -f "$module_path/yarn.lock" ] && echo "yarn" && return
	[ -f "$module_path/package-lock.json" ] && echo "npm" && return

	echo "bun"  # default
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
