#!/bin/sh
# ===================================
# Workspace Template - Обновление шаблона
# ===================================
set -e

# Инициализация общих переменных
. "$(dirname "$0")/../lib/init.sh"

# Загружаем библиотеки
. "$SCRIPT_DIR/lib/ui.sh"
. "$SCRIPT_DIR/lib/git.sh"
. "$SCRIPT_DIR/lib/template.sh"

# ===================================
# Основная логика
# ===================================

log_section "Обновление шаблона"

# Определить статус инициализации
check_project_init_status

if [ "$STATUS" = "инициализирован" ]; then
	# ===========================================
	# Обновление инициализированного проекта
	# ===========================================
	log_success "Режим: инициализированный проект"

	# Автомиграция .template-version → .template-commit (для старых проектов)
	if [ -f .template-version ] && [ ! -f .template-commit ]; then
		log_info "Обнаружен старый формат версии (.template-version)"
		old_version=$(cat .template-version 2>/dev/null)
		# Пробуем найти коммит по версии в истории
		old_commit=$(git log --all --oneline | grep -i "$old_version" | head -1 | awk '{print $1}' 2>/dev/null || echo "")
		if [ -n "$old_commit" ]; then
			save_template_commit "$old_commit"
			log_success "Мигрировано в новый формат: $old_commit"
			git rm -f .template-version 2>/dev/null || rm -f .template-version
		else
			log_warning "Не удалось найти коммит для версии $old_version"
			log_info "Будет использован текущий HEAD template/main"
			# Используем последний коммит template/main как fallback
			latest_commit=$(git rev-parse --short=7 template/main 2>/dev/null || echo "")
			if [ -n "$latest_commit" ]; then
				save_template_commit "$latest_commit"
				git rm -f .template-version 2>/dev/null || rm -f .template-version
			fi
		fi
		printf "\n"
	fi

	# Проверка: есть uncommitted changes
	if ! require_clean_working_tree; then
		exit 1
	fi

	# Fetch обновлений
	show_spinner "Проверка обновлений шаблона" git fetch template --force 2>&1 || true

	# Определить текущий и последний коммиты
	current_commit=$(get_template_commit)
	current_date=$(get_template_commit_date "$current_commit")

	latest_commit=$(git rev-parse --short=7 template/main 2>/dev/null || echo "unknown")
	latest_date=$(get_template_commit_date "template/main")

	printf "Текущая версия:   %s (%s)\n" "$current_date" "$current_commit"
	printf "Последняя версия: %s (%s)\n" "$latest_date" "$latest_commit"
	printf "\n"

	# Проверка: если уже на последнем коммите
	if [ "$current_commit" = "$latest_commit" ]; then
		log_success "У вас самая свежая версия"
		exit 0
	fi

	# Показать изменения (список коммитов между версиями)
	log_info "Изменения между версиями:"
	show_changelog "$current_commit" "template/main"
	printf "\n"

	# Подтверждение обновления
	if ! ask_yes_no "Обновить до последнего коммита?"; then
		log_info "Обновление отменено"
		exit 0
	fi

	# Выполняем merge последнего коммита из template/main
	tmpfile=$(mktemp)
	# shellcheck disable=SC2064
	trap "rm -f $tmpfile" EXIT INT TERM
	if ! git merge --allow-unrelated-histories --no-commit --no-ff template/main > "$tmpfile" 2>&1; then
		# Merge с конфликтами - это нормально, продолжаем
		# Но показываем вывод если это не конфликт, а другая ошибка
		if ! grep -q "Automatic merge failed" "$tmpfile"; then
			cat "$tmpfile" >&2
		fi
	fi
	rm -f "$tmpfile"
	trap - EXIT INT TERM

	# Автоматически разрешаем конфликты
	auto_resolve_template_conflicts

	# Проверяем нерешённые конфликты
	unresolved=$(git diff --name-only --diff-filter=U 2>/dev/null)
	if [ -n "$unresolved" ]; then
		printf "\n"
		log_error "Нерешённые конфликты:"
		echo "$unresolved" | while read -r file; do
			log_warning "$file"
		done
		printf "\n"
		log_info "Разрешите конфликты и выполните:"
		printf "  git add <файлы>\n"
		printf "  git commit\n"
		exit 1
	fi

	# Удаление артефактов шаблона
	remove_template_artifacts

	# Сохраняем новый коммит
	save_template_commit "$latest_commit"

	# Показываем изменения
	printf "\n"
	log_info "Изменения подготовлены к коммиту:"
	git diff --cached --stat --color=always
	printf "\n"

	# Запрос на создание коммита
	if ! ask_yes_no "Создать коммит обновления шаблона?"; then
		printf "\n"
		log_info "Обновление завершено без коммита"
		printf "  Новая версия: %s (%s)\n" "$latest_date" "$latest_commit"
		printf "  Выполните 'git commit' когда будете готовы\n"
		exit 0
	fi

	# Запрос сообщения коммита
	default_msg="chore: update template to $latest_commit ($latest_date)"
	commit_msg=$(ask_input_with_default "$default_msg" "Сообщение коммита:")

	if [ -n "$commit_msg" ]; then
		# Проверка наличия staged changes перед коммитом
		if ! git diff --cached --quiet; then
			tmpfile=$(mktemp)
			# shellcheck disable=SC2064
			trap "rm -f $tmpfile" EXIT INT TERM
			if git commit -m "$commit_msg" > "$tmpfile" 2>&1; then
				commit_hash=$(git rev-parse --short=7 HEAD)
				printf "\n"
				log_success "Обновление завершено!"
				printf "  Новая версия: %s (%s)\n" "$latest_date" "$latest_commit"
				printf "  Коммит создан: %s\n" "$commit_hash"
			else
				printf "\n"
				log_error "Ошибка при создании коммита:"
				cat "$tmpfile" >&2
				printf "\n"
				log_info "Выполните 'git commit' вручную"
			fi
			rm -f "$tmpfile"
			trap - EXIT INT TERM
		else
			printf "\n"
			log_warning "Нет изменений для коммита"
			printf "  Staging area пуст\n"
			printf "  Проверьте, что изменения были корректно добавлены\n"
		fi
	else
		log_warning "Пустое сообщение - коммит пропущен"
		printf "  Выполните 'git commit' когда будете готовы\n"
	fi

else
	# ===========================================
	# Обновление неинициализированного шаблона
	# ===========================================
	log_info "Режим: неинициализированный шаблон"

	# Проверка: есть uncommitted changes
	if ! require_clean_working_tree; then
		exit 1
	fi

	# Определить текущую ветку
	current_branch=$(git branch --show-current)
	log_info "Обновление ветки: $current_branch"

	# Pull изменений
	if git pull 2>&1; then
		log_success "Изменения получены"
	else
		log_error "Не удалось выполнить git pull"
		exit 1
	fi

	# Определить commit hash шаблона
	template_commit=$(git rev-parse --short=7 HEAD 2>/dev/null || echo "unknown")
	template_date=$(get_template_commit_date HEAD)
	printf "\n"
	log_success "Обновление завершено!"
	printf "  Версия шаблона: %s (%s)\n" "$template_date" "$template_commit"
fi
