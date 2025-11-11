#!/bin/sh
# ===================================
# Workspace Template - Массовые операции с модулями
# ===================================
# Обработка команд для всех модулей сразу: pull, push, status
set -e

# Инициализация общих переменных
. "$(dirname "$0")/../lib/init.sh"

# Загружаем библиотеки
. "$SCRIPT_DIR/lib/ui.sh"
. "$SCRIPT_DIR/lib/modules-git.sh"

# ===================================
# Параметры
# ===================================

BULK_CMD="$1"

# Проверка что команда передана
if [ -z "$BULK_CMD" ]; then
	log_error "Не указана команда"
	log_info "Использование:"
	printf "make modules pull<COL>Инициализация и обновление всех субмодулей\n" | print_table 20
	printf "make modules push<COL>Отправка изменений во все субмодули\n" | print_table 20
	printf "make modules status<COL>Статус всех субмодулей\n" | print_table 20
	exit 1
fi

# ===================================
# Функции
# ===================================

# Получить список всех субмодулей из .gitmodules
get_all_submodules() {
	if [ ! -f "$WORKSPACE_ROOT/.gitmodules" ]; then
		return
	fi

	# Извлекаем все path из .gitmodules
	awk '
		/^\[submodule / { in_section=1; next }
		in_section && /^[[:space:]]*path[[:space:]]*=/ {
			sub(/^[[:space:]]*path[[:space:]]*=[[:space:]]*/, "")
			print
			in_section=0
		}
	' "$WORKSPACE_ROOT/.gitmodules"
}

# Проверить, инициализирован ли субмодуль
is_submodule_initialized() {
	local module_path="$1"

	# Проверяем наличие .git в директории модуля
	if [ -f "$WORKSPACE_ROOT/$module_path/.git" ] || [ -d "$WORKSPACE_ROOT/$module_path/.git" ]; then
		# Дополнительно проверяем, что это не пустая директория
		if [ -n "$(ls -A "$WORKSPACE_ROOT/$module_path" 2>/dev/null)" ]; then
			return 0
		fi
	fi

	return 1
}

# Получить текущий коммит субмодуля
get_submodule_commit() {
	local module_path="$1"

	if ! is_submodule_initialized "$module_path"; then
		echo "-"
		return
	fi

	cd "$WORKSPACE_ROOT/$module_path" || return
	git rev-parse --short=7 HEAD 2>/dev/null || echo "?"
	cd "$WORKSPACE_ROOT" || return
}

# ===================================
# Команды
# ===================================

case "$BULK_CMD" in
	pull)
		log_section "Синхронизация workspace и субмодулей"
		printf "\n"

		# ===================================
		# Шаг 1: Обновление workspace репозитория
		# ===================================

		log_info "Проверка обновлений workspace..."

		# Проверяем наличие uncommitted changes
		if ! git diff-index --quiet HEAD -- 2>/dev/null; then
			log_error "Workspace содержит несохраненные изменения"
			log_info "Закоммитьте или отмените изменения перед обновлением"
			printf "\n  git status\n  git add .\n  git commit -m \"...\"\n"
			exit 1
		fi

		# Получаем информацию о remote
		if ! git fetch origin 2>/dev/null; then
			log_warning "Не удалось получить обновления из origin"
			log_info "Продолжаем обновление субмодулей..."
		else
			# Проверяем наличие изменений
			LOCAL=$(git rev-parse HEAD 2>/dev/null)
			REMOTE=$(git rev-parse @{u} 2>/dev/null)

			if [ "$LOCAL" = "$REMOTE" ]; then
				log_success "Workspace актуален"
			else
				log_info "Обновление workspace..."

				# Выполняем git pull
				if git pull --rebase origin "$(git branch --show-current)" 2>&1; then
					log_success "Workspace обновлен"
				else
					log_error "Не удалось обновить workspace"
					log_info "Разрешите конфликты вручную и повторите"
					exit 1
				fi
			fi
		fi

		printf "\n"

		# ===================================
		# Шаг 2: Синхронизация субмодулей
		# ===================================

		log_section "Синхронизация субмодулей"
		printf "\n"

		# Получаем список всех субмодулей
		submodules=$(get_all_submodules)

		if [ -z "$submodules" ]; then
			log_warning "Субмодули не найдены в .gitmodules"
			exit 0
		fi

		# Счётчики
		total=0
		initialized=0
		updated=0
		failed=0

		# Обрабатываем каждый субмодуль
		for module_path in $submodules; do
			total=$((total + 1))
			module_name=$(basename "$module_path")

			if is_submodule_initialized "$module_path"; then
				# Субмодуль уже инициализирован - обновляем
				initialized=$((initialized + 1))

				log_info "Обновление $module_name..."
				if module_smart_pull_quiet "$module_name" "$module_path"; then
					log_success "$module_name обновлен"
					updated=$((updated + 1))
				else
					failed=$((failed + 1))
					log_error "Не удалось обновить $module_name"
				fi
			else
				# Субмодуль не инициализирован - инициализируем
				log_info "Инициализация $module_name..."
				if git submodule update --init "$module_path" 2>&1; then
					log_success "$module_name инициализирован"
					initialized=$((initialized + 1))
					updated=$((updated + 1))
				else
					failed=$((failed + 1))
					log_error "Не удалось инициализировать $module_name"
				fi
			fi
		done

		printf "\n"

		# Итоговый отчёт
		log_section "Результат синхронизации"
		printf "  Всего субмодулей: %d\n" "$total"
		printf "  Обновлено: ${COLOR_SUCCESS}%d${COLOR_RESET}\n" "$updated"
		if [ "$failed" -gt 0 ]; then
			printf "  Ошибок: ${COLOR_ERROR}%d${COLOR_RESET}\n" "$failed"
		fi
		;;

	push)
		log_section "Отправка изменений субмодулей и workspace"
		printf "\n"

		# Получаем список всех субмодулей
		submodules=$(get_all_submodules)

		if [ -z "$submodules" ]; then
			log_warning "Субмодули не найдены в .gitmodules"
			exit 0
		fi

		# ===================================
		# Шаг 1: Отправка изменений субмодулей
		# ===================================

		log_section "Отправка изменений субмодулей"
		printf "\n"

		# Счётчики
		total=0
		pushed=0
		skipped=0
		failed=0

		# Обрабатываем каждый субмодуль
		for module_path in $submodules; do
			module_name=$(basename "$module_path")

			if ! is_submodule_initialized "$module_path"; then
				continue
			fi

			total=$((total + 1))

			# Проверяем наличие изменений
			cd "$WORKSPACE_ROOT/$module_path" || continue

			if git diff-index --quiet HEAD -- 2>/dev/null; then
				# Нет изменений - пропускаем
				log_info "$module_name: нет изменений"
				skipped=$((skipped + 1))
				cd "$WORKSPACE_ROOT" || return
				continue
			fi

			cd "$WORKSPACE_ROOT" || return

			# Есть изменения - выполняем push
			log_info "Отправка $module_name..."

			if module_smart_push "$module_name" "$module_path"; then
				log_success "$module_name отправлен"
				pushed=$((pushed + 1))
			else
				log_error "Не удалось отправить $module_name"
				failed=$((failed + 1))
			fi
		done

		printf "\n"

		# Итоговый отчёт по субмодулям
		log_info "Результат отправки субмодулей:"
		printf "  Проверено: %d\n" "$total"
		if [ "$pushed" -gt 0 ]; then
			printf "  Отправлено: ${COLOR_SUCCESS}%d${COLOR_RESET}\n" "$pushed"
		fi
		if [ "$skipped" -gt 0 ]; then
			printf "  Пропущено: %d\n" "$skipped"
		fi
		if [ "$failed" -gt 0 ]; then
			printf "  Ошибок: ${COLOR_ERROR}%d${COLOR_RESET}\n" "$failed"
		fi

		if [ "$total" -eq 0 ]; then
			log_info "Нет инициализированных субмодулей"
			exit 0
		fi

		# Прерываем если были ошибки
		if [ "$failed" -gt 0 ]; then
			log_warning "Отправка workspace отменена из-за ошибок в субмодулях"
			exit 1
		fi

		printf "\n"

		# ===================================
		# Шаг 2: Обновление workspace репозитория
		# ===================================

		log_section "Синхронизация workspace"
		printf "\n"

		# Проверяем, есть ли uncommitted changes
		workspace_status=$(git status --porcelain 2>/dev/null)
		has_changes=false

		if [ -n "$workspace_status" ]; then
			has_changes=true
			# Есть изменения - коммитим
			log_info "Обнаружены изменения ссылок на субмодули"
			log_info "Коммит изменений workspace..."

			if git add . && git commit -m "chore: update submodule references" 2>&1; then
				log_success "Изменения закоммичены"
			else
				log_error "Не удалось создать коммит"
				exit 1
			fi
		fi

		# Проверяем, есть ли unpushed commits
		ahead=$(count_commits_ahead "$WORKSPACE_ROOT")

		if [ "$ahead" -gt 0 ]; then
			log_info "Отправка workspace в origin ($ahead коммитов)..."

			if git push origin "$(git branch --show-current)" 2>&1; then
				log_success "Workspace отправлен ($ahead коммитов)"
			else
				log_error "Не удалось отправить workspace"
				log_info "Попробуйте вручную: git push"
				exit 1
			fi
		else
			if [ "$has_changes" = false ]; then
				log_success "Workspace актуален, изменений нет"
			fi
		fi

		printf "\n"
		log_section "Синхронизация завершена"
		;;

	status)
		# Проверяем workspace status
		log_section "Workspace status"
		printf "\n"

		# Получаем текущую ветку
		current_branch=$(git branch --show-current 2>/dev/null || echo "detached")

		# Fetch для получения актуальной информации о remote (тихо)
		log_info "Получение информации о remote..."
		git fetch --quiet 2>/dev/null || true

		# Проверяем статус синхронизации workspace
		workspace_sync=$(get_sync_status "$WORKSPACE_ROOT")
		workspace_has_changes=""
		if has_uncommitted_changes "$WORKSPACE_ROOT"; then
			workspace_has_changes="yes"
		else
			workspace_has_changes="no"
		fi

		workspace_ahead=$(count_commits_ahead "$WORKSPACE_ROOT")
		workspace_behind=$(count_commits_behind "$WORKSPACE_ROOT")

		# Форматируем вывод workspace status
		printf "  Branch: %s\n" "$current_branch"

		case "$workspace_sync" in
			synced)
				printf "  Status: ${COLOR_SUCCESS}✓ synced with origin/%s${COLOR_RESET}\n" "$current_branch"
				;;
			ahead)
				printf "  Status: ${COLOR_WARNING}⚠ ahead${COLOR_RESET} (%s коммитов не отправлено)\n" "$workspace_ahead"
				;;
			behind)
				printf "  Status: ${COLOR_WARNING}⚠ behind${COLOR_RESET} (%s коммитов не получено)\n" "$workspace_behind"
				;;
			diverged)
				printf "  Status: ${COLOR_ERROR}⚠ diverged${COLOR_RESET} (%s↑ %s↓)\n" "$workspace_ahead" "$workspace_behind"
				;;
			no-remote)
				printf "  Status: ${COLOR_DIM}- no remote tracking${COLOR_RESET}\n"
				;;
		esac

		printf "  Local changes: %s\n" "$workspace_has_changes"
		printf "\n"

		# Получаем список всех субмодулей
		submodules=$(get_all_submodules)

		if [ -z "$submodules" ]; then
			log_warning "Субмодули не найдены в .gitmodules"
			exit 0
		fi

		log_section "Статус субмодулей"
		printf "\n"

		# Заголовок таблицы
		printf "${COLOR_DIM}%-16s %-10s %-15s %-8s %s${COLOR_RESET}\n" \
			"MODULE" "BRANCH" "STATUS" "CHANGES" "SYNC"

		# Формируем данные для каждого субмодуля
		for module_path in $submodules; do
			module_name=$(basename "$module_path")

			if ! is_submodule_initialized "$module_path"; then
				# Не инициализирован
				branch=$(get_submodule_branch "$module_path")
				printf "%-16s %-10s ${COLOR_ERROR}%-15s${COLOR_RESET} %-8s %s\n" \
					"$module_name" \
					"$branch" \
					"✗ not init" \
					"-" \
					"-"
				continue
			fi

			# Инициализирован - получаем детальную информацию
			branch=$(get_submodule_branch "$module_path")
			module_path_abs="$WORKSPACE_ROOT/$module_path"

			# Fetch для субмодуля (тихо)
			(cd "$module_path_abs" && git fetch --quiet 2>/dev/null) || true

			sync_status=$(get_sync_status "$module_path_abs")
			ahead=$(count_commits_ahead "$module_path_abs")
			behind=$(count_commits_behind "$module_path_abs")

			if has_uncommitted_changes "$module_path_abs"; then
				changes="yes"
			else
				changes="-"
			fi

			# Выводим строку таблицы с цветами
			case "$sync_status" in
				synced)
					printf "%-16s %-10s ${COLOR_SUCCESS}%-15s${COLOR_RESET} %-8s %s\n" \
						"$module_name" "$branch" "✓ synced" "$changes" "-"
					;;
				ahead)
					printf "%-16s %-10s ${COLOR_WARNING}%-15s${COLOR_RESET} %-8s %s\n" \
						"$module_name" "$branch" "⚠ ahead" "$changes" "${ahead}↑"
					;;
				behind)
					printf "%-16s %-10s ${COLOR_WARNING}%-15s${COLOR_RESET} %-8s %s\n" \
						"$module_name" "$branch" "⚠ behind" "$changes" "${behind}↓"
					;;
				diverged)
					printf "%-16s %-10s ${COLOR_ERROR}%-15s${COLOR_RESET} %-8s %s\n" \
						"$module_name" "$branch" "⚠ diverged" "$changes" "${ahead}↑${behind}↓"
					;;
				no-remote)
					printf "%-16s %-10s ${COLOR_DIM}%-15s${COLOR_RESET} %-8s %s\n" \
						"$module_name" "$branch" "- no remote" "$changes" "-"
					;;
			esac
		done

		printf "\n"
		log_info "Легенда:"
		printf "  ${COLOR_SUCCESS}✓ synced${COLOR_RESET}     - синхронизирован с remote\n"
		printf "  ${COLOR_WARNING}⚠ ahead${COLOR_RESET}      - есть непушнутые коммиты\n"
		printf "  ${COLOR_WARNING}⚠ behind${COLOR_RESET}     - есть необпулленные коммиты\n"
		printf "  ${COLOR_ERROR}⚠ diverged${COLOR_RESET}   - есть изменения в обоих направлениях\n"
		printf "  yes/-        - наличие uncommitted changes\n"
		printf "  N↑           - N коммитов ahead (непушнуто)\n"
		printf "  N↓           - N коммитов behind (необпуллено)\n"
		printf "\n"
		log_info "Используйте: make modules pull - для синхронизации"
		log_info "Используйте: make modules push - для отправки изменений"
		;;

	*)
		log_error "Неизвестная команда: $BULK_CMD"
		log_info "Доступные команды: pull, push, status"
		exit 1
		;;
esac
