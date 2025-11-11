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
	printf "make modules sync<COL>Синхронизация в обоих направлениях (pull + push)\n" | print_table 20
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
		log_section "Статус воркспэйса"
		printf "\n"

		# Получаем текущую ветку
		current_branch=$(git branch --show-current 2>/dev/null || echo "detached")

		# Fetch для получения актуальной информации о remote (тихо)
		log_info "Получение информации с сервера..."
		git fetch --quiet 2>/dev/null || true

		# Проверяем статус синхронизации workspace
		workspace_sync=$(get_sync_status "$WORKSPACE_ROOT")
		workspace_has_changes=""
		workspace_has_changes_display=""
		if has_uncommitted_changes "$WORKSPACE_ROOT"; then
			workspace_has_changes="есть"
			workspace_has_changes_display="${COLOR_WARNING}⚠ есть${COLOR_RESET}"
		else
			workspace_has_changes="нет"
			workspace_has_changes_display="${COLOR_SUCCESS}✓ нет${COLOR_RESET}"
		fi

		workspace_ahead=$(count_commits_ahead "$WORKSPACE_ROOT")
		workspace_behind=$(count_commits_behind "$WORKSPACE_ROOT")

		# Форматируем вывод workspace status
		printf "  Ветка: %s\n" "$current_branch"

		case "$workspace_sync" in
			synced)
				printf "  Статус: ${COLOR_SUCCESS}✓ синхронизирован с origin/%s${COLOR_RESET}\n" "$current_branch"
				;;
			ahead)
				printf "  Статус: ${COLOR_WARNING}⚠ %s↑ коммитов не отправлено${COLOR_RESET}\n" "$workspace_ahead"
				;;
			behind)
				printf "  Статус: ${COLOR_WARNING}⚠ %s↓ коммитов не получено${COLOR_RESET}\n" "$workspace_behind"
				;;
			diverged)
				printf "  Статус: ${COLOR_ERROR}⚠ %s↑ коммитов не отправлено и %s↓ не получено${COLOR_RESET}\n" "$workspace_ahead" "$workspace_behind"
				;;
			no-remote)
				printf "  Статус: ${COLOR_DIM}- не отслеживается${COLOR_RESET}\n"
				;;
		esac

		printf "  Изменения вне коммитов: ${workspace_has_changes_display}\n"
		printf "\n"

		# Получаем список всех субмодулей
		submodules=$(get_all_submodules)

		if [ -z "$submodules" ]; then
			log_info "В проекте нет Git-субмодулей"
			exit 0
		fi

		log_section "Статус модулей"
		printf "\n"

		# Определяем максимальную длину имени модуля для правильного выравнивания
		max_module_len=10
		for module_path in $submodules; do
			module_name=$(basename "$module_path")
			module_len=${#module_name}
			if [ "$module_len" -gt "$max_module_len" ]; then
				max_module_len=$module_len
			fi
		done
		# Добавляем запас для удобства чтения
		max_module_len=$((max_module_len + 2))

		# Заголовок таблицы
		printf "${COLOR_DIM}%-${max_module_len}s       Ветка        Вне коммитов     Коммиты    Статус${COLOR_RESET}\n" "Модуль"

		# Формируем данные для каждого субмодуля
		for module_path in $submodules; do
			module_name=$(basename "$module_path")

			if ! is_submodule_initialized "$module_path"; then
				# Не инициализирован
				branch=$(get_submodule_branch "$module_path")
				printf "%-${max_module_len}s %-12s %-16s %-12s ${COLOR_ERROR}%s${COLOR_RESET}\n" \
					"$module_name" \
					"$branch" \
					"-" \
					"-" \
					"не инициализирован"
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
				file_count=$(count_uncommitted_files "$module_path_abs")
				changes="⚠ $file_count  "  # 2 пробела для компенсации UTF-8 ширины ⚠
			else
				changes="-"
			fi

			# Проверяем синхронизацию с workspace (HEAD субмодуля vs запись в workspace)
			expected_commit=$(git ls-tree HEAD "$module_path" 2>/dev/null | awk '{print $3}')
			actual_commit=$(cd "$module_path_abs" && git rev-parse HEAD 2>/dev/null)

			if [ -n "$expected_commit" ] && [ -n "$actual_commit" ] && [ "$expected_commit" != "$actual_commit" ]; then
				# Субмодуль не синхронизирован с workspace
				printf "%-${max_module_len}s %-12s %-16s %-12s ${COLOR_WARNING}%s${COLOR_RESET}\n" \
					"$module_name" "$branch" "$changes" "workspace" "требуется git add и commit"
				continue
			fi

			# Выводим строку таблицы с цветами
			# Формат: MODULE BRANCH SYNC STATUS CHANGES
			case "$sync_status" in
				synced)
					printf "%-${max_module_len}s %-12s %-16s %-12s ${COLOR_SUCCESS}%s${COLOR_RESET}\n" \
						"$module_name" "$branch" "$changes" "-" "синхронизировано"
					;;
				ahead)
					printf "%-${max_module_len}s %-12s %-16s %-12s ${COLOR_WARNING}%s${COLOR_RESET}\n" \
						"$module_name" "$branch" "$changes" "${ahead}↑" "make modules push"
					;;
				behind)
					printf "%-${max_module_len}s %-12s %-16s %-12s ${COLOR_WARNING}%s${COLOR_RESET}\n" \
						"$module_name" "$branch" "$changes" "${behind}↓" "make modules pull"
					;;
				diverged)
					printf "%-${max_module_len}s %-12s %-16s %-12s ${COLOR_ERROR}%s${COLOR_RESET}\n" \
						"$module_name" "$branch" "$changes" "${ahead}↑${behind}↓" "make modules sync"
					;;
				no-remote)
					printf "%-${max_module_len}s %-12s %-16s %-12s ${COLOR_DIM}%s${COLOR_RESET}\n" \
						"$module_name" "$branch" "$changes" "-" "не отслеживается"
					;;
			esac
		done
		;;

	sync)
		log_section "Синхронизация workspace и субмодулей с удалёнными Git-репозиториями"
		printf "\n"

		# Сначала pull
		log_section "Шаг 1: Pull изменений"
		printf "\n"

		# Проверяем наличие uncommitted changes в workspace
		if ! git diff-index --quiet HEAD -- 2>/dev/null; then
			log_error "Workspace содержит несохраненные изменения"
			log_info "Закоммитьте или stash их перед синхронизацией"
			exit 1
		fi

		# Получаем информацию о remote
		if ! git fetch origin 2>/dev/null; then
			log_warning "Не удалось получить обновления из origin"
		else
			LOCAL=$(git rev-parse HEAD 2>/dev/null)
			REMOTE=$(git rev-parse @{u} 2>/dev/null)

			if [ "$LOCAL" = "$REMOTE" ]; then
				log_success "Workspace актуален"
			else
				if git pull --rebase origin "$(git branch --show-current)" 2>&1; then
					log_success "Workspace обновлен"
				else
					log_error "Не удалось обновить workspace"
					log_info "Разрешите конфликты и попробуйте снова"
					exit 1
				fi
			fi
		fi

		# Синхронизация субмодулей
		submodules=$(get_all_submodules)

		if [ -z "$submodules" ]; then
			log_info "Нет субмодулей для синхронизации"
		else
			for module_path in $submodules; do
				module_name=$(basename "$module_path")

				if ! is_submodule_initialized "$module_path"; then
					continue
				fi

				log_info "Синхронизация $module_name..."
				if module_smart_pull_quiet "$module_name" "$module_path"; then
					log_success "$module_name обновлен"
				else
					log_warning "Не удалось обновить $module_name"
				fi
			done
		fi

		printf "\n"
		log_section "Шаг 2: Push изменений"
		printf "\n"

		# Отправляем изменения (используем логику из push)
		pushed=0
		failed=0

		for module_path in $submodules; do
			module_name=$(basename "$module_path")

			if ! is_submodule_initialized "$module_path"; then
				continue
			fi

			module_path_abs="$WORKSPACE_ROOT/$module_path"
			cd "$module_path_abs" || continue

			# Проверяем есть ли изменения для отправки
			if ! git diff-index --quiet HEAD -- 2>/dev/null; then
				log_info "Отправка $module_name..."

				# Auto-commit uncommitted changes
				if git add -A && git commit -m "chore: sync changes" 2>&1; then
					if git push origin "$(get_submodule_branch "$module_path")" 2>&1; then
						pushed=$((pushed + 1))
						log_success "$module_name отправлен"
					else
						failed=$((failed + 1))
						log_error "Не удалось отправить $module_name"
					fi
				fi
			else
				# Проверяем unpushed commits
				ahead=$(count_commits_ahead "$module_path_abs")
				if [ "$ahead" -gt 0 ]; then
					log_info "Отправка $module_name ($ahead коммитов)..."
					if git push origin "$(get_submodule_branch "$module_path")" 2>&1; then
						pushed=$((pushed + 1))
						log_success "$module_name отправлен"
					else
						failed=$((failed + 1))
						log_error "Не удалось отправить $module_name"
					fi
				fi
			fi

			cd "$WORKSPACE_ROOT" || exit 1
		done

		# Отправка workspace
		workspace_status=$(git status --porcelain 2>/dev/null)

		if [ -n "$workspace_status" ]; then
			log_info "Коммит изменений workspace..."
			if git add . && git commit -m "chore: sync submodule references" 2>&1; then
				log_success "Изменения закоммичены"
			fi
		fi

		ahead=$(count_commits_ahead "$WORKSPACE_ROOT")
		if [ "$ahead" -gt 0 ]; then
			log_info "Отправка workspace в origin ($ahead коммитов)..."
			if git push origin "$(git branch --show-current)" 2>&1; then
				log_success "Workspace отправлен"
			else
				log_error "Не удалось отправить workspace"
			fi
		fi

		printf "\n"
		log_section "Синхронизация завершена"
		;;

	*)
		log_error "Неизвестная команда: $BULK_CMD"
		log_info "Доступные команды: pull, push, sync, status"
		exit 1
		;;
esac
