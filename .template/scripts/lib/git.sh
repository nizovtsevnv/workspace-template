#!/bin/sh
# ===================================
# Git библиотека для Workspace Template
# ===================================
# Функции работы с коммитами и git
# Использование: . lib/git.sh
# shellcheck disable=SC1091

# Определить commit hash шаблона (короткий, 7 символов)
# В неинициализированном шаблоне: из git HEAD
# В инициализированном проекте: из .template-commit
# Использование: commit=$(get_template_commit)
get_template_commit() {
	if [ -f .template-commit ]; then
		commit=$(cat .template-commit 2>/dev/null)
		if [ -n "$commit" ]; then
			echo "$commit"
		else
			echo "unknown"
		fi
	else
		git rev-parse --short=7 HEAD 2>/dev/null || echo "unknown"
	fi
}

# Получить дату коммита в формате YYYY-MM-DD
# Параметр: $1 - commit hash или ref (HEAD, template/main, etc.)
# Использование: date=$(get_template_commit_date "abc1234")
get_template_commit_date() {
	commit_ref="${1:-HEAD}"
	git log -1 --format=%ci "$commit_ref" 2>/dev/null | cut -d' ' -f1 || echo "unknown"
}

# Сохранить commit hash шаблона в .template-commit и добавить в git
# Параметр: $1 - commit hash (короткий, 7 символов)
# Использование: save_template_commit "abc1234"
save_template_commit() {
	echo "$1" > .template-commit
	git add .template-commit 2>/dev/null || true
}

# Показать changelog между двумя refs (коммитами, ветками, тегами)
# Параметры: $1 - from ref, $2 - to ref
# Использование: show_changelog "abc1234" "template/main"
show_changelog() {
	from_ref="$1"
	to_ref="$2"
	git log --oneline --decorate "$from_ref..$to_ref" 2>/dev/null || \
		log_info "(changelog недоступен)"
}

# Проверить наличие незакоммиченных изменений в файлах шаблона
# Возвращает: 0 если нет изменений в файлах шаблона, 1 если есть
# Использование: if ! require_clean_working_tree; then ...
require_clean_working_tree() {
	# Файлы и директории, управляемые шаблоном
	# При обновлении шаблона изменяются только эти файлы
	template_files=".template/ Makefile .editorconfig .gitignore doc/development/"

	# Проверяем изменения только в файлах шаблона
	if ! git diff-index --quiet HEAD -- $template_files 2>/dev/null; then
		# Загружаем UI библиотеку для вывода (если еще не загружена)
		# SCRIPT_DIR должен быть определён через init.sh перед загрузкой библиотек
		. "${SCRIPT_DIR:?SCRIPT_DIR не определён}/lib/loader.sh"
		load_lib "ui" "log_error"
		log_error "Есть незакоммиченные изменения в файлах шаблона!"
		log_info "Закоммитьте или stash их перед обновлением"
		printf "\n"
		log_info "Изменённые файлы шаблона:"
		git status --short -- $template_files
		return 1
	fi

	# Проверяем другие изменения (информационно, не блокируем)
	# Игнорируем изменения в modules/ (ссылки на субмодули)
	other_changes=$(git status --porcelain 2>/dev/null | grep -v -E "^.. (\.template/|Makefile|\.editorconfig|\.gitignore|doc/development/|modules/)" || true)

	if [ -n "$other_changes" ]; then
		# Загружаем UI библиотеку для вывода (если еще не загружена)
		. "${SCRIPT_DIR:?SCRIPT_DIR не определён}/lib/loader.sh"
		load_lib "ui" "log_info"
		printf "\n"
		log_info "В проекте есть другие незакоммиченные изменения (не мешают обновлению):"
		echo "$other_changes"
		printf "\n"
	fi

	return 0
}

# Подсчитать количество коммитов в репозитории
# Параметр: $1 - путь к git репозиторию (опционально, по умолчанию текущий)
# Возвращает: число коммитов
# Использование: count=$(count_commits "/path/to/repo")
count_commits() {
	if [ -n "$1" ]; then
		git -C "$1" rev-list --count HEAD 2>/dev/null || echo "0"
	else
		git rev-list --count HEAD 2>/dev/null || echo "0"
	fi
}

