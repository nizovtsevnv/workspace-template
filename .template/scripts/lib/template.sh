#!/bin/sh
# ===================================
# Template библиотека для Workspace Template
# ===================================
# Функции управления шаблоном и инициализацией
# Использование: . lib/template.sh
# shellcheck disable=SC1091

# ===================================
# Константы: Стратегия разрешения конфликтов слияния с шаблоном
# ===================================
# При слиянии с шаблоном используется стратегия:
# - THEIRS (из шаблона): всё, что относится к инфраструктуре разработки
# - OURS (оставляем своё): проектные файлы (документация, CI/CD, конфигурация git)
#
# Приоритет проверки (сверху вниз):
# 1. MERGE_STRATEGY_THEIRS_PRIORITY - файлы из шаблона с высоким приоритетом (doc/development/template/*)
# 2. MERGE_STRATEGY_OURS - проектные файлы, которые всегда остаются своими
# 3. * (по умолчанию) - всё остальное из шаблона

# Файлы шаблона с высоким приоритетом (берём из шаблона, игнорируя локальные изменения)
readonly MERGE_STRATEGY_THEIRS_PRIORITY="doc/development/template/*"

# Проектные файлы (всегда оставляем свои, игнорируя изменения шаблона)
readonly MERGE_STRATEGY_OURS=".github/* .editorconfig .gitignore .gitmodules README.md doc/*"

# ===================================
# Функции
# ===================================

# Определить статус инициализации проекта
# Возвращает: переменную STATUS="инициализирован" или STATUS="не инициализирован"
# Использование:
#   check_project_init_status
#   if [ "$STATUS" = "инициализирован" ]; then ...
check_project_init_status() {
	# Проект считается инициализированным, если существует файл .template-commit
	if [ -f ".template-commit" ]; then
		STATUS="инициализирован"
	else
		STATUS="не инициализирован"
	fi
}

# Удалить артефакты шаблона (.github/)
# Использование: remove_template_artifacts
remove_template_artifacts() {
	# Загружаем UI библиотеку для вывода (если еще не загружена)
	# SCRIPT_DIR должен быть определён через init.sh перед загрузкой библиотек
	. "${SCRIPT_DIR:?SCRIPT_DIR не определён}/lib/loader.sh"
	load_lib "ui" "log_success"

	if [ -d ".github" ]; then
		git rm -rf .github 2>/dev/null || rm -rf .github
		log_success "Удалена директория .github/"
	fi
}

# Проверить, соответствует ли файл одному из паттернов
# Использование: _matches_patterns "$file" "$patterns"
_matches_patterns() {
	file="$1"
	patterns="$2"

	# shellcheck disable=SC2254
	for pattern in $patterns; do
		case "$file" in
			$pattern) return 0 ;;
		esac
	done
	return 1
}

# Автоматически разрешить конфликты слияния шаблона
# Принцип: upstream версии для ВСЕХ файлов, кроме проектных
#         По умолчанию всё из шаблона, исключения явно перечислены в константах
# Использование: auto_resolve_template_conflicts
auto_resolve_template_conflicts() {
	# Загружаем UI библиотеку для вывода (если еще не загружена)
	# SCRIPT_DIR должен быть определён через init.sh перед загрузкой библиотек
	. "${SCRIPT_DIR:?SCRIPT_DIR не определён}/lib/loader.sh"
	load_lib "ui" "log_success"

	conflicts=$(git diff --name-only --diff-filter=U 2>/dev/null)

	if [ -n "$conflicts" ]; then
		echo "$conflicts" | while read -r conflict_file; do
			# Проверяем приоритеты (сверху вниз)
			if _matches_patterns "$conflict_file" "$MERGE_STRATEGY_THEIRS_PRIORITY"; then
				# Документация шаблона - ВСЕГДА из upstream (приоритет перед OURS)
				git checkout --theirs "$conflict_file" >/dev/null 2>&1
				git add "$conflict_file" >/dev/null 2>&1
			elif _matches_patterns "$conflict_file" "$MERGE_STRATEGY_OURS"; then
				# Проектные файлы - ВСЕГДА оставляем свои
				git checkout --ours "$conflict_file" >/dev/null 2>&1
				git add "$conflict_file" >/dev/null 2>&1
			else
				# ВСЁ ОСТАЛЬНОЕ - из шаблона
				git checkout --theirs "$conflict_file" >/dev/null 2>&1
				git add "$conflict_file" >/dev/null 2>&1
			fi
		done

		remaining=$(git diff --name-only --diff-filter=U 2>/dev/null | wc -l)

		if [ "$remaining" -eq 0 ]; then
			log_success "Конфликты разрешены автоматически"
		else
			log_warning "Осталось конфликтов для ручного разрешения: $remaining"
		fi
	fi
}

# Создать README.md проекта автоматически
# Использование: create_project_readme
create_project_readme() {
	# Загружаем UI библиотеку для вывода (если еще не загружена)
	if ! command -v log_success >/dev/null 2>&1; then
		SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
		. "$SCRIPT_DIR/ui.sh"
	fi

	if [ -f ".template/assets/README.md" ]; then
		cp .template/assets/README.md README.md
		log_success "README.md создан из шаблона"
	else
		cat > README.md <<'EOF'
# My Project

Проект создан из [Workspace Template](https://github.com/nizovtsevnv/devcontainer-workspace)
EOF
		log_success "README.md создан"
	fi
}
