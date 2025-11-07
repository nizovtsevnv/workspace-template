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
	printf "make module pull<COL>Инициализация и обновление всех субмодулей\n" | print_table 20
	printf "make module push<COL>Отправка изменений во все субмодули\n" | print_table 20
	printf "make module status<COL>Статус всех субмодулей\n" | print_table 20
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
		log_section "Синхронизация всех субмодулей"
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

				if module_smart_pull "$module_name" "$module_path"; then
					updated=$((updated + 1))
				else
					failed=$((failed + 1))
				fi
			else
				# Субмодуль не инициализирован - инициализируем
				log_info "Инициализация $module_name..."

				if show_spinner "git submodule update --init" \
					git submodule update --init "$module_path" 2>&1; then
					initialized=$((initialized + 1))
					updated=$((updated + 1))
					log_success "Модуль $module_name инициализирован"
				else
					failed=$((failed + 1))
					log_error "Не удалось инициализировать $module_name"
				fi
			fi
			printf "\n"
		done

		# Итоговый отчёт
		log_section "Результат"
		printf "  Всего субмодулей: %d\n" "$total"
		printf "  Обновлено: ${COLOR_SUCCESS}%d${COLOR_RESET}\n" "$updated"
		if [ "$failed" -gt 0 ]; then
			printf "  Ошибок: ${COLOR_ERROR}%d${COLOR_RESET}\n" "$failed"
		fi

		# Напоминание про коммит workspace
		if [ "$updated" -gt 0 ]; then
			printf "\n"
			log_info "Не забудьте закоммитить изменения в workspace:"
			printf "  git add .\n"
			printf "  git commit -m \"chore: update submodules\"\n"
		fi
		;;

	push)
		log_section "Отправка изменений во все субмодули"
		printf "\n"

		# Получаем список всех субмодулей
		submodules=$(get_all_submodules)

		if [ -z "$submodules" ]; then
			log_warning "Субмодули не найдены в .gitmodules"
			exit 0
		fi

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
				skipped=$((skipped + 1))
				cd "$WORKSPACE_ROOT" || return
				continue
			fi

			cd "$WORKSPACE_ROOT" || return

			# Есть изменения - выполняем push
			log_info "Отправка изменений $module_name..."

			if module_smart_push "$module_name" "$module_path"; then
				pushed=$((pushed + 1))
			else
				failed=$((failed + 1))
			fi
			printf "\n"
		done

		# Итоговый отчёт
		log_section "Результат"
		printf "  Проверено модулей: %d\n" "$total"
		if [ "$pushed" -gt 0 ]; then
			printf "  Отправлено: ${COLOR_SUCCESS}%d${COLOR_RESET}\n" "$pushed"
		fi
		if [ "$skipped" -gt 0 ]; then
			printf "  Пропущено (нет изменений): %d\n" "$skipped"
		fi
		if [ "$failed" -gt 0 ]; then
			printf "  Ошибок: ${COLOR_ERROR}%d${COLOR_RESET}\n" "$failed"
		fi

		if [ "$total" -eq 0 ]; then
			log_info "Нет инициализированных субмодулей"
		fi
		;;

	status)
		log_section "Статус субмодулей"
		printf "\n"

		# Получаем список всех субмодулей
		submodules=$(get_all_submodules)

		if [ -z "$submodules" ]; then
			log_warning "Субмодули не найдены в .gitmodules"
			exit 0
		fi

		# Формируем таблицу
		table_data=""

		for module_path in $submodules; do
			module_name=$(basename "$module_path")

			if is_submodule_initialized "$module_path"; then
				status="${COLOR_SUCCESS}✓ initialized${COLOR_RESET}"
				commit=$(get_submodule_commit "$module_path")
				branch=$(get_submodule_branch "$module_path")
			else
				status="${COLOR_ERROR}✗ not initialized${COLOR_RESET}"
				commit="-"
				branch=$(get_submodule_branch "$module_path")
			fi

			if [ -z "$table_data" ]; then
				table_data="${module_name}<COL>${status}<COL>${branch}<COL>${commit}"
			else
				table_data="${table_data}<ROW>${module_name}<COL>${status}<COL>${branch}<COL>${commit}"
			fi
		done

		if [ -n "$table_data" ]; then
			printf "%s\n" "$table_data" | print_table 20
		fi

		printf "\n"
		log_info "Используйте: make module pull - для инициализации и обновления"
		;;

	*)
		log_error "Неизвестная команда: $BULK_CMD"
		log_info "Доступные команды: pull, push, status"
		exit 1
		;;
esac
