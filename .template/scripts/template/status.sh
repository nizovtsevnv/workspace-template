#!/bin/sh
# ===================================
# Workspace Template - Статус шаблона
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

log_section "Статус шаблона"
printf "\n"

# Проверка URL шаблона
if [ -z "$TEMPLATE_REPO_URL" ]; then
	log_error "TEMPLATE_REPO_URL не определён"
	log_info "Убедитесь, что запускаете команду через make"
	exit 1
fi

# Определить статус проекта
if [ -f ".template-commit" ]; then
	# Инициализированный проект
	current_commit=$(get_template_commit)
	current_date=$(get_template_commit_date "$current_commit")

	log_info "URL шаблона:"
	printf "  %s\n" "$TEMPLATE_REPO_URL"
	printf "\n"

	log_info "Текущая версия:"
	printf "  %s (%s)\n" "$current_date" "$current_commit"
	printf "\n"

	# Проверяем доступность обновлений
	log_info "Проверка доступности обновлений..."
	if git fetch "$TEMPLATE_REPO_URL" main:refs/remotes/template/main --force >/dev/null 2>&1; then
		latest_commit=$(git rev-parse --short=7 refs/remotes/template/main 2>/dev/null || echo "unknown")
		latest_date=$(get_template_commit_date "refs/remotes/template/main")

		printf "  Последняя версия: %s (%s)\n" "$latest_date" "$latest_commit"
		printf "\n"

		if [ "$current_commit" = "$latest_commit" ]; then
			log_success "У вас самая свежая версия шаблона"
		else
			log_warning "Доступно обновление шаблона"
			log_info "Используйте: make template update"
		fi
	else
		log_warning "Не удалось проверить обновления"
		log_info "Проверьте доступность $TEMPLATE_REPO_URL"
	fi
else
	# Неинициализированный шаблон (разработка шаблона)
	log_info "Режим: неинициализированный шаблон"
	printf "\n"

	template_commit=$(git rev-parse --short=7 HEAD 2>/dev/null || echo "unknown")
	template_date=$(get_template_commit_date HEAD)

	log_info "Текущая версия шаблона:"
	printf "  %s (%s)\n" "$template_date" "$template_commit"
fi
