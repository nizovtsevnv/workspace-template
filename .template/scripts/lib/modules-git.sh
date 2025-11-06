#!/bin/sh
# ===================================
# Modules Git библиотека для Workspace Template
# ===================================
# Функции для работы с git submodules
# Использование: . lib/modules-git.sh
# shellcheck disable=SC1091,SC3043

# ===================================
# Функции детектирования
# ===================================

# Проверить, является ли модуль git submodule
# Параметр: $1 - путь к модулю (относительно workspace root)
# Возвращает: 0 если submodule, 1 если нет
is_git_submodule() {
	local module_path="$1"

	# Проверяем наличие .gitmodules и записи о модуле
	if [ ! -f "$WORKSPACE_ROOT/.gitmodules" ]; then
		return 1
	fi

	# Ищем путь модуля в .gitmodules
	if grep -q "path = $module_path" "$WORKSPACE_ROOT/.gitmodules" 2>/dev/null; then
		return 0
	fi

	return 1
}

# Получить URL git submodule из .gitmodules
# Параметр: $1 - путь к модулю
# Возвращает: URL или пустую строку
get_submodule_url() {
	local module_path="$1"

	if [ ! -f "$WORKSPACE_ROOT/.gitmodules" ]; then
		return
	fi

	# Извлекаем URL для данного path
	awk -v path="$module_path" '
		$0 ~ /\[submodule/ { in_section=0 }
		$1 == "path" && $3 == path { in_section=1 }
		in_section && $1 == "url" { print $3; exit }
	' "$WORKSPACE_ROOT/.gitmodules"
}

# Получить ветку git submodule из .gitmodules
# Параметр: $1 - путь к модулю
# Возвращает: branch или "main" по умолчанию
get_submodule_branch() {
	local module_path="$1"

	if [ ! -f "$WORKSPACE_ROOT/.gitmodules" ]; then
		echo "main"
		return
	fi

	# Извлекаем branch для данного path
	branch=$(awk -v path="$module_path" '
		$0 ~ /\[submodule/ { in_section=0 }
		$1 == "path" && $3 == path { in_section=1 }
		in_section && $1 == "branch" { print $3; exit }
	' "$WORKSPACE_ROOT/.gitmodules")

	# Если branch не указан, возвращаем main
	if [ -z "$branch" ]; then
		echo "main"
	else
		echo "$branch"
	fi
}

# Получить текстовое представление типа модуля для отображения
# Параметр: $1 - путь к модулю
# Возвращает: "Local" или "Git Submodule (branch: <branch>, url: <url>)"
get_module_type_display() {
	local module_path="$1"

	if is_git_submodule "$module_path"; then
		local url
		local branch
		url=$(get_submodule_url "$module_path")
		branch=$(get_submodule_branch "$module_path")
		echo "Git Submodule (branch: $branch)"
	else
		echo "Local"
	fi
}

# ===================================
# Функции работы с .gitmodules
# ===================================

# Добавить запись в .gitmodules
# Параметры: $1 - имя модуля, $2 - путь, $3 - URL, $4 - branch
# Использование: add_to_gitmodules "mymodule" "modules/mymodule" "git@..." "main"
add_to_gitmodules() {
	# shellcheck disable=SC2034
	local name="$1"
	local path="$2"
	local url="$3"
	local branch="$4"

	# Используем git submodule add - он автоматически обновляет .gitmodules
	cd "$WORKSPACE_ROOT" || return 1
	git submodule add -b "$branch" "$url" "$path" || return 1
}

# Удалить запись из .gitmodules
# Параметр: $1 - путь к модулю
# Использование: remove_from_gitmodules "modules/mymodule"
remove_from_gitmodules() {
	local module_path="$1"

	cd "$WORKSPACE_ROOT" || return 1

	# Используем git submodule deinit + git rm
	git submodule deinit -f "$module_path" || return 1
	git rm -f "$module_path" || return 1
	rm -rf ".git/modules/$module_path"
}

# Обновить ссылку на submodule в workspace
# Параметр: $1 - путь к модулю
# Использование: update_workspace_submodule_ref "modules/mymodule"
update_workspace_submodule_ref() {
	local module_path="$1"

	cd "$WORKSPACE_ROOT" || return 1
	git add "$module_path"
}

# ===================================
# Функции умной синхронизации
# ===================================

# Умный pull: синхронизация с удаленным репозиторием + обновление workspace
# Параметры: $1 - имя модуля, $2 - путь к модулю
# Использование: module_smart_pull "mymodule" "modules/mymodule"
module_smart_pull() {
	local module_name="$1"
	local module_path="$2"

	# Загружаем UI библиотеку для вывода
	. "${SCRIPT_DIR:?SCRIPT_DIR не определён}/lib/loader.sh"
	load_lib "ui" "log_info"

	# Проверяем что модуль - submodule
	if ! is_git_submodule "$module_path"; then
		log_error "Модуль '$module_name' не является git submodule"
		log_info "Используйте: make $module_name convert URL=<url> для конвертации"
		return 1
	fi

	local branch
	branch=$(get_submodule_branch "$module_path")

	log_section "Синхронизация модуля $module_name"

	# Переходим в модуль
	cd "$WORKSPACE_ROOT/$module_path" || return 1

	# Проверяем uncommitted changes
	if ! git diff-index --quiet HEAD -- 2>/dev/null; then
		log_warning "В модуле есть незакоммиченные изменения!"
		log_info "Сохраните изменения (git stash) или закоммитьте их перед pull"
		git status --short
		return 1
	fi

	# Pull из удаленного репозитория
	log_info "Pull из origin/$branch..."
	if ! git pull origin "$branch"; then
		log_error "Не удалось выполнить git pull"
		return 1
	fi

	# Возвращаемся в workspace root
	cd "$WORKSPACE_ROOT" || return 1

	# Обновляем ссылку на submodule
	log_info "Обновление ссылки в workspace..."
	git add "$module_path"

	log_success "Модуль $module_name успешно обновлён"
	log_info "Не забудьте закоммитить изменения в workspace:"
	printf "  %s\n" "git commit -m \"chore: update $module_name submodule\""
}

# Умный push: commit + push + обновление workspace
# Параметры: $1 - имя модуля, $2 - путь к модулю
# Использование: module_smart_push "mymodule" "modules/mymodule"
module_smart_push() {
	local module_name="$1"
	local module_path="$2"

	# Загружаем UI библиотеку для вывода
	. "${SCRIPT_DIR:?SCRIPT_DIR не определён}/lib/loader.sh"
	load_lib "ui" "log_info"

	# Проверяем что модуль - submodule
	if ! is_git_submodule "$module_path"; then
		log_error "Модуль '$module_name' не является git submodule"
		log_info "Используйте: make $module_name convert URL=<url> для конвертации"
		return 1
	fi

	local branch
	branch=$(get_submodule_branch "$module_path")

	log_section "Отправка изменений модуля $module_name"

	# Переходим в модуль
	cd "$WORKSPACE_ROOT/$module_path" || return 1

	# Показываем статус
	log_info "Статус модуля:"
	git status --short

	# Проверяем есть ли изменения
	if git diff-index --quiet HEAD -- 2>/dev/null && [ -z "$(git ls-files --others --exclude-standard)" ]; then
		log_info "Нет изменений для отправки"
		return 0
	fi

	printf "\n"

	# Запрашиваем commit message
	log_info "Введите commit message:"
	read -r commit_msg

	if [ -z "$commit_msg" ]; then
		log_error "Commit message не может быть пустым"
		return 1
	fi

	printf "\n"

	# Commit + push
	log_info "Отправка изменений..."
	if ! git add -A; then
		log_error "Не удалось выполнить git add"
		return 1
	fi

	if ! git commit -m "$commit_msg"; then
		log_error "Не удалось создать commit"
		return 1
	fi

	if ! git push origin "$branch"; then
		log_error "Не удалось выполнить git push"
		log_warning "Commit создан локально, но не отправлен"
		return 1
	fi

	# Возвращаемся в workspace root
	cd "$WORKSPACE_ROOT" || return 1

	# Обновляем ссылку на submodule
	log_info "Обновление ссылки в workspace..."
	git add "$module_path"

	log_success "Изменения успешно отправлены"
	log_info "Не забудьте закоммитить изменения в workspace:"
	printf "  %s\n" "git commit -m \"chore: update $module_name submodule\""
}

# ===================================
# Функция умной конвертации
# ===================================

# Умная конвертация: Local → Git или Git → Local (автоопределение)
# Параметры: $1 - имя модуля, $2 - путь к модулю, $3 - URL (опционально, для Local → Git)
# Использование: module_convert "mymodule" "modules/mymodule" "git@..."
module_convert() {
	local module_name="$1"
	local module_path="$2"
	local git_url="$3"

	# Загружаем UI библиотеку для вывода
	. "${SCRIPT_DIR:?SCRIPT_DIR не определён}/lib/loader.sh"
	load_lib "ui" "log_info"

	if is_git_submodule "$module_path"; then
		# Git → Local
		log_section "Конвертация git submodule в локальный модуль"

		# Создаем временную директорию
		temp_dir=$(mktemp -d)

		# Копируем содержимое модуля
		log_info "Сохранение содержимого модуля..."
		cp -r "$WORKSPACE_ROOT/$module_path" "$temp_dir/" || return 1

		# Удаляем submodule
		log_info "Удаление git submodule..."
		cd "$WORKSPACE_ROOT" || return 1

		if ! remove_from_gitmodules "$module_path"; then
			log_error "Не удалось удалить submodule"
			rm -rf "$temp_dir"
			return 1
		fi

		# Восстанавливаем как локальную папку
		log_info "Восстановление как локальной директории..."
		cp -r "$temp_dir/$(basename "$module_path")" "$WORKSPACE_ROOT/$module_path" || return 1
		rm -rf "$temp_dir"

		# Удаляем .git из модуля
		rm -rf "$WORKSPACE_ROOT/$module_path/.git"

		log_success "Модуль '$module_name' конвертирован в локальный"
		log_info "Не забудьте закоммитить изменения в workspace"

	else
		# Local → Git
		log_section "Конвертация локального модуля в git submodule"

		# Запрашиваем URL если не указан
		if [ -z "$git_url" ]; then
			log_info "Введите URL удаленного git репозитория:"
			read -r git_url

			if [ -z "$git_url" ]; then
				log_error "URL не может быть пустым"
				return 1
			fi
		fi

		printf "\n"

		# Инициализируем git в модуле
		log_info "Инициализация git репозитория..."
		cd "$WORKSPACE_ROOT/$module_path" || return 1

		git init || return 1
		git add -A || return 1
		git commit -m "Initial commit" || return 1
		git branch -M main || return 1
		git remote add origin "$git_url" || return 1

		# Пытаемся отправить в удаленный репозиторий
		log_info "Отправка в удаленный репозиторий..."
		if ! git push -u origin main; then
			log_warning "Не удалось отправить в удаленный репозиторий"
			log_info "Возможно, репозиторий не существует. Создайте его вручную:"
			log_info "  $git_url"
			log_info "Затем выполните:"
			log_info "  cd $module_path && git push -u origin main"
			return 1
		fi

		# Возвращаемся в workspace
		cd "$WORKSPACE_ROOT" || return 1

		# Создаем backup и конвертируем в submodule
		log_info "Конвертация в git submodule..."
		mv "$module_path" "${module_path}.backup" || return 1

		if ! git submodule add -b main "$git_url" "$module_path"; then
			log_error "Не удалось добавить submodule"
			mv "${module_path}.backup" "$module_path"
			return 1
		fi

		rm -rf "${module_path}.backup"

		log_success "Модуль '$module_name' конвертирован в git submodule"
		log_info "Не забудьте закоммитить изменения в workspace"
	fi
}
